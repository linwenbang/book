import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PicWidget extends StatelessWidget {
  final Uint8List kTransparentImage = new Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
  ]);
  String url;
  double height;
  double width;
  bool fitOk;
  double radius;

  PicWidget(
    this.url, {
    this.height = 115,
    this.width = 97,
    this.fitOk,
    this.radius: 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) => ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          "images/bg.png",
          width: width,
          height: height,
        ),
      ),
    );
  }
}
