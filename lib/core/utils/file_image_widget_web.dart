import 'package:flutter/material.dart';

Widget fileImageWidget(String path, {double? height, BoxFit fit = BoxFit.cover}) {
  // On web, blob: and http(s) are usable with Image.network
  if (path.startsWith('http') || path.startsWith('https') || path.startsWith('blob:')) {
    return Image.network(path, height: height, fit: fit);
  }
  // No filesystem access on web — try to use as asset fallback
  return Image.asset(path, height: height, fit: fit);
}
