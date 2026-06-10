import 'package:flutter/widgets.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 700;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 700 && width < 1100;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;
}
