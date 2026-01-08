import 'package:flutter/material.dart';

class WebAdBanner extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
