import 'package:flutter/material.dart';

Widget imagePreview(String? path, {BoxFit fit = BoxFit.cover}) {
  if (path == null || path.isEmpty) return const SizedBox.shrink();
  // On web, camera plugin may return blob URLs or data URLs; Image.network handles them.
  return Image.network(path, fit: fit);
}
