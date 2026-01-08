// Conditional export to handle dart:ui_web dependency
// This ensures the app builds on mobile (where dart:ui_web is unavailable)
// while keeping the functionality on web.

export 'web_ad_banner_stub.dart'
    if (dart.library.html) 'web_ad_banner_web.dart';
