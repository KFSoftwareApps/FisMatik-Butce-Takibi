import 'package:flutter/material.dart';

class AppIcons {
  static const Map<int, IconData> _iconMap = {
    0xe59c: Icons.shopping_cart,
    0xe532: Icons.restaurant,
    0xe3e7: Icons.local_gas_station,
    0xe15f: Icons.checkroom,
    0xe1b8: Icons.computer,
    0xe357: Icons.local_hospital,
    0xe145: Icons.category,
    0xe5c3: Icons.star,
    0xe149: Icons.label, // Default label icon if needed
  };

  static IconData getIcon(int code) {
    return _iconMap[code] ?? Icons.help_outline;
  }
}
