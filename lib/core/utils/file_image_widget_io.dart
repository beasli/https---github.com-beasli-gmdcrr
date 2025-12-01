import 'dart:io';
import 'package:flutter/material.dart';

Widget fileImageWidget(String path, {double? height, BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('http')) return Image.network(path, height: height, fit: fit);
  return Image.file(File(path), height: height, fit: fit);
}
