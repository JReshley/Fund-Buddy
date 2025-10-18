import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/transaction_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  bool isDarkMode = false;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
  }

  //elements colors
  Color get appColor => isDarkMode ? Color(0xFF212F4B) : Color(0xFFF7F7F7);
  Color get backgroundColor => isDarkMode ? Color(0xFF0D1B2A) : Color(0xFFEEF2F6);
  Color get boxshadow => isDarkMode ? Color(0xFF212F4B) : Color(0xFF05090F);
  Color get logboxshadow => isDarkMode ? Color(0xFF727f8c) : Color(0xFF05090F);
  Color get navColor => isDarkMode ? Color(0xFFb3b3b3) : Color(0xFF4F4F4F);
  Color get boxColor => isDarkMode ? Color(0xFF1B263B) : Color(0xFFF7F7F7);
  Color get logboxColor => isDarkMode ? Color(0xFF2a3644) : Color(0xFFEAEAEA);
  Color get logCircleColor => isDarkMode ? Color(0xFF212F4B) : Color(0xFFEAEAEA).withOpacity(0.4);
  Color get coverphoto => isDarkMode ? Color(0xFFA9B8D4) : Color(0xFF64B5F6);
  Color get transactionBox => isDarkMode ? Color(0xFF212F4B) : Color(0xFFF2F3F5);

  //text colors
  Color get loginColor => isDarkMode ? Color(0xFFDDE2EA) : Color(0xFF4F4F4F);
  Color get headerColor => isDarkMode ? Color(0xFFDDE2EA) : Color(0xFF0D1B2A);
  Color get textColor => isDarkMode ? Color(0xFFA9B8D4) : Color(0xFF0D1B2A);
  Color get header2Color => isDarkMode ? Color(0xFF64B5F6) : Color(0xFF0D1B2A);
  Color get hintColor => isDarkMode ? Color(0xFF64B5F6) : Color(0XFF757575);
  Color get loghintColor => isDarkMode ? Color(0xFFD9D9D9) : Colors.grey[600]!;
  Color get logtextColor => isDarkMode ? Color(0xFFD9D9D9) : Color(0xFF05090F);
  Color get cancelColor => isDarkMode ? Color(0xFF64B5F6) : Color(0xFF4F4F4F);
}

// Global instance
final themeController = ThemeController();