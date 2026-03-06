import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders animated SVGs (with `<animate>` tags) using a WebView.
/// Falls back to a static icon if WebView fails to initialize.
class AnimatedSvgIcon extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;

  const AnimatedSvgIcon({
    super.key,
    required this.assetPath,
    this.width = 64,
    this.height = 64,
  });

  /// Cache for loaded SVG strings to avoid repeated asset reads.
  static final Map<String, String> _svgCache = {};

  @override
  State<AnimatedSvgIcon> createState() => _AnimatedSvgIconState();
}

class _AnimatedSvgIconState extends State<AnimatedSvgIcon> {
  WebViewController? _controller;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final svgString = await _loadSvg(widget.assetPath);
      if (!mounted) return;

      final html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * { margin: 0; padding: 0; }
  body {
    background: transparent;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100vw;
    height: 100vh;
    overflow: hidden;
  }
  svg { width: 100%; height: 100%; }
</style>
</head>
<body>$svgString</body>
</html>
''';

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..loadHtmlString(html);

      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<String> _loadSvg(String assetPath) async {
    if (AnimatedSvgIcon._svgCache.containsKey(assetPath)) {
      return AnimatedSvgIcon._svgCache[assetPath]!;
    }
    final svgString = await rootBundle.loadString(assetPath);
    AnimatedSvgIcon._svgCache[assetPath] = svgString;
    return svgString;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_isLoaded || _controller == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Icon(Icons.games, color: Colors.white54, size: 32),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: WebViewWidget(controller: _controller!),
    );
  }
}
