import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'AGR Converter';
  static const String companyName = 'AGR Soft';
  static const String appTagline = 'PDF to CSV Made Simple';

  // Colors
  static const Color primaryColor = Color(0xFFD23737);
  static const Color secondaryColor = Color(0xFFE04F4E);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;

  // Gradients
  static Gradient primaryGradient = const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}