// noop fallback for non-web platforms. Use conditional import to provide web impl.
Future<void> openUrl(String url) async => null;
