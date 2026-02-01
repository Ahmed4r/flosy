import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  static TextStyle _getFontStyle(
    BuildContext context,
    double size,
    FontWeight weight,
    Color color,
  ) {
    final isArabic = context.locale.languageCode == 'ar';
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
    } else {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
    }
  }

  static TextStyle head24(BuildContext context) =>
      _getFontStyle(context, 32, FontWeight.bold, const Color(0xff333333));

  static TextStyle body16(BuildContext context) =>
      _getFontStyle(context, 16, FontWeight.w400, const Color(0xff333333));
  static TextStyle textButton(BuildContext context) =>
      _getFontStyle(context, 22, FontWeight.bold, const Color(0xff333333));
}
