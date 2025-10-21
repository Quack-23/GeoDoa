import 'package:flutter/material.dart';
import '../services/logging_service.dart';

/// Service untuk optimasi animasi
class AnimationOptimizationService {
  static final AnimationOptimizationService _instance =
      AnimationOptimizationService._internal();
  static AnimationOptimizationService get instance => _instance;
  AnimationOptimizationService._internal();

  // Animation settings
  bool _animationsEnabled = true;
  bool _reduceMotionEnabled = false;
  Duration _defaultDuration = const Duration(milliseconds: 300);
  Duration _fastDuration = const Duration(milliseconds: 150);
  Duration _slowDuration = const Duration(milliseconds: 500);

  // Performance settings
  bool _enableHardwareAcceleration = true;
  bool _enableOpacityAnimations = true;
  bool _enableTransformAnimations = true;
  bool _enableColorAnimations = true;

  // Getters
  bool get animationsEnabled => _animationsEnabled;
  bool get reduceMotionEnabled => _reduceMotionEnabled;
  Duration get defaultDuration => _defaultDuration;
  Duration get fastDuration => _fastDuration;
  Duration get slowDuration => _slowDuration;

  /// Initialize animation optimization service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing animation optimization service');

      // Check system settings for reduce motion
      await _checkSystemSettings();

