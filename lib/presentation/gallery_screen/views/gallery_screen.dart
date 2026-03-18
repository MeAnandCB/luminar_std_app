// screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/gallery_details_screen/controller/gallery_details_screen_controller.dart';
import 'package:luminar_std/presentation/gallery_details_screen/views/gallery_detail_screen.dart';
import 'package:luminar_std/presentation/gallery_screen/controller/gallery_screen_controller.dart';
import 'package:luminar_std/presentation/gallery_screen/views/widgets/gallery_card.dart';
import 'package:luminar_std/repository/gallery_screen/models/gellery_res_model.dart';
import 'package:provider/provider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key, required this.batchId}) : super(key: key);
  final String batchId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _loadInitialData();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    await provider.loadGalleries(widget.batchId, refresh: true);
  }

  Future<void> _loadMore() async {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    await provider.loadNextPage(widget.batchId);
  }

  Future<void> _refresh() async {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    await provider.refreshGalleries(widget.batchId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          if (provider.error != null && provider.galleries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)),
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
                // Galleries List
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == provider.galleries.length) {
                      if (provider.isLoadingMore) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final gallery = provider.galleries[index];
                    return GalleryCard(
                      gallery: gallery,
                      onTap: () {
                        _openGallery(gallery);
                      },
                    );
                  }, childCount: provider.galleries.length + (provider.hasMore ? 1 : 0)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // In more_enrollment_bottom.dart, when opening a gallery:
  void _openGallery(Gallery gallery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderBrowserScreen(
          batchId: widget.batchId,
          galleryUid: gallery.uid,
          galleryName: gallery.name,
          galleryDescription: gallery.description,
        ),
      ),
    );
  }
}
