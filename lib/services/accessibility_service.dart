import 'package:flutter/material.dart';
import 'dart:math';
import '../services/logging_service.dart';

/// Service untuk mendukung accessibility (screen readers, dll)
class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  static AccessibilityService get instance => _instance;
  AccessibilityService._internal();

  // Accessibility settings
  bool _isAccessibilityEnabled = false;
  bool _isScreenReaderEnabled = false;
  bool _isHighContrastEnabled = false;
  bool _isLargeTextEnabled = false;
  bool _isReduceMotionEnabled = false;

  // Text scaling
  double _textScaleFactor = 1.0;
  double _minTextScaleFactor = 0.8;
  double _maxTextScaleFactor = 2.0;

  // Color contrast
  double _contrastRatio = 4.5; // WCAG AA standard
  bool _isHighContrastMode = false;

  // Focus management
  FocusNode? _currentFocus;
  List<FocusNode> _focusNodes = [];

  // Getters
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  bool get isLargeTextEnabled => _isLargeTextEnabled;
  bool get isReduceMotionEnabled => _isReduceMotionEnabled;
  double get textScaleFactor => _textScaleFactor;
  double get contrastRatio => _contrastRatio;
  bool get isHighContrastMode => _isHighContrastMode;

  /// Initialize accessibility service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing accessibility service');

      // Check system accessibility settings
      await _checkSystemAccessibilitySettings();

      // Setup accessibility listeners
      _setupAccessibilityListeners();

      ServiceLogger.info('Accessibility service initialized', data: {
        'is_enabled': _isAccessibilityEnabled,
        'screen_reader': _isScreenReaderEnabled,
        'high_contrast': _isHighContrastEnabled,
        'large_text': _isLargeTextEnabled,
        'reduce_motion': _isReduceMotionEnabled,
      });
    } catch (e) {
      ServiceLogger.error('Failed to initialize accessibility service',
          error: e);
    }
  }

  /// Check system accessibility settings
  Future<void> _checkSystemAccessibilitySettings() async {
    try {
      // Mock implementation - in real app, use accessibility_plus package
      _isAccessibilityEnabled = true;
      _isScreenReaderEnabled = false; // Mock value
      _isHighContrastEnabled = false; // Mock value
      _isLargeTextEnabled = false; // Mock value
      _isReduceMotionEnabled = false; // Mock value

      ServiceLogger.debug('System accessibility settings checked');
    } catch (e) {
      ServiceLogger.error('Error checking system accessibility settings',
          error: e);
    }
  }

  /// Setup accessibility listeners
  void _setupAccessibilityListeners() {
    try {
      // Listen for text scale changes
      // In real app, use MediaQuery.of(context).textScaleFactor

      ServiceLogger.debug('Accessibility listeners setup');
    } catch (e) {
      ServiceLogger.error('Error setting up accessibility listeners', error: e);
    }
  }

  /// Enable/disable accessibility
  void setAccessibilityEnabled(bool enabled) {
    _isAccessibilityEnabled = enabled;
    ServiceLogger.info('Accessibility ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable screen reader support
  void setScreenReaderEnabled(bool enabled) {
    _isScreenReaderEnabled = enabled;
    ServiceLogger.info(
        'Screen reader support ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable high contrast mode
  void setHighContrastEnabled(bool enabled) {
    _isHighContrastEnabled = enabled;
    _isHighContrastMode = enabled;
    ServiceLogger.info(
        'High contrast mode ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable large text support
  void setLargeTextEnabled(bool enabled) {
    _isLargeTextEnabled = enabled;
    ServiceLogger.info(
        'Large text support ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable reduce motion
  void setReduceMotionEnabled(bool enabled) {
    _isReduceMotionEnabled = enabled;
    ServiceLogger.info('Reduce motion ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set text scale factor
  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(_minTextScaleFactor, _maxTextScaleFactor);
    ServiceLogger.info('Text scale factor set to $_textScaleFactor');
  }

  /// Set contrast ratio
  void setContrastRatio(double ratio) {
    _contrastRatio = ratio.clamp(1.0, 21.0);
    ServiceLogger.info('Contrast ratio set to $_contrastRatio');
  }

  /// Get accessible colors
  Color getAccessibleColor(Color baseColor, Color backgroundColor) {
    if (!_isHighContrastMode) return baseColor;

    // Calculate contrast ratio and adjust if needed
    final contrast = _calculateContrastRatio(baseColor, backgroundColor);
    if (contrast >= _contrastRatio) return baseColor;

    // Return high contrast version
    return _getHighContrastColor(baseColor, backgroundColor);
  }

  /// Calculate contrast ratio between two colors
  double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _getLuminance(color1);
    final luminance2 = _getLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Get luminance of a color
  double _getLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final rsRGB = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
    final gsRGB = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
    final bsRGB = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * rsRGB + 0.7152 * gsRGB + 0.0722 * bsRGB;
  }

  /// Get high contrast color
  Color _getHighContrastColor(Color baseColor, Color backgroundColor) {
    final baseLuminance = _getLuminance(baseColor);
    final backgroundLuminance = _getLuminance(backgroundColor);

    // Return black or white based on background
    return backgroundLuminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Create accessible button
  Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? semanticHint,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: excludeSemantics,
      child: ElevatedButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }

  /// Create accessible text
  Widget createAccessibleText(
    String text, {
    TextStyle? style,
    String? semanticLabel,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      excludeSemantics: excludeSemantics,
      child: Text(
        text,
        style: style,
      ),
    );
  }

  /// Create accessible icon
  Widget createAccessibleIcon(
    IconData icon, {
    double? size,
    Color? color,
    String? semanticLabel,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: excludeSemantics,
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }

  /// Create accessible card
  Widget createAccessibleCard({
    required Widget child,
    String? semanticLabel,
    String? semanticHint,
    bool excludeSemantics = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      enabled: onTap != null,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: Card(
        child: child,
      ),
    );
  }

  /// Create accessible list tile
  Widget createAccessibleListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    String? semanticLabel,
    String? semanticHint,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel ?? title,
      hint: semanticHint ?? subtitle,
      button: onTap != null,
      enabled: onTap != null,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Create accessible dialog
  Widget createAccessibleDialog({
    required String title,
    required Widget content,
    List<Widget>? actions,
    String? semanticLabel,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel ?? title,
      excludeSemantics: excludeSemantics,
      child: AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
      ),
    );
  }

  /// Create accessible snackbar
  void showAccessibleSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: message,
          child: Text(message),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
              )
            : null,
        duration: duration,
      ),
    );
  }

  /// Create accessible tooltip
  Widget createAccessibleTooltip({
    required String message,
    required Widget child,
    String? semanticLabel,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel ?? message,
      excludeSemantics: excludeSemantics,
      child: Tooltip(
        message: message,
        child: child,
      ),
    );
  }

  /// Create accessible focus node
  FocusNode createFocusNode() {
    final focusNode = FocusNode();
    _focusNodes.add(focusNode);
    return focusNode;
  }

  /// Dispose focus node
  void disposeFocusNode(FocusNode focusNode) {
    _focusNodes.remove(focusNode);
    focusNode.dispose();
  }

  /// Set focus to next element
  void focusNext() {
    if (_focusNodes.isEmpty) return;

    final currentIndex =
        _focusNodes.indexOf(_currentFocus ?? _focusNodes.first);
    final nextIndex = (currentIndex + 1) % _focusNodes.length;

    _currentFocus = _focusNodes[nextIndex];
    _currentFocus?.requestFocus();
  }

  /// Set focus to previous element
  void focusPrevious() {
    if (_focusNodes.isEmpty) return;

    final currentIndex =
        _focusNodes.indexOf(_currentFocus ?? _focusNodes.first);
    final previousIndex =
        currentIndex == 0 ? _focusNodes.length - 1 : currentIndex - 1;

    _currentFocus = _focusNodes[previousIndex];
    _currentFocus?.requestFocus();
  }

  /// Get accessibility statistics
  Map<String, dynamic> getAccessibilityStats() {
    return {
      'is_enabled': _isAccessibilityEnabled,
      'screen_reader': _isScreenReaderEnabled,
      'high_contrast': _isHighContrastEnabled,
      'large_text': _isLargeTextEnabled,
      'reduce_motion': _isReduceMotionEnabled,
      'text_scale_factor': _textScaleFactor,
      'contrast_ratio': _contrastRatio,
      'focus_nodes_count': _focusNodes.length,
      'current_focus': _currentFocus != null,
    };
  }

  /// Dispose service
  void dispose() {
    try {
      for (final focusNode in _focusNodes) {
        focusNode.dispose();
      }
      _focusNodes.clear();
      _currentFocus = null;

      ServiceLogger.info('Accessibility service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing accessibility service', error: e);
    }
  }
}
