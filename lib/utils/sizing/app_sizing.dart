// lib/constants/app_spacing.dart (put in core package for monorepos)
import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // 8px grid system (common professional standard; change base to update all)
  static const double base = 8.0;

  static const double xs = base * 0.5; // 4
  static const double sm = base * 1; // 8
  static const double md = base * 2; // 16
  static const double lg = base * 3; // 24
  static const double xl = base * 4; // 32
  static const double xxl = base * 6; // 48

  // Predefined const widgets
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);

  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);
}
