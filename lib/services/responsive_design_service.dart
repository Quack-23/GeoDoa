import 'package:flutter/material.dart';
import '../services/logging_service.dart';

/// Service untuk responsive design
class ResponsiveDesignService {
  static final ResponsiveDesignService _instance =
      ResponsiveDesignService._internal();
  static ResponsiveDesignService get instance => _instance;
  ResponsiveDesignService._internal();

  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Current screen size
  Size _screenSize = const Size(0, 0);
  Orientation _orientation = Orientation.portrait;

  // Responsive settings
  bool _isResponsiveEnabled = true;
  double _baseFontSize = 16.0;
  double _baseSpacing = 8.0;

  // Layout settings
  int _columns = 1;
  double _gutter = 16.0;
  double _margin = 16.0;

  // Getters
  Size get screenSize => _screenSize;
  Orientation get orientation => _orientation;
  bool get isResponsiveEnabled => _isResponsiveEnabled;
  double get baseFontSize => _baseFontSize;
  double get baseSpacing => _baseSpacing;
  int get columns => _columns;
  double get gutter => _gutter;
  double get margin => _margin;

  /// Initialize responsive design service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing responsive design service');

      // Set default values
      _screenSize = const Size(375, 667); // iPhone 6/7/8 size
      _orientation = Orientation.portrait;

