import 'package:flutter/widgets.dart';

/// Rebuilds a category/account icon from a stored codepoint in the app's icon
/// font — Solar **Bold** (soft, rounded). Category/account icons use Solar; the
/// UI chrome uses Phosphor Fill (Solar lacks clean bare chrome glyphs). Stored
/// codepoints are Solar codepoints.
IconData appIconData(int codePoint) => IconData(
  codePoint,
  fontFamily: 'SolarIconsBold',
  fontPackage: 'solar_icons',
);
