import 'package:flutter/material.dart';

enum ResponsiveDevice { mobile, tablet, desktop }

class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static ResponsiveDevice deviceForWidth(double width) {
    if (width < mobileMax) return ResponsiveDevice.mobile;
    if (width <= tabletMax) return ResponsiveDevice.tablet;
    return ResponsiveDevice.desktop;
  }

  static bool isMobile(BuildContext context) =>
      deviceForWidth(MediaQuery.sizeOf(context).width) ==
      ResponsiveDevice.mobile;

  static bool isTablet(BuildContext context) =>
      deviceForWidth(MediaQuery.sizeOf(context).width) ==
      ResponsiveDevice.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceForWidth(MediaQuery.sizeOf(context).width) ==
      ResponsiveDevice.desktop;
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    final device = ResponsiveBreakpoints.deviceForWidth(
      MediaQuery.sizeOf(context).width,
    );
    return switch (device) {
      ResponsiveDevice.mobile => mobile(context),
      ResponsiveDevice.tablet => (tablet ?? mobile)(context),
      ResponsiveDevice.desktop => (desktop ?? tablet ?? mobile)(context),
    };
  }
}

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.desktopNavigation,
    this.drawer,
    this.bottomNavigationBar,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget? desktopNavigation;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final device = ResponsiveBreakpoints.deviceForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final useDesktopNavigation = device == ResponsiveDevice.desktop;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: useDesktopNavigation ? null : drawer,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (useDesktopNavigation && desktopNavigation != null)
            desktopNavigation!,
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: device == ResponsiveDevice.mobile
          ? bottomNavigationBar
          : null,
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.spacing = 12,
    this.childAspectRatio = 1.2,
    this.mainAxisExtent,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double childAspectRatio;
  final double? mainAxisExtent;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    final device = ResponsiveBreakpoints.deviceForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final columns = switch (device) {
      ResponsiveDevice.mobile => mobileColumns,
      ResponsiveDevice.tablet => tabletColumns,
      ResponsiveDevice.desktop => desktopColumns,
    };
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class ResponsiveSpacing extends StatelessWidget {
  const ResponsiveSpacing({
    super.key,
    this.mobile = 8,
    this.tablet = 12,
    this.desktop = 16,
    this.axis = Axis.vertical,
  });

  final double mobile;
  final double tablet;
  final double desktop;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final value = switch (ResponsiveBreakpoints.deviceForWidth(
      MediaQuery.sizeOf(context).width,
    )) {
      ResponsiveDevice.mobile => mobile,
      ResponsiveDevice.tablet => tablet,
      ResponsiveDevice.desktop => desktop,
    };
    return axis == Axis.vertical
        ? SizedBox(height: value)
        : SizedBox(width: value);
  }
}

class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.data, {
    super.key,
    this.mobileSize = 14,
    this.tabletSize = 16,
    this.desktopSize = 18,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final double mobileSize;
  final double tabletSize;
  final double desktopSize;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final size = switch (ResponsiveBreakpoints.deviceForWidth(
      MediaQuery.sizeOf(context).width,
    )) {
      ResponsiveDevice.mobile => mobileSize,
      ResponsiveDevice.tablet => tabletSize,
      ResponsiveDevice.desktop => desktopSize,
    };
    return Text(
      data,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: size,
        letterSpacing: 0,
      ),
    );
  }
}

class ResponsiveDialog extends StatelessWidget {
  const ResponsiveDialog({
    super.key,
    required this.child,
    this.maxDesktopWidth = 560,
    this.maxTabletWidth = 480,
  });

  final Widget child;
  final double maxDesktopWidth;
  final double maxTabletWidth;

  @override
  Widget build(BuildContext context) {
    final device = ResponsiveBreakpoints.deviceForWidth(
      MediaQuery.sizeOf(context).width,
    );
    if (device == ResponsiveDevice.mobile) {
      return Dialog.fullscreen(child: SafeArea(child: child));
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: device == ResponsiveDevice.tablet
              ? maxTabletWidth
              : maxDesktopWidth,
        ),
        child: child,
      ),
    );
  }
}
