
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CircularCachedNetworkProfileImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Color buttonPrimaryColor;
  final bool? isCamp;

  const CircularCachedNetworkProfileImage({
    super.key,
    required this.imageUrl,
    this.size = 80,required this.buttonPrimaryColor, this.isCamp = false
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            width: size,
            height: size,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          isCamp! ? 'assets/images/ic_camp.png':Theme.of(context).brightness == Brightness.dark
              ? 'assets/images/ic_dark.png'
              : 'assets/images/ic_light.png',
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      ),
    );
  }
}