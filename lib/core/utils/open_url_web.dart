import 'dart:html' as html;

Future<void> openUrl(String url) async {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}
