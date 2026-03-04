import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class PlacementCarousel extends StatelessWidget {
  PlacementCarousel({Key? key}) : super(key: key);

  final List<String> images = [
    "https://i.pinimg.com/736x/3c/eb/c5/3cebc58c671eff1be1bb32cf9d7289e5.jpg",
    "https://i.pinimg.com/736x/33/18/ed/3318ede7b79daa509ac73d07de12a7dc.jpg",
    "https://i.pinimg.com/736x/ec/52/ad/ec52ade04a46c1421c96323ed64313c2.jpg",
    "https://i.pinimg.com/736x/02/f7/56/02f756d9250b2f44056b8ec75b04424d.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 250,
        enableInfiniteScroll: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 600),
        enlargeCenterPage: true,

        viewportFraction: .7,
      ),
      items: images.map((image) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
