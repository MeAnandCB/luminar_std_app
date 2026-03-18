// screens/folder_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/gallery_details_screen/controller/gallery_details_screen_controller.dart';
import 'package:luminar_std/presentation/gallery_details_screen/views/widget/folder_card.dart';
import 'package:luminar_std/presentation/gallery_details_screen/views/widget/section_header.dart';
import 'package:luminar_std/presentation/gallery_details_screen/views/widget/video_card.dart';
import 'package:luminar_std/repository/gallery_details_screen/models/gallery_detail_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/theme/app_colors.dart'; // Import your AppColors

class FolderBrowserScreen extends StatefulWidget {
  final String batchId;
  final String galleryUid;
  final String galleryName;
  final String galleryDescription;

  const FolderBrowserScreen({
    Key? key,
    required this.batchId,
    required this.galleryUid,
    required this.galleryName,
    required this.galleryDescription,
  }) : super(key: key);

  @override
  State<FolderBrowserScreen> createState() => _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends State<FolderBrowserScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _initializeProvider();
  }

  void _setupAnimations() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreVideos();
      }
    });
  }

  void _initializeProvider() {
    final provider = Provider.of<FolderBrowserProvider>(context, listen: false);
    provider.initialize(
      batchId: widget.batchId,
      galleryUid: widget.galleryUid,
      galleryName: widget.galleryName,
      galleryDescription: widget.galleryDescription,
    );
    provider.loadRootContents();
  }

  void _loadMoreVideos() {
    final provider = Provider.of<FolderBrowserProvider>(context, listen: false);
    if (provider.hasMoreVideos && !provider.isLoadingMore) {
      provider.loadNextVideoPage();
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    final provider = Provider.of<FolderBrowserProvider>(context, listen: false);
    await provider.refreshCurrentFolder();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Consumer<FolderBrowserProvider>(
          builder: (context, provider, child) {
            final folderCount = provider.currentFolderSummary?.totalFolders ?? provider.currentSubfolders.length;
            final videoCount = provider.currentVideoSummary?.totalVideos ?? provider.currentVideos.length;
            final hasVideoSection = provider.currentVideos.isNotEmpty || provider.currentVideoSummary != null;

            // Show loading indicator with animation
            if (provider.isLoading && !provider.isRefreshing) {
              return _buildLoadingState();
            }

            // Show error with animation
            if (provider.hasError && provider.currentSubfolders.isEmpty && provider.currentVideos.isEmpty) {
              return _buildErrorState(provider);
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                backgroundColor: AppColors.white,
                strokeWidth: 2,
                displacement: 40,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // Header Section with Gallery Info
                    SliverToBoxAdapter(child: _buildHeader(provider)),

                    // Subfolders Section
                    if (provider.currentSubfolders.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: SectionHeader(title: 'Subfolders', count: provider.currentFolderSummary?.totalFolders),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final folder = provider.currentSubfolders[index];
                          return TweenAnimationBuilder(
                            duration: Duration(milliseconds: 400 + (index * 50)),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: index == provider.currentSubfolders.length - 1 ? 16 : 8,
                              ),
                              child: FolderCard(
                                folder: folder,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  provider.navigateToFolder(folderUid: folder.uid, folderName: folder.name);
                                },
                              ),
                            ),
                          );
                        }, childCount: provider.currentSubfolders.length),
                      ),
                    ],

                    // Videos Section
                    if (hasVideoSection) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, provider.currentSubfolders.isEmpty ? 24 : 16, 16, 8),
                          child: SectionHeader(title: 'Videos', count: videoCount),
                        ),
                      ),
                      if (provider.currentVideos.isEmpty) ...[
                        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyVideos()),
                      ] else ...[
                        SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            if (index == provider.currentVideos.length) {
                              if (provider.isLoadingMore) {
                                return _buildLoadingMore();
                              }
                              return const SizedBox.shrink();
                            }

                            final video = provider.currentVideos[index];
                            return TweenAnimationBuilder(
                              duration: Duration(milliseconds: 400 + (index * 50)),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: index == provider.currentVideos.length - 1 ? 16 : 8,
                                ),
                                child: VideoCard(
                                  video: video,
                                  onWatch: () {
                                    HapticFeedback.mediumImpact();
                                    _showVideoDialog(context, video);
                                  },
                                ),
                              ),
                            );
                          }, childCount: provider.currentVideos.length + (provider.hasMoreVideos ? 1 : 0)),
                        ),
                      ],
                    ],

                    // Empty state
                    if (provider.currentSubfolders.isEmpty && provider.currentVideos.isEmpty && !provider.isLoading)
                      SliverFillRemaining(child: _buildEmptyState()),

                    // Footer with count
                    if (provider.currentVideos.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Showing ${provider.currentVideos.length} '
                              '${provider.currentVideos.length == 1 ? 'video' : 'videos'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.galleryName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FolderBrowserProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 80, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb Navigation
          // FolderBreadcrumb(
          //   currentFolder: provider.currentFolderName,
          //   onNavigateBack: (index) {
          //     HapticFeedback.selectionClick();
          //     provider.navigateToFolderAtIndex(index);
          //   },
          // ),
          const SizedBox(height: 8),

          // Quick Stats
          if (provider.currentSubfolders.isNotEmpty || provider.currentVideos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.folder_outlined,
                      value:
                          provider.currentFolderSummary?.totalFolders?.toString() ??
                          provider.currentSubfolders.length.toString(),
                      label: 'Folders',
                      color: Colors.white,
                    ),
                  ),
                  Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.video_library_outlined,
                      value:
                          provider.currentVideoSummary?.totalVideos?.toString() ??
                          provider.currentVideos.length.toString(),
                      label: 'Videos',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label, required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color.withOpacity(0.9)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading content...',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(FolderBrowserProvider provider) {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 500),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.error_outline, size: 64, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.foldersError ?? provider.videosError ?? 'Failed to load folder',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVideos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.videocam_off_outlined, size: 64, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            'No videos in this folder',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text('Videos will appear here when added', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.folder_open_outlined, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'This folder is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text('Add content to get started', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Loading more videos...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog(BuildContext context, VideoModel video) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              width: double.maxFinite,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnail/Video Placeholder
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: AppColors.primary.withOpacity(0.1),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.play_circle_fill, size: 64, color: AppColors.primary.withOpacity(0.8)),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                video.duration?.toString() ?? '00:00',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (video.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(video.description, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  HapticFeedback.mediumImpact();
                                  _openVideoPlayer(context, video);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('Play Now'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _openVideoPlayer(BuildContext context, VideoModel video) {
    // Navigate to video player screen with animation
    if (video.videoLink != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing: ${video.title}'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
