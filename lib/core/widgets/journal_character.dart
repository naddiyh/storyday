import 'package:flutter/material.dart';

/// The supplied character artwork stays intact at every display size.
class JournalCharacter extends StatelessWidget {
  const JournalCharacter({super.key, this.width = 76, this.height = 88});
  static const asset = 'assets/characters/companion.png';
  final double width, height;

  @override
  Widget build(BuildContext context) => Image.asset(asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).ceil(),
      excludeFromSemantics: true);
}
