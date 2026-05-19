import 'package:flutter/material.dart';

/// Returns an ImageProvider for the given path (web platform).
/// On web, file paths from DB are asset paths (e.g. "assets/novel_covers/x.jpg")
ImageProvider buildImageProvider(String path) {
  return AssetImage(path);
}
