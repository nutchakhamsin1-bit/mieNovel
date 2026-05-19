import 'dart:io';
import 'package:flutter/material.dart';

/// Returns an ImageProvider for the given file path (native platforms).
ImageProvider buildImageProvider(String path) {
  return FileImage(File(path));
}