      ServiceLogger.info('Responsive design service initialized');
    } catch (e) {
      ServiceLogger.error('Failed to initialize responsive design service',
          error: e);
    }
  }

  /// Update screen size
  void updateScreenSize(Size size, Orientation orientation) {
    _screenSize = size;
    _orientation = orientation;

    // Update responsive settings based on screen size
    _updateResponsiveSettings();

    ServiceLogger.debug('Screen size updated', data: {
      'width': size.width,
      'height': size.height,
      'orientation': orientation.toString(),
      'device_type': getDeviceType().toString(),
    });
  }

  /// Update responsive settings based on screen size
  void _updateResponsiveSettings() {
    final deviceType = getDeviceType();

    switch (deviceType) {
      case DeviceType.mobile:
        _columns = 1;
        _gutter = 16.0;
        _margin = 16.0;
        _baseFontSize = 16.0;
        _baseSpacing = 8.0;
        break;
      case DeviceType.tablet:
        _columns = 2;
        _gutter = 24.0;
        _margin = 24.0;
        _baseFontSize = 18.0;
        _baseSpacing = 12.0;
        break;
      case DeviceType.desktop:
        _columns = 3;
        _gutter = 32.0;
        _margin = 32.0;
        _baseFontSize = 20.0;
        _baseSpacing = 16.0;
        break;
    }
  }

  /// Get device type based on screen size
  DeviceType getDeviceType() {
    if (_screenSize.width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (_screenSize.width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if screen is mobile
  bool isMobile() => getDeviceType() == DeviceType.mobile;

  /// Check if screen is tablet
  bool isTablet() => getDeviceType() == DeviceType.tablet;

  /// Check if screen is desktop
  bool isDesktop() => getDeviceType() == DeviceType.desktop;

  /// Check if screen is landscape
  bool isLandscape() => _orientation == Orientation.landscape;

  /// Check if screen is portrait
  bool isPortrait() => _orientation == Orientation.portrait;

  /// Get responsive font size
  double getResponsiveFontSize(double baseSize) {
    if (!_isResponsiveEnabled) return baseSize;

    final deviceType = getDeviceType();
    double multiplier = 1.0;

    switch (deviceType) {
      case DeviceType.mobile:
        multiplier = 1.0;
        break;
      case DeviceType.tablet:
        multiplier = 1.1;
        break;
      case DeviceType.desktop:
        multiplier = 1.2;
        break;
    }

    return baseSize * multiplier;
  }

  /// Get responsive spacing
  double getResponsiveSpacing(double baseSpacing) {
    if (!_isResponsiveEnabled) return baseSpacing;

    final deviceType = getDeviceType();
    double multiplier = 1.0;

    switch (deviceType) {
      case DeviceType.mobile:
        multiplier = 1.0;
        break;
      case DeviceType.tablet:
        multiplier = 1.2;
        break;
      case DeviceType.desktop:
        multiplier = 1.5;
        break;
    }

    return baseSpacing * multiplier;
  }

  /// Get responsive padding
  EdgeInsets getResponsivePadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      final responsiveAll = getResponsiveSpacing(all);
      return EdgeInsets.all(responsiveAll);
    }

    return EdgeInsets.only(
      left: getResponsiveSpacing(left ?? horizontal ?? 0),
      top: getResponsiveSpacing(top ?? vertical ?? 0),
      right: getResponsiveSpacing(right ?? horizontal ?? 0),
      bottom: getResponsiveSpacing(bottom ?? vertical ?? 0),
    );
  }

  /// Get responsive margin
  EdgeInsets getResponsiveMargin({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      final responsiveAll = getResponsiveSpacing(all);
      return EdgeInsets.all(responsiveAll);
    }

    return EdgeInsets.only(
      left: getResponsiveSpacing(left ?? horizontal ?? 0),
      top: getResponsiveSpacing(top ?? vertical ?? 0),
      right: getResponsiveSpacing(right ?? horizontal ?? 0),
      bottom: getResponsiveSpacing(bottom ?? vertical ?? 0),
    );
  }

  /// Get responsive width
  double getResponsiveWidth(double baseWidth) {
    if (!_isResponsiveEnabled) return baseWidth;

    final deviceType = getDeviceType();
    double multiplier = 1.0;

    switch (deviceType) {
      case DeviceType.mobile:
        multiplier = 1.0;
        break;
      case DeviceType.tablet:
        multiplier = 0.8;
        break;
      case DeviceType.desktop:
        multiplier = 0.6;
        break;
    }

    return _screenSize.width * multiplier;
  }

  /// Get responsive height
  double getResponsiveHeight(double baseHeight) {
    if (!_isResponsiveEnabled) return baseHeight;

    final deviceType = getDeviceType();
    double multiplier = 1.0;

    switch (deviceType) {
      case DeviceType.mobile:
        multiplier = 1.0;
        break;
      case DeviceType.tablet:
        multiplier = 1.1;
        break;
      case DeviceType.desktop:
        multiplier = 1.2;
        break;
    }

    return _screenSize.height * multiplier;
  }

  /// Get responsive columns
  int getResponsiveColumns() {
    if (!_isResponsiveEnabled) return 1;

    final deviceType = getDeviceType();

    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }

  /// Get responsive grid
  Widget getResponsiveGrid({
    required List<Widget> children,
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final columns = getResponsiveColumns();
    final spacing = getResponsiveSpacing(crossAxisSpacing ?? _gutter);
    final mainSpacing = getResponsiveSpacing(mainAxisSpacing ?? _gutter);

    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio ?? 1.0,
      crossAxisSpacing: spacing,
      mainAxisSpacing: mainSpacing,
      children: children,
    );
  }

  /// Get responsive list
  Widget getResponsiveList({
    required List<Widget> children,
    double? spacing,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    final listSpacing = getResponsiveSpacing(spacing ?? _baseSpacing);

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: listSpacing),
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Get responsive card
  Widget getResponsiveCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? elevation,
    Color? color,
  }) {
    final cardPadding = padding ?? getResponsivePadding(all: 16);
    final cardMargin = margin ?? getResponsiveMargin(all: 8);
    final cardElevation = elevation ?? (isMobile() ? 2.0 : 4.0);

    return Card(
      elevation: cardElevation,
      color: color,
      margin: cardMargin,
      child: Padding(
        padding: cardPadding,
        child: child,
      ),
    );
  }

  /// Get responsive button
  Widget getResponsiveButton({
    required Widget child,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    EdgeInsets? padding,
  }) {
    final buttonPadding = padding ??
        getResponsivePadding(
          horizontal: 24,
          vertical: 12,
        );

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Padding(
        padding: buttonPadding,
        child: child,
      ),
    );
  }

  /// Get responsive text
  Widget getResponsiveText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final fontSize = style?.fontSize ?? _baseFontSize;
    final responsiveFontSize = getResponsiveFontSize(fontSize);

    return Text(
      text,
      style: style?.copyWith(fontSize: responsiveFontSize) ??
          TextStyle(fontSize: responsiveFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Get responsive icon
  Widget getResponsiveIcon(
    IconData icon, {
    Color? color,
    double? size,
  }) {
    final iconSize = size ?? _baseFontSize * 1.5;
    final responsiveSize = getResponsiveFontSize(iconSize);

    return Icon(
      icon,
      color: color,
      size: responsiveSize,
    );
  }

  /// Get responsive app bar
  PreferredSizeWidget getResponsiveAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    double? elevation,
  }) {
    final appBarElevation = elevation ?? (isMobile() ? 4.0 : 2.0);
    final titleStyle = TextStyle(
      fontSize: getResponsiveFontSize(20),
      fontWeight: FontWeight.bold,
    );

    return AppBar(
      title: Text(title, style: titleStyle),
      actions: actions,
      leading: leading,
      elevation: appBarElevation,
    );
  }

  /// Get responsive drawer
  Widget getResponsiveDrawer({
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    final drawerPadding = padding ?? getResponsivePadding(all: 16);

    return Drawer(
      child: Padding(
        padding: drawerPadding,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  /// Get responsive bottom sheet
  Widget getResponsiveBottomSheet({
    required Widget child,
    EdgeInsets? padding,
    double? height,
  }) {
    final bottomSheetPadding = padding ?? getResponsivePadding(all: 16);
    final bottomSheetHeight = height ?? _screenSize.height * 0.5;

    return Container(
      height: bottomSheetHeight,
      padding: bottomSheetPadding,
      child: child,
    );
  }

  /// Enable/disable responsive design
  void setResponsiveEnabled(bool enabled) {
    _isResponsiveEnabled = enabled;
    ServiceLogger.info('Responsive design ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set base font size
  void setBaseFontSize(double size) {
    _baseFontSize = size.clamp(12.0, 24.0);
    ServiceLogger.info('Base font size set to $_baseFontSize');
  }

  /// Set base spacing
  void setBaseSpacing(double spacing) {
    _baseSpacing = spacing.clamp(4.0, 32.0);
    ServiceLogger.info('Base spacing set to $_baseSpacing');
  }

  /// Get responsive statistics
  Map<String, dynamic> getResponsiveStats() {
    return {
      'screen_width': _screenSize.width,
      'screen_height': _screenSize.height,
      'orientation': _orientation.toString(),
      'device_type': getDeviceType().toString(),
      'is_mobile': isMobile(),
      'is_tablet': isTablet(),
      'is_desktop': isDesktop(),
      'is_landscape': isLandscape(),
      'is_portrait': isPortrait(),
      'columns': _columns,
      'gutter': _gutter,
      'margin': _margin,
      'base_font_size': _baseFontSize,
      'base_spacing': _baseSpacing,
      'responsive_enabled': _isResponsiveEnabled,
    };
  }

  /// Dispose service
  void dispose() {
    try {
      ServiceLogger.info('Responsive design service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing responsive design service',
          error: e);
    }
  }
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
}
