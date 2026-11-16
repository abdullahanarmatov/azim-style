import 'package:material_ui/material_ui.dart';

/// Brand palette: quiet neutrals with a warm camel accent.
class AppColors {
  const AppColors._();

  static const ink = Color(0xFF141414);
  static const paper = Color(0xFFFAF8F5);
  static const sand = Color(0xFFEFE9E1);
  static const stone = Color(0xFF8A8580);
  static const camel = Color(0xFFB08D57);
  static const camelDark = Color(0xFFD2B07A);
  static const night = Color(0xFF0F0F10);
  static const nightSurface = Color(0xFF1C1B1A);
  static const success = Color(0xFF3F7D58);
  static const danger = Color(0xFFB3261E);

  /// Soft tints used for image placeholders, picked by a stable hash.
  static const placeholders = [
    Color(0xFFE8E1D7),
    Color(0xFFDCE1DA),
    Color(0xFFE4DCE0),
    Color(0xFFD9DFE6),
    Color(0xFFE9E3D3),
  ];
}
