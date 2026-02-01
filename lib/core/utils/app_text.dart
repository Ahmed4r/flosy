import 'dart:ui';
import 'package:flutter/src/painting/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  static TextStyle get head24 =>
      GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w600);

  static TextStyle get body16 => GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xff333333),
  );
}
