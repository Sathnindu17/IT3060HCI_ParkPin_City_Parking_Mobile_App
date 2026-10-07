import 'package:flutter/material.dart';

/// ParkPin colour tokens – taken from the Figma high-fidelity prototype
/// (IT3060 M02 – Parking App – WE_46).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B3B6F); // navy header, active tab
  static const Color accent = Color(0xFFF5A524); // main action buttons
  static const Color onAccent = Color(0xFF4A2E00); // text on accent buttons
  static const Color background = Color(0xFFF5F7FB); // screen background
  static const Color surface = Colors.white; // cards, inputs
  static const Color border = Color(0xFFE7EAF0); // card + input borders
  static const Color textPrimary = Color(0xFF1A2233);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF16A34A); // free bay outline, live dot
  static const Color successDark = Color(0xFF15803D);
  static const Color successBg = Color(0xFFE7F6EC);
  static const Color occupied = Color(0xFFC7D0E0); // occupied bay fill
  static const Color neutralBg = Color(0xFFEEF0F4); // grey status chip
  static const Color warning = Color(0xFF8A5A00);
  static const Color warningBg = Color(0xFFFFF4DE);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFDECEC);
  static const Color scanner = Color(0xFF0F1E36); // gate-check scanner box
}
