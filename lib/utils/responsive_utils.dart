import 'package:flutter/material.dart';

enum DeviceType { mobile, tabletPortrait, tabletLandscape, desktop }

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletPortraitBreakpoint = 900;
  static const double tabletLandscapeBreakpoint = 1200;
  static DeviceType getDeviceType(double width) {
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletPortraitBreakpoint) {
      return DeviceType.tabletPortrait;
    } else if (width < tabletLandscapeBreakpoint) {
      return DeviceType.tabletLandscape;
    } else {
      return DeviceType.desktop;
    }
  }

  static int getGridColumns(double width) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return 3;
      case DeviceType.tabletPortrait:
        return 4;
      case DeviceType.tabletLandscape:
        return 5;
      case DeviceType.desktop:
        return 6;
    }
  }

  static double getGridPadding(double width) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tabletPortrait:
        return 20.0;
      case DeviceType.tabletLandscape:
        return 24.0;
      case DeviceType.desktop:
        return 32.0;
    }
  }

  static double getAppBarHeight(double width) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return kToolbarHeight;
      case DeviceType.tabletPortrait:
      case DeviceType.tabletLandscape:
        return kToolbarHeight + 8;
      case DeviceType.desktop:
        return kToolbarHeight + 16;
    }
  }

  static double getMaxContentWidth(double width) {
    final deviceType = getDeviceType(width);
    if (deviceType == DeviceType.desktop) {
      return 1400;
    }
    return double.infinity;
  }

  static EdgeInsets getResponsivePadding(double width) {
    final padding = getGridPadding(width);
    return EdgeInsets.all(padding);
  }

  static int getSubMenuColumns(double width) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tabletPortrait:
        return 2;
      case DeviceType.tabletLandscape:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletLandscapeBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletLandscapeBreakpoint;
  }
}
