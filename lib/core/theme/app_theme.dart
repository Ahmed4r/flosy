import 'package:flosy/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.whiteColor,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorButton,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
