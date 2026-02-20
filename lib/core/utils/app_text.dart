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
      return GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
    }
  }

  static TextStyle head24(BuildContext context) =>
      _getFontStyle(context, 24, FontWeight.bold, const Color(0xff333333));

  static TextStyle body16(BuildContext context) =>
      _getFontStyle(context, 16, FontWeight.w400, const Color(0xff333333));
  static TextStyle body11(BuildContext context) =>
      _getFontStyle(context, 11, FontWeight.w400, const Color(0xff333333));
  static TextStyle body13(BuildContext context) =>
      _getFontStyle(context, 13, FontWeight.w400, const Color(0xff333333));
  static TextStyle body12(BuildContext context) =>
      _getFontStyle(context, 12, FontWeight.w400, const Color(0xff333333));
  static TextStyle body14(BuildContext context) =>
      _getFontStyle(context, 14, FontWeight.w400, const Color(0xff333333));
  static TextStyle body15(BuildContext context) =>
      _getFontStyle(context, 15, FontWeight.w400, const Color(0xff333333));
  static TextStyle body17(BuildContext context) =>
      _getFontStyle(context, 17, FontWeight.w400, const Color(0xff333333));
  static TextStyle body18(BuildContext context) =>
      _getFontStyle(context, 18, FontWeight.w400, const Color(0xff333333));
  static TextStyle body12grey(BuildContext context) =>
      _getFontStyle(context, 12, FontWeight.w400, const Color(0xff888888));
  static TextStyle textButton(BuildContext context) =>
      _getFontStyle(context, 22, FontWeight.bold, const Color(0xff333333));
  static TextStyle head20(BuildContext context) =>
      _getFontStyle(context, 20, FontWeight.bold, const Color(0xff333333));
  static TextStyle head32(BuildContext context) =>
      _getFontStyle(context, 32, FontWeight.bold, const Color(0xff333333));
  static TextStyle body20(BuildContext context) =>
      _getFontStyle(context, 20, FontWeight.bold, const Color(0xff333333));
  static TextStyle body28(BuildContext context) =>
      _getFontStyle(context, 28, FontWeight.bold, const Color(0xff333333));
  static TextStyle head28(BuildContext context) =>
      _getFontStyle(context, 28, FontWeight.bold, const Color(0xff333333));
  static TextStyle body36(BuildContext context) =>
      _getFontStyle(context, 36, FontWeight.bold, const Color(0xff333333));
}
