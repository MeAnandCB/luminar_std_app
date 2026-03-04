import 'package:flutter/material.dart';

class AppSizing {
  // Base spacing values
  static const double xs = 6;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 36;
  static const double xxxl = 60;

  // EdgeInsets helpers
  static const EdgeInsets padallXs = EdgeInsets.all(xs);
  static const EdgeInsets allS = EdgeInsets.all(s);
  static const EdgeInsets allM = EdgeInsets.all(m);
  static const EdgeInsets allL = EdgeInsets.all(l);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXXl = EdgeInsets.all(xxxl);
  static const EdgeInsets horizontalM = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets horizontalL = EdgeInsets.symmetric(horizontal: l);

  static const EdgeInsets verticalM = EdgeInsets.symmetric(vertical: m);

  // Vertical Spacing Widgets
  static const Widget verticalSpacing4 = SizedBox(height: 4);

  static const Widget verticalSpacing6 = SizedBox(height: 6);
  static const Widget verticalSpacing8 = SizedBox(height: 8);
  static const Widget verticalSpacing12 = SizedBox(height: 12);
  static const Widget verticalSpacing16 = SizedBox(height: 16);
  static const Widget verticalSpacing24 = SizedBox(height: 24);
  static const Widget verticalSpacing36 = SizedBox(height: 36);

  // Horizontal Spacing Widgets
  static const Widget horizontalSpacing4 = SizedBox(width: 4);
  static const Widget horizontalSpacing6 = SizedBox(width: 6);
  static const Widget horizontalSpacing8 = SizedBox(width: 8);
  static const Widget horizontalSpacing12 = SizedBox(width: 12);
  static const Widget horizontalSpacing16 = SizedBox(width: 16);
  static const Widget horizontalSpacingE24 = SizedBox(width: 24);
  static const Widget horizontalSpacingE36 = SizedBox(width: 36);
}
