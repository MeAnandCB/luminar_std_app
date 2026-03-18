// screens/folder_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/gallery_details_screen/controller/gallery_details_screen_controller.dart';
import 'package:luminar_std/presentation/gallery_details_screen/views/widget/folder_card.dart';
import 'package:luminar_std/presentation/gallery_details_screen/views/widget/section_header.dart';
import 'package:luminar_std/presentation/gallery_details_screen/views/widget/video_card.dart';
import 'package:luminar_std/repository/gallery_details_screen/models/gallery_detail_model.dart';
import 'package:provider/provider.dart';

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

class _FolderBrowserScreenState extends State<FolderBrowserScreen> {
  final ScrollController _scrollController = ScrollController();

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreVideos();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _initializeProvider();
  }

  void _initializeProvider() {
    final provider = Provider.of<FolderBrowserProvider>(context, listen: false);
    provider.initialize(
      batchId: widget.batchId,
      galleryUid: widget.galleryUid,
      galleryName: widget.galleryName,
      galleryDescription: widget.galleryDescription,
    );

    // Load root contents immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        provider.loadRootContents();
      }
    });
  }

  void _loadMoreVideos() {
    final provider = Provider.of<FolderBrowserProvider>(context, listen: false);
    if (provider.hasMoreVideos && !provider.isLoadingMore) {
      provider.loadNextVideoPage();
    }
  }

  Future<void> _refresh() async {
    final provider = Provider.of<FolderBrowserProvider>(context, listen: false);
    await provider.refreshCurrentFolder();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.galleryName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (widget.galleryDescription.isNotEmpty)
              Text(widget.galleryDescription, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Consumer<FolderBrowserProvider>(
        builder: (context, provider, child) {
          // Derive counts from summary when available so we don't show stale / partial results
          final folderCount = provider.currentFolderSummary?.totalFolders ?? provider.currentSubfolders.length;
          final videoCount = provider.currentVideoSummary?.totalVideos ?? provider.currentVideos.length;
          final hasVideoSection = provider.currentVideos.isNotEmpty || provider.currentVideoSummary != null;

          // Show loading indicator
          if (provider.isLoading && !provider.isRefreshing) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if both failed
          if (provider.hasError && provider.currentSubfolders.isEmpty && provider.currentVideos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.foldersError ?? provider.videosError ?? 'Failed to load folder',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Subfolders Section
                if (provider.currentSubfolders.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(title: 'Subfolders', count: provider.currentFolderSummary?.totalFolders),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final folder = provider.currentSubfolders[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: index == provider.currentSubfolders.length - 1 ? 0 : 8,
                        ),
                        child: FolderCard(
                          folder: folder,
                          onTap: () {
                            provider.navigateToFolder(folderUid: folder.uid, folderName: folder.name);
                          },
                        ),
                      );
                    }, childCount: provider.currentSubfolders.length),
                  ),
                ],

                // Videos Section
                if (hasVideoSection) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(title: 'Videos', count: videoCount),
                  ),
                  if (provider.currentVideos.isEmpty) ...[
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No videos in this folder', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == provider.currentVideos.length) {
                          if (provider.isLoadingMore) {
                            return const Center(
                              child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final video = provider.currentVideos[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: index == provider.currentVideos.length - 1 ? 16 : 8,
                          ),
                          child: VideoCard(
                            video: video,
                            onWatch: () {
                              _showVideoDialog(context, video);
                            },
                          ),
                        );
                      }, childCount: provider.currentVideos.length + (provider.hasMoreVideos ? 1 : 0)),
                    ),
                  ],
                ],

                // Empty state
                if (provider.currentSubfolders.isEmpty && provider.currentVideos.isEmpty && !provider.isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('This folder is empty', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),

                // Video count footer
                if (provider.currentVideos.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Showing ${provider.currentVideos.length} ${provider.currentVideos.length == 1 ? 'video' : 'videos'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVideoDialog(BuildContext context, VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(video.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (video.description.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(video.description)),
            Container(
              width: double.maxFinite,
              height: 200,
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill, size: 64, color: Colors.blue[400]),
                    const SizedBox(height: 8),
                    Text('Video Player', style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open video player
              _openVideoPlayer(context, video);
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  void _openVideoPlayer(BuildContext context, VideoModel video) {
    // Navigate to video player screen or open URL
    if (video.videoLink != null) {
      // You can launch URL or navigate to video player
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing: ${video.title}')));
    }
  }

  // In your gallery detail screen, when opening a folder:
  void _openFolder(FolderModel folder) {
    final provider = Provider.of<FolderBrowserProvider>(context, listen: false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<FolderBrowserProvider>.value(
          value: provider, // Reuse the same provider instance
          child: FolderBrowserScreen(
            batchId: widget.batchId,
            galleryUid: widget.galleryUid,
            galleryName: widget.galleryName,
            galleryDescription: widget.galleryDescription,
          ),
        ),
      ),
    ).then((_) {
      // When coming back, refresh if needed
      provider.refreshCurrentFolder();
    });
  }
}
