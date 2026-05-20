import 'package:flutter/material.dart';

// Web implementation: use Image.asset for asset paths
Widget buildCoverImage(
  String imagePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Color? color,
  BlendMode? colorBlendMode,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  final fallback = Container(
    width: width,
    height: height,
    color: Colors.grey[300],
    child: const Icon(Icons.book, color: Colors.grey),
  );
  return Image.asset(
    imagePath,
    width: width,
    height: height,
    fit: fit,
    color: color,
    colorBlendMode: colorBlendMode,
    errorBuilder: errorBuilder ?? (_, _, _) => fallback,
  );
}
