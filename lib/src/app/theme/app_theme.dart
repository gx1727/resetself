import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const seedColor = Color(0xFF819B8E);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        // 去掉 Card 默认的 4dp 外边距，让所有卡片与页面内容区等宽对齐。
        margin: EdgeInsets.zero,
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF8E8E93),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E5EA)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E5EA)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: seedColor, width: 1.5),
        ),
      ),
    );
  }
}
