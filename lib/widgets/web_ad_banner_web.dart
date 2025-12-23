import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui_web' as ui_web;
import 'package:universal_html/html.dart' as html;

class WebAdBanner extends StatefulWidget {
  final String adSlot;
  final double width;
  final double height;

  const WebAdBanner({
    super.key,
    required this.adSlot,
    this.width = 300,
    this.height = 250,
  });

  @override
  State<WebAdBanner> createState() => _WebAdBannerState();
}

class _WebAdBannerState extends State<WebAdBanner> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'ad-view-${widget.adSlot}';

    // Register the HTML element factory
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final container = html.DivElement()
        ..id = 'ad-container-${widget.adSlot}'
        ..style.width = '${widget.width}px'
        ..style.height = '${widget.height}px'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'inline-block'
        ..style.width = '${widget.width}px'
        ..style.height = '${widget.height}px'
        ..setAttribute('data-ad-client', 'ca-pub-3855771133052397')
        ..setAttribute('data-ad-slot', widget.adSlot);

      container.append(ins);

      // Execute the push call for AdSense
      final script = html.ScriptElement()
        ..text = '(adsbygoogle = window.adsbygoogle || []).push({});';
      container.append(script);

      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
