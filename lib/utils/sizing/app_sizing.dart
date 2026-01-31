import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double base = 8.0;

  static const double xs = base * 0.5;
  static const double sm = base * 1;
  static const double md = base * 2;
  static const double lg = base * 3;
  static const double xl = base * 4;
  static const double xxl = base * 6;

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
