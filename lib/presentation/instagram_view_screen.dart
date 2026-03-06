import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//  String token =
//       "IGAARYxzHq6nZABZAFk2WGM1eG9DT1FwOGl5a09ZAZAkZAiRzJzd1MwWm9QcFVud09KT0dZAakhxVTRVc2MyZAHplSjNEcUh0YjV5eEtlUWVWNUp5SmswZAHdWLWptOG1Xa3QyXzgwNXpGa2xKcjM2V0d2alhsXzZAudjBjOU56Qkp3U2d1VQZDZD";

Future<List<String>> fetchInstagramImages() async {
  try {
    String token =
        "IGAARYxzHq6nZABZAFk2WGM1eG9DT1FwOGl5a09ZAZAkZAiRzJzd1MwWm9QcFVud09KT0dZAakhxVTRVc2MyZAHplSjNEcUh0YjV5eEtlUWVWNUp5SmswZAHdWLWptOG1Xa3QyXzgwNXpGa2xKcjM2V0d2alhsXzZAudjBjOU56Qkp3U2d1VQZDZD";

    List<String> allImages = [];
    String? nextUrl =
        "https://graph.instagram.com/me/media?fields=id,media_type,media_url&access_token=$token";

    // Continue fetching while there's a next page and we haven't reached 200+ images
    while (nextUrl != null && allImages.length < 2) {
      final response = await http.get(Uri.parse(nextUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List media = data["data"];

        // Add images from current page
        List<String> pageImages = media
            .where((item) => item["media_type"] == "IMAGE")
            .map<String>((item) => item["media_url"])
            .toList();

        allImages.addAll(pageImages);

        // Check for next page
        if (data["paging"] != null && data["paging"]["next"] != null) {
          nextUrl = data["paging"]["next"];
        } else {
          nextUrl = null;
        }
      } else {
        break;
      }
    }

    print("Total images fetched: ${allImages.length}");
    return allImages;
  } catch (e) {
    print("Error fetching images: $e");
    return [];
  }
}

class InstaCarousel extends StatefulWidget {
  const InstaCarousel({super.key});

  @override
  State<InstaCarousel> createState() => _InstaCarouselState();
}

class _InstaCarouselState extends State<InstaCarousel> {
  List<String> images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  void loadImages() async {
    images = await fetchInstagramImages();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (images.isEmpty) {
      return const SizedBox(); // Prevent blank crash
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 280,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.6,
      ),
      items: images.map((imageUrl) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        );
      }).toList(),
    );
  }
}
