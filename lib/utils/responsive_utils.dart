import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Screen type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Responsive values
  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  // Grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  // Content padding
  static EdgeInsets getContentPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  // Maximum content width for readability
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  // Chat layout type
  static bool shouldUseTwoColumnChat(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1000;
  }

  // Sidebar behavior
  static bool shouldShowPersistentSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1100;
  }

  // Font size scaling
  static double getScaledFontSize(BuildContext context, double baseFontSize) {
    if (isDesktop(context)) return baseFontSize * 1.1;
    if (isTablet(context)) return baseFontSize * 1.05;
    return baseFontSize;
  }
}

// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

// Responsive layout wrapper
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool centerContent;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getContentPadding(context),
      child: centerContent
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                ),
                child: child,
              ),
            )
          : child,
    );
  }
}