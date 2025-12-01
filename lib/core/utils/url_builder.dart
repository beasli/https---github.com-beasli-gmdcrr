import '../config/api.dart';

class UrlBuilder {
  /// Build a full URL for the given path. If [pathOrUrl] is already an absolute URL
  /// (starts with http:// or https://), it is returned unchanged.
  /// If it begins with a leading slash or not, it will be appended to the [kApiBaseUrl].
  static String build(String pathOrUrl) {
    final input = pathOrUrl.trim();
    if (input.startsWith('http://') || input.startsWith('https://')) return input;
      final base = kApiBaseUrl.trim();
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = input.startsWith('/') ? input : '/$input';
      return '$normalizedBase$normalizedPath'.replaceFirst('', '');
  }
}
