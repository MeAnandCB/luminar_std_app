import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';

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
    if (!mounted) return;
    // Don't re-fetch if we already have images
    if (images.isNotEmpty) return;

    setState(() => isLoading = true);
    await fetchInstagramImages(reset: true);
    if (!mounted) return;
    setState(() => isLoading = false);

    // Start preloading next batch immediately
    if (nextUrl != null) {
      preloadNextBatch();
    }
  }

  Future<void> fetchInstagramImages({bool reset = false}) async {
    try {
      String token =
          "IGAARYxzHq6nZABZAGFfckFSV3RUcHlHcy1QZAUxsQk85LU05QVhjYllIQzZAtdnpiM3ZAyRHRtNkI3X1JvYUlYVEE0LXdVTFhZAbU9rQWx0QXBwa2xoclNHNTZASUkEySjRfY1hYLXpFZA2liUnhmYlVFY09ZAMHR2aGxkby1acjdJc242bwZDZD";

      String? requestUrl =
          nextUrl ??
          "https://graph.instagram.com/me/media?fields=id,media_type,media_url&access_token=$token&limit=$imagesPerPage";

      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        // Parse in a background isolate
        final parsedData = await compute(
          _parseInstagramResponse,
          response.body,
        );
        final List<String> newImages = parsedData['images'];
        final String? next = parsedData['nextUrl'];

        if (!mounted) return;
        setState(() {
          if (reset) {
            images = newImages;
          } else {
            images.addAll(newImages);
          }
        });

        // Pre-cache images in a non-blocking way
        for (String url in newImages) {
          precacheImage(CachedNetworkImageProvider(url), context).catchError((
            e,
          ) {
            debugPrint("Error pre-caching image: $e");
          });
        }

        nextUrl = next;

        LoggerUtils.info(
          "Loaded ${newImages.length} images. Total: ${images.length}",
          tag: 'Instagram',
        );
      } else {
        LoggerUtils.error(
          "Instagram API error ${response.statusCode}: ${response.body}",
          tag: 'Instagram',
        );
      }
    } catch (e) {
      LoggerUtils.error("Error fetching images: $e", tag: 'Instagram');
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
        // Parse in a background isolate
        final parsedData = await compute(
          _parseInstagramResponse,
          response.body,
        );
        preloadedImages = parsedData['images'];

        // Pre-cache these images in a non-blocking way
        for (String url in preloadedImages) {
          if (mounted) {
            precacheImage(CachedNetworkImageProvider(url), context).catchError((
              e,
            ) {
              debugPrint("Error pre-caching preloaded image: $e");
            });
          }
        }

        nextUrl = parsedData['nextUrl'];
      }
    } catch (e) {
      LoggerUtils.error("Error preloading images: $e", tag: 'Instagram');
    } finally {
      isPreloading = false;
    }
  }

  Future<void> loadMoreImages() async {
    if (isLoadingMore || nextUrl == null) return;

    if (!mounted) return;
    setState(() => isLoadingMore = true);

    // Use preloaded images if available
    if (preloadedImages.isNotEmpty) {
      if (!mounted) return;
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

    if (!mounted) return;
    setState(() => isLoadingMore = false);
  }

  void _checkAndLoadMore(int index) {
    if (!isLoadingMore && nextUrl != null && index >= images.length - 3) {
      loadMoreImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (isLoading) {
      return _buildShimmerLoader();
    }

    if (images.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
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

/// Parsing function for the Instagram response.
/// This runs in a background isolate to keep the UI smooth.
Map<String, dynamic> _parseInstagramResponse(String responseBody) {
  final data = jsonDecode(responseBody);
  final List media = data["data"] ?? [];

  final List<String> images = media
      .where((item) => item["media_type"] == "IMAGE")
      .map<String>((item) => item["media_url"] as String)
      .toList();

  String? next;
  if (data["paging"] != null && data["paging"]["next"] != null) {
    next = data["paging"]["next"];
  }

  return {'images': images, 'nextUrl': next};
}
