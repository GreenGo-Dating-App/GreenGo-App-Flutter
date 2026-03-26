import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/country_centroids.dart';
import '../../domain/entities/globe_user.dart';

class GlobeWebView extends StatefulWidget {
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;
  final String? flyToCountry;
  final void Function(String userId, GlobePinType pinType) onPinTapped;
  final void Function(String countryName, double lat, double lng)
      onCountryTapped;

  const GlobeWebView({
    super.key,
    required this.data,
    required this.showMatched,
    required this.showDiscovery,
    this.flyToCountry,
    required this.onPinTapped,
    required this.onCountryTapped,
  });

  @override
  State<GlobeWebView> createState() => _GlobeWebViewState();
}

class _GlobeWebViewState extends State<GlobeWebView> {
  late WebViewController _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<String> _getCesiumToken() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();
      final token = remoteConfig.getString('cesium_ion_token');
      if (token.isNotEmpty) return token;
    } catch (_) {
      // Fall back to dart-define
    }
    // Fallback: build-time token via --dart-define=CESIUM_TOKEN=xxx
    const buildToken = String.fromEnvironment('CESIUM_TOKEN', defaultValue: '');
    return buildToken;
  }

  Future<void> _initController() async {
    final html = await rootBundle.loadString('assets/web/globe.html');
    final cesiumToken = await _getCesiumToken();
    final injected = html.replaceFirst('__CESIUM_ION_TOKEN__', cesiumToken);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'GlobeChannel',
        onMessageReceived: (message) {
          try {
            final data =
                jsonDecode(message.message) as Map<String, dynamic>;
            if (data['type'] == 'countryTap') {
              widget.onCountryTapped(
                data['country'] as String,
                (data['lat'] as num).toDouble(),
                (data['lng'] as num).toDouble(),
              );
            } else {
              final pinType = _parsePinType(data['pinType'] as String);
              widget.onPinTapped(data['userId'] as String, pinType);
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          _pageLoaded = true;
          _injectPinData();
        },
      ))
      ..loadHtmlString(injected, baseUrl: 'https://cesium.com');

    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant GlobeWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pageLoaded) return;

    if (widget.data != oldWidget.data ||
        widget.showMatched != oldWidget.showMatched ||
        widget.showDiscovery != oldWidget.showDiscovery) {
      _injectPinData();
    }

    if (widget.flyToCountry != null &&
        widget.flyToCountry != oldWidget.flyToCountry) {
      _flyToCountry(widget.flyToCountry!);
    }
  }

  void _injectPinData() {
    final payload = {
      'currentUser': _serializeUser(widget.data.currentUser),
      'matched': widget.showMatched
          ? widget.data.matchedUsers.map(_serializeUser).toList()
          : [],
      'discovery': widget.showDiscovery
          ? widget.data.discoveryUsers.map(_serializeUser).toList()
          : [],
    };
    final json = jsonEncode(payload);
    final escaped = json.replaceAll("'", "\\'");
    _controller.runJavaScript("loadPins('$escaped')");
  }

  void _flyToCountry(String country) {
    final centroid = countryCentroids[country];
    if (centroid != null) {
      _controller.runJavaScript(
        "flyToLocation(${centroid[0]}, ${centroid[1]})",
      );
    }
  }

  Map<String, dynamic> _serializeUser(GlobeUser u) => {
        'userId': u.userId,
        'displayName': u.displayName,
        'photoUrl': u.photoUrl,
        'lat': u.pinLatitude,
        'lng': u.pinLongitude,
        'country': u.country,
        'isOnline': u.isOnline,
        'isTraveler': u.isTravelerActive,
        'pinType': u.pinType.name,
        if (u.realCountryLatitude != null)
          'realCountryLat': u.realCountryLatitude,
        if (u.realCountryLongitude != null)
          'realCountryLng': u.realCountryLongitude,
      };

  GlobePinType _parsePinType(String s) => GlobePinType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => GlobePinType.discovery,
      );

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
