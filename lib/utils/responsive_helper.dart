import 'package:flutter/material.dart';

enum Breakpoint { compact, standard, expanded, tablet }

class ResponsiveHelper {
  final double width;
  final double height;
  final Orientation orientation;

  static const double _ref = 390.0;

  ResponsiveHelper._({
    required this.width,
    required this.height,
    required this.orientation,
  });

  factory ResponsiveHelper.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ResponsiveHelper._(
      width: mq.size.width,
      height: mq.size.height,
      orientation: mq.orientation,
    );
  }

  Breakpoint get breakpoint {
    if (width <= 360) return Breakpoint.compact;
    if (width <= 414) return Breakpoint.standard;
    if (width <= 600) return Breakpoint.expanded;
    return Breakpoint.tablet;
  }

  bool get isTablet => breakpoint == Breakpoint.tablet;
  bool get isExpanded => breakpoint == Breakpoint.expanded;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Scale a value proportionally to screen width vs 390dp reference
  double scale(double base) => base * (width / _ref);

  /// Percentage of screen width
  double wp(double percent) => width * percent / 100;

  /// Percentage of screen height
  double hp(double percent) => height * percent / 100;

  /// Scaled font size
  double sp(double fontSize) => scale(fontSize);
}
