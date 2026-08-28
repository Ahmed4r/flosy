import 'package:flutter/material.dart';

class AppThemeColorPreset {
  final String id;
  final String nameKey;
  final Color color;

  const AppThemeColorPreset({
    required this.id,
    required this.nameKey,
    required this.color,
  });
}

class AppColors {
  static const whiteColor = Color(0xfff7f9f6);
  static const blackColor = Color(0xff121212);
  static const redColor = Color(0xffed1313);
  static const greyColor = Color(0xff888888);
  static const orangeColor = Color(0xffffa500);
  
  static Color _accentColor = const Color(0xff13ed5a);

  static Color get greenColor => _accentColor;
  static Color get colorButton => _accentColor;
  static Color get accentColor => _accentColor;

  static void setAccentColor(Color color) {
    _accentColor = color;
  }

  static const textFieldFill = Color.fromARGB(104, 215, 216, 214);
  static const textFieldFillDark = Color.fromARGB(104, 142, 143, 142);

  // Available Theme Colors
  static const List<AppThemeColorPreset> themePresets = [
    AppThemeColorPreset(id: 'emerald', nameKey: 'theme.emerald', color: Color(0xff13ed5a)),
    AppThemeColorPreset(id: 'cyan', nameKey: 'theme.cyan', color: Color(0xff00d2ff)),
    AppThemeColorPreset(id: 'royal_blue', nameKey: 'theme.blue', color: Color(0xff3a86ff)),
    AppThemeColorPreset(id: 'violet', nameKey: 'theme.violet', color: Color(0xff8338ec)),
    AppThemeColorPreset(id: 'rose_pink', nameKey: 'theme.pink', color: Color(0xffff006e)),
    AppThemeColorPreset(id: 'sunset_orange', nameKey: 'theme.orange', color: Color(0xfffb5607)),
    AppThemeColorPreset(id: 'amber_gold', nameKey: 'theme.gold', color: Color(0xffffbe0b)),
    AppThemeColorPreset(id: 'teal', nameKey: 'theme.teal', color: Color(0xff06d6a0)),
  ];

  // Tile Custom Palette for Transactions
  static const List<Color> tileColors = [
    Color(0xff13ed5a), // Emerald
    Color(0xff00d2ff), // Cyan
    Color(0xff3a86ff), // Royal Blue
    Color(0xff8338ec), // Violet
    Color(0xffff006e), // Rose Pink
    Color(0xfffb5607), // Sunset Orange
    Color(0xffffbe0b), // Amber Gold
    Color(0xff06d6a0), // Teal
    Color(0xffe63946), // Crimson
    Color(0xff6c757d), // Slate Gray
  ];
}