      ServiceLogger.info('Animation optimization service initialized', data: {
        'animations_enabled': _animationsEnabled,
        'reduce_motion': _reduceMotionEnabled,
        'default_duration': _defaultDuration.inMilliseconds,
      });
    } catch (e) {
      ServiceLogger.error('Failed to initialize animation optimization service',
          error: e);
    }
  }

  /// Check system settings
  Future<void> _checkSystemSettings() async {
    try {
      // Mock implementation - in real app, use accessibility_plus package
      _reduceMotionEnabled = false; // Mock value

      ServiceLogger.debug('System animation settings checked');
    } catch (e) {
      ServiceLogger.error('Error checking system animation settings', error: e);
    }
  }

  /// Enable/disable animations
  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
    ServiceLogger.info('Animations ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable reduce motion
  void setReduceMotionEnabled(bool enabled) {
    _reduceMotionEnabled = enabled;
    ServiceLogger.info('Reduce motion ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get optimized duration
  Duration getOptimizedDuration(Duration baseDuration) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return Duration.zero;
    }
    return baseDuration;
  }

  /// Get optimized curve
  Curve getOptimizedCurve(Curve baseCurve) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return Curves.linear;
    }
    return baseCurve;
  }

  /// Create optimized animation controller
  AnimationController createOptimizedController({
    required TickerProvider vsync,
    Duration? duration,
    Duration? reverseDuration,
    double? lowerBound,
    double? upperBound,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final optimizedDuration =
        getOptimizedDuration(duration ?? _defaultDuration);

    return AnimationController(
      vsync: vsync,
      duration: optimizedDuration,
      reverseDuration: reverseDuration,
      lowerBound: lowerBound ?? 0.0,
      upperBound: upperBound ?? 1.0,
      animationBehavior: animationBehavior,
    );
  }

  /// Create optimized animation
  Animation<T> createOptimizedAnimation<T>({
    required AnimationController controller,
    required T begin,
    required T end,
    Curve? curve,
  }) {
    final optimizedCurve = getOptimizedCurve(curve ?? Curves.easeInOut);

    return Tween<T>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: optimizedCurve,
    ));
  }

  /// Create optimized transition
  Widget createOptimizedTransition({
    required Animation<double> animation,
    required Widget child,
    TransitionType type = TransitionType.fade,
    Duration? duration,
  }) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return child;
    }

    final optimizedDuration =
        getOptimizedDuration(duration ?? _defaultDuration);

    switch (type) {
      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case TransitionType.scale:
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case TransitionType.rotation:
        return RotationTransition(
          turns: animation,
          child: child,
        );
    }
  }

  /// Create optimized page route
  PageRoute<T> createOptimizedPageRoute<T>({
    required Widget child,
    String? name,
    Object? arguments,
    String? restorationId,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    bool fullscreenDialog = false,
    bool maintainState = true,
    bool opaque = true,
    bool barrierDismissible = false,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    final optimizedDuration = getOptimizedDuration(
      transitionDuration ?? _defaultDuration,
    );

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: optimizedDuration,
      reverseTransitionDuration: optimizedDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return createOptimizedTransition(
          animation: animation,
          child: child,
          type: TransitionType.fade,
        );
      },
      settings: RouteSettings(
        name: name,
        arguments: arguments,
      ),
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
    );
  }

  /// Create optimized hero animation
  Widget createOptimizedHero({
    required String tag,
    required Widget child,
    bool createRectTween = false,
    HeroFlightShuttleBuilder? flightShuttleBuilder,
    HeroPlaceholderBuilder? placeholderBuilder,
  }) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return child;
    }

    return Hero(
      tag: tag,
      child: child,
      createRectTween: createRectTween
          ? (begin, end) => RectTween(begin: begin, end: end)
          : null,
      flightShuttleBuilder: flightShuttleBuilder,
      placeholderBuilder: placeholderBuilder,
    );
  }

  /// Create optimized animated container
  Widget createOptimizedAnimatedContainer({
    required Widget child,
    Duration? duration,
    Curve? curve,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Decoration? decoration,
    BoxConstraints? constraints,
    Matrix4? transform,
    AlignmentGeometry? alignment,
  }) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        color: color,
        decoration: decoration,
        constraints: constraints,
        transform: transform,
        alignment: alignment,
        child: child,
      );
    }

    final optimizedDuration =
        getOptimizedDuration(duration ?? _defaultDuration);
    final optimizedCurve = getOptimizedCurve(curve ?? Curves.easeInOut);

    return AnimatedContainer(
      duration: optimizedDuration,
      curve: optimizedCurve,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      constraints: constraints,
      transform: transform,
      alignment: alignment,
      child: child,
    );
  }

  /// Create optimized animated opacity
  Widget createOptimizedAnimatedOpacity({
    required Widget child,
    required double opacity,
    Duration? duration,
    Curve? curve,
  }) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return Opacity(
        opacity: opacity,
        child: child,
      );
    }

    final optimizedDuration =
        getOptimizedDuration(duration ?? _defaultDuration);
    final optimizedCurve = getOptimizedCurve(curve ?? Curves.easeInOut);

    return AnimatedOpacity(
      opacity: opacity,
      duration: optimizedDuration,
      curve: optimizedCurve,
      child: child,
    );
  }

  /// Create optimized animated size
  Widget createOptimizedAnimatedSize({
    required Widget child,
    Duration? duration,
    Curve? curve,
    Alignment alignment = Alignment.center,
  }) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return child;
    }

    final optimizedDuration =
        getOptimizedDuration(duration ?? _defaultDuration);
    final optimizedCurve = getOptimizedCurve(curve ?? Curves.easeInOut);

    return AnimatedSize(
      duration: optimizedDuration,
      curve: optimizedCurve,
      alignment: alignment,
      child: child,
    );
  }

  /// Create optimized animated position
  Widget createOptimizedAnimatedPositioned({
    required Widget child,
    Duration? duration,
    Curve? curve,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) {
    if (!_animationsEnabled || _reduceMotionEnabled) {
      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: width,
        height: height,
        child: child,
      );
    }

    final optimizedDuration =
        getOptimizedDuration(duration ?? _defaultDuration);
    final optimizedCurve = getOptimizedCurve(curve ?? Curves.easeInOut);

    return AnimatedPositioned(
      duration: optimizedDuration,
      curve: optimizedCurve,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Get animation statistics
  Map<String, dynamic> getAnimationStats() {
    return {
      'animations_enabled': _animationsEnabled,
      'reduce_motion_enabled': _reduceMotionEnabled,
      'default_duration': _defaultDuration.inMilliseconds,
      'fast_duration': _fastDuration.inMilliseconds,
      'slow_duration': _slowDuration.inMilliseconds,
      'hardware_acceleration': _enableHardwareAcceleration,
      'opacity_animations': _enableOpacityAnimations,
      'transform_animations': _enableTransformAnimations,
      'color_animations': _enableColorAnimations,
    };
  }

  /// Dispose service
  void dispose() {
    try {
      ServiceLogger.info('Animation optimization service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing animation optimization service',
          error: e);
    }
  }
}

/// Transition type enum
enum TransitionType {
  fade,
  scale,
  slide,
  rotation,
}
