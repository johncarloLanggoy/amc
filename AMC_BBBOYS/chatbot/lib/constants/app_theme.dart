// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Consistent spacing system
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Consistent border radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 20.0;

  // Animation durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> cardShadowElevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Typography scale
  static TextStyle headline1(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge!.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    );
  }

  static TextStyle headline2(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      height: 1.5,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      height: 1.4,
    );
  }
}