import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';

mixin Seed {
  SizedBox get kHeight30 => const SizedBox(height: 15);
}

class Styles with Seed {
  bool _isDark;
  Styles._internal({required bool isDark}) : _isDark = isDark;
  factory Styles.seed({required bool isDark}) =>
      Styles._internal(isDark: isDark);

  ThemeData get getThemeData => ThemeData(
        useMaterial3: true,
        brightness: _isDark ? Brightness.dark : Brightness.light,
        textTheme: TextTheme(
          headline1: GoogleFonts.lato(fontSize: 18),
        ),
      );
}
