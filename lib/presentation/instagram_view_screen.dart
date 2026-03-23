import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdvancedInstaCarousel extends StatefulWidget {
  const AdvancedInstaCarousel({super.key});

  @override
  State<AdvancedInstaCarousel> createState() => _AdvancedInstaCarouselState();
}

class _AdvancedInstaCarouselState extends State<AdvancedInstaCarousel>
    with AutomaticKeepAliveClientMixin {
  List<String> images = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? nextUrl;
  final int imagesPerPage = 15;

  // Preload queue for next batch
  List<String> preloadedImages = [];
  bool isPreloading = false;

  @override
  bool get wantKeepAlive => true; // Keep state when tab changes

  @override
  void initState() {
    super.initState();
    loadInitialImages();
  }

  Future<void> loadInitialImages() async {
    setState(() => isLoading = true);
    await fetchInstagramImages(reset: true);
    setState(() => isLoading = false);

    // Start preloading next batch immediately
    if (nextUrl != null) {
      preloadNextBatch();
    }
  }

  Future<void> fetchInstagramImages({bool reset = false}) async {
    try {
      String token =
          "IGAARYxzHq6nZABZAFk2WGM1eG9DT1FwOGl5a09ZAZAkZAiRzJzd1MwWm9QcFVud09KT0dZAakhxVTRVc2MyZAHplSjNEcUh0YjV5eEtlUWVWNUp5SmswZAHdWLWptOG1Xa3QyXzgwNXpGa2xKcjM2V0d2alhsXzZAudjBjOU56Qkp3U2d1VQZDZD";

      String? requestUrl =
          nextUrl ??
          "https://graph.instagram.com/me/media?fields=id,media_type,media_url&access_token=$token&limit=$imagesPerPage";

      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List media = data["data"];

        List<String> newImages = media
            .where((item) => item["media_type"] == "IMAGE")
            .map<String>((item) => item["media_url"])
            .toList();

        setState(() {
          if (reset) {
            images = newImages;
          } else {
            images.addAll(newImages);
          }
        });

        // Pre-cache images
        for (String url in newImages) {
          await precacheImage(CachedNetworkImageProvider(url), context);
        }

        if (data["paging"] != null && data["paging"]["next"] != null) {
          nextUrl = data["paging"]["next"];
        } else {
          nextUrl = null;
        }

        print("Loaded ${newImages.length} images. Total: ${images.length}");
      }
    } catch (e) {
      print("Error fetching images: $e");
    }
  }

  Future<void> preloadNextBatch() async {
    if (isPreloading || nextUrl == null) return;

    isPreloading = true;

    try {
      String token =
          "IGAARYxzHq6nZABZAFk2WGM1eG9DT1FwOGl5a09ZAZAkZAiRzJzd1MwWm9QcFVud09KT0dZAakhxVTRVc2MyZAHplSjNEcUh0YjV5eEtlUWVWNUp5SmswZAHdWLWptOG1Xa3QyXzgwNXpGa2xKcjM2V0d2alhsXzZAudjBjOU56Qkp3U2d1VQZDZD";

      final response = await http.get(Uri.parse(nextUrl!));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List media = data["data"];

        preloadedImages = media
            .where((item) => item["media_type"] == "IMAGE")
            .map<String>((item) => item["media_url"])
            .toList();

        // Pre-cache these images
        for (String url in preloadedImages) {
          await precacheImage(CachedNetworkImageProvider(url), context);
        }

        if (data["paging"] != null && data["paging"]["next"] != null) {
          nextUrl = data["paging"]["next"];
        } else {
          nextUrl = null;
        }
      }
    } catch (e) {
      print("Error preloading images: $e");
    } finally {
      isPreloading = false;
    }
  }

  Future<void> loadMoreImages() async {
    if (isLoadingMore || nextUrl == null) return;

    setState(() => isLoadingMore = true);

    // Use preloaded images if available
    if (preloadedImages.isNotEmpty) {
      setState(() {
        images.addAll(preloadedImages);
        preloadedImages.clear();
      });

      // Start preloading next batch
      if (nextUrl != null) {
        preloadNextBatch();
      }
    } else {
      await fetchInstagramImages();
    }

    setState(() => isLoadingMore = false);
  }

  void _checkAndLoadMore(int index) {
    if (!isLoadingMore && nextUrl != null && index >= images.length - 3) {
      loadMoreImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (isLoading) {
      return _buildShimmerLoader();
    }

    if (images.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        Center(
          child: Text(
            "Our Success Stories",
            style: AppTextStyles.activitySubtitle,
          ),
        ),

        const SizedBox(height: 10),
        CarouselSlider(
          options: CarouselOptions(
            height: 280,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.6,
            onPageChanged: (index, reason) {
              _checkAndLoadMore(index);
            },
          ),
          items: images.map((imageUrl) {
            return Container(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.fitHeight,
                  width: double.infinity,
                  memCacheWidth: 500, // Optimize cache size
                  memCacheHeight: 600,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Status indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${images.length} images',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                ),
              if (nextUrl == null && !isLoadingMore)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.done_all, size: 16, color: Colors.green),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoader() {
    return Center(
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: ShimmerWidget(width: double.infinity, height: 180),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: ShimmerWidget(width: double.infinity, height: 200),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShimmerWidget(width: double.infinity, height: 180),
              ),
            ],
          ),
          const Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
