import 'package:flutter/material.dart';

/// One shared, small decoded image for the HUD, welcome and Settings.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 26});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .24),
    child: Image.asset(
      'assets/branding/cleancity-icon-ui.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    ),
  );
}
