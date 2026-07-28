import 'package:flutter/widgets.dart';

/// Rebuilds a category/account icon from a stored codepoint in the app's icon
/// font — Phosphor **Fill**, the rounded filled style used app-wide. Codepoints
/// are Phosphor codepoints (the picker/seed store them).
IconData appIconData(int codePoint) => IconData(
  codePoint,
  fontFamily: 'PhosphorFill',
  fontPackage: 'phosphor_flutter',
);
