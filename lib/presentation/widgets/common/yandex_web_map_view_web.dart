// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

class YandexWebMapView extends StatefulWidget {
  final String url;

  const YandexWebMapView({
    super.key,
    required this.url,
  });

  @override
  State<YandexWebMapView> createState() => _YandexWebMapViewState();
}

class _YandexWebMapViewState extends State<YandexWebMapView> {
  static int _nextId = 0;
  late final String _viewType;
  late final html.IFrameElement _iframe;

  @override
  void initState() {
    super.initState();
    _viewType = 'yandex-web-map-view-${_nextId++}';
    _iframe = html.IFrameElement()
      ..src = widget.url
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('allowfullscreen', 'true')
      ..allow = 'geolocation *; fullscreen *';

    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int _) => _iframe);
  }

  @override
  void didUpdateWidget(covariant YandexWebMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _iframe.src = widget.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
