import 'package:flutter/material.dart';
import '../domain/day_activity.dart';

extension DecorationPresentation on CalendarDecoration {
  String get label => name[0].toUpperCase() + name.substring(1);
  IconData get icon => switch (this) {
        CalendarDecoration.flower => Icons.local_florist_outlined,
        CalendarDecoration.star => Icons.star_outline,
        CalendarDecoration.leaf => Icons.eco_outlined
      };
}

/// Raster artwork is decorative; the surrounding day/chip supplies semantics.
class CalendarSticker extends StatelessWidget {
  const CalendarSticker(
      {super.key, required this.decoration, this.size = 18, this.color});
  final CalendarDecoration decoration;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => decoration == CalendarDecoration.flower
      ? Image.asset('assets/stickers/jasmine.png',
          width: size,
          height: size,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
          fit: BoxFit.contain,
          excludeFromSemantics: true)
      : Icon(decoration.icon, size: size, color: color);
}
