import 'package:flutter/cupertino.dart';

class AppColors {
  // Surface hierarchy (auto-responds to light/dark theme)
  static const surface1 = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: Color(0xFF1C1C1E),
  );
  static const surface2 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF2C2C2E),
  );
  static const surface3 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFE5E5EA),
    darkColor: Color(0xFF3A3A3C),
  );
  static const separator = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFC6C6C8),
    darkColor: Color(0xFF38383A),
  );

  // System accent colors (already adaptive)
  static const accent = CupertinoColors.activeBlue;
  static const destructive = CupertinoColors.destructiveRed;
  static const success = CupertinoColors.systemGreen;

  // Category colors for password entries (fixed, theme-independent)
  static const categoryColors = [
    Color(0xFF007AFF), // blue
    Color(0xFF34C759), // green
    Color(0xFFFF9500), // orange
    Color(0xFFAF52DE), // purple
    Color(0xFFFF3B30), // red
    Color(0xFF5AC8FA), // cyan
    Color(0xFFFF2D55), // pink
    Color(0xFF5856D6), // indigo
    Color(0xFF00C7BE), // teal
    Color(0xFFFFCC00), // yellow
  ];

  static bool isDark(BuildContext context) {
    return (CupertinoTheme.of(context).brightness ??
            MediaQuery.platformBrightnessOf(context)) ==
        Brightness.dark;
  }
}
