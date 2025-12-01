import 'dart:io';
import 'package:flutter/material.dart';

Widget imagePreview(String? path, {BoxFit fit = BoxFit.cover}) {
  if (path == null || path.isEmpty) return const SizedBox.shrink();
  final file = File(path);
  if (!file.existsSync()) return const SizedBox.shrink();
  return Image.file(file, fit: fit);
}
