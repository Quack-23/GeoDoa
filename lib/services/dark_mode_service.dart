import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service untuk mengelola dark mode dan kontras
class DarkModeService {
  static final DarkModeService _instance = DarkModeService._internal();
  static DarkModeService get instance => _instance;
  DarkModeService._internal();

  // Dark mode settings
  bool _isDarkMode = false;
  bool _isSystemDarkMode = false;
  bool _isHighContrast = false;
  double _contrastRatio = 4.5; // WCAG AA standard

  // Color schemes
  ColorScheme? _lightColorScheme;
  ColorScheme? _darkColorScheme;
  ColorScheme? _highContrastLightScheme;
  ColorScheme? _highContrastDarkScheme;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isSystemDarkMode => _isSystemDarkMode;
  bool get isHighContrast => _isHighContrast;
  double get contrastRatio => _contrastRatio;

  /// Initialize dark mode service
  Future<void> initialize() async {
    try {
      debugPrint('INFO: Initializing dark mode service');

      // Initialize color schemes
      _initializeColorSchemes();

      // Check system dark mode
      await _checkSystemDarkMode();

      debugPrint('INFO: Dark mode service initialized - isDark: $_isDarkMode, isSystem: $_isSystemDarkMode, contrast: $_contrastRatio');
    } catch (e) {
      debugPrint('ERROR: Failed to initialize dark mode service: $e');
    }
  }

  /// Initialize color schemes
  void _initializeColorSchemes() {
    // Light color scheme - Tema Modern dengan Variasi Warna
    _lightColorScheme = const ColorScheme.light(
      primary: Color(0xFF1976D2), // Biru modern untuk primary
      primaryContainer: Color(0xFFE3F2FD), // Biru sangat muda untuk container
      secondary: Color(0xFF2E7D32), // Hijau Islam untuk secondary
      secondaryContainer: Color(0xFFE8F5E8), // Hijau sangat muda
      tertiary: Color(0xFF7B1FA2), // Ungu untuk tertiary
      tertiaryContainer: Color(0xFFF3E5F5), // Ungu sangat muda
      surface: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFF8F9FA), // Abu-abu sangat muda untuk surface
      background: Color(0xFFFFFFFF),
      error: Color(0xFFD32F2F),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onTertiary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A1A), // Hitam untuk teks
      onBackground: Color(0xFF1A1A1A), // Hitam untuk background
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFE0E0E0), // Abu-abu untuk outline
      shadow: Color(0xFF000000), // Hitam untuk shadow
    );

    // Dark color scheme - Tema Hijau Gelap yang Elegan
    _darkColorScheme = const ColorScheme.dark(
      primary: Color(0xFF4CAF50), // Hijau terang untuk dark mode
      primaryContainer: Color(0xFF1B5E20), // Hijau gelap untuk container
      secondary: Color(0xFF66BB6A), // Hijau sekunder terang
      secondaryContainer:
          Color(0xFF2E7D32), // Hijau gelap untuk secondary container
      surface: Color(0xFF1A1A1A), // Surface gelap dengan sedikit hijau
      surfaceContainer:
          Color(0xFF2A2A2A), // Surface container yang lebih terang
      background: Color(0xFF0F0F0F), // Background hitam pekat
      error: Color(0xFFEF5350),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF81C784), // Hijau terang untuk teks di surface
      onBackground: Color(0xFF81C784), // Hijau terang untuk teks di background
      onError: Color(0xFF000000),
      outline: Color(0xFF4CAF50), // Hijau untuk outline
      shadow: Color(0xFF4CAF50), // Hijau untuk shadow
    );

    // High contrast light scheme - Hijau Kontras Tinggi
    _highContrastLightScheme = const ColorScheme.light(
      primary: Color(0xFF1B5E20), // Hijau gelap untuk kontras tinggi
      primaryContainer: Color(0xFF2E7D32),
      secondary: Color(0xFF4CAF50),
      secondaryContainer: Color(0xFF66BB6A),
      surface: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFF1F8E9),
      background: Color(0xFFFFFFFF),
      error: Color(0xFFD32F2F),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1B5E20), // Hijau gelap untuk teks
      onBackground: Color(0xFF1B5E20),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFF1B5E20), // Hijau gelap untuk outline
      shadow: Color(0xFF1B5E20),
    );

    // High contrast dark scheme - Hijau Kontras Tinggi Gelap
    _highContrastDarkScheme = const ColorScheme.dark(
      primary: Color(0xFF4CAF50), // Hijau terang untuk kontras tinggi
      primaryContainer: Color(0xFF66BB6A),
      secondary: Color(0xFF81C784),
      secondaryContainer: Color(0xFFA5D6A7),
      surface: Color(0xFF000000),
      surfaceContainer: Color(0xFF1A1A1A),
      background: Color(0xFF000000),
      error: Color(0xFFFF5252),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF81C784), // Hijau terang untuk teks
      onBackground: Color(0xFF81C784),
      onError: Color(0xFF000000),
      outline: Color(0xFF4CAF50), // Hijau terang untuk outline
      shadow: Color(0xFF4CAF50),
    );
  }

  /// Check system dark mode
  Future<void> _checkSystemDarkMode() async {
    try {
      // Mock implementation - in real app, use system theme
      _isSystemDarkMode = false; // Mock value
      _isDarkMode = _isSystemDarkMode;

      debugPrint('DEBUG: System dark mode checked');
    } catch (e) {
      debugPrint('ERROR: Error checking system dark mode: $e');
    }
  }

  /// Set dark mode
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    debugPrint('INFO: Dark mode ${isDark ? 'enabled' : 'disabled'}');
  }

  /// Set system dark mode
  void setSystemDarkMode(bool isSystemDark) {
    _isSystemDarkMode = isSystemDark;
    if (_isSystemDarkMode) {
      _isDarkMode = _isSystemDarkMode;
    }
    debugPrint('INFO: System dark mode ${isSystemDark ? 'enabled' : 'disabled'}');
  }

  /// Set high contrast mode
  void setHighContrast(bool isHighContrast) {
    _isHighContrast = isHighContrast;
    debugPrint('INFO: High contrast mode ${isHighContrast ? 'enabled' : 'disabled'}');
  }

  /// Set contrast ratio
  void setContrastRatio(double ratio) {
    _contrastRatio = ratio.clamp(1.0, 21.0);
    debugPrint('INFO: Contrast ratio set to $_contrastRatio');
  }

  /// Get current color scheme
  ColorScheme getCurrentColorScheme() {
    if (_isHighContrast) {
      return _isDarkMode ? _highContrastDarkScheme! : _highContrastLightScheme!;
    }
    return _isDarkMode ? _darkColorScheme! : _lightColorScheme!;
  }

  /// Get accessible color
  Color getAccessibleColor(Color baseColor, {Color? backgroundColor}) {
    final bgColor = backgroundColor ?? getCurrentColorScheme().background;

    if (!_isHighContrast) return baseColor;

    // Calculate contrast ratio
    final contrast = _calculateContrastRatio(baseColor, bgColor);
    if (contrast >= _contrastRatio) return baseColor;

    // Return high contrast version
    return _getHighContrastColor(baseColor, bgColor);
  }

  /// Calculate contrast ratio
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

  /// Get theme data
  ThemeData getThemeData() {
    final colorScheme = getCurrentColorScheme();

    return ThemeData(
      colorScheme: colorScheme,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: _isDarkMode ? 0 : 4,
        shadowColor: colorScheme.shadow,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shadowColor: colorScheme.shadow,
        elevation: _isDarkMode ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: _isDarkMode ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.outline.withOpacity(0.3);
        }),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }

  /// Get dark mode statistics
  Map<String, dynamic> getDarkModeStats() {
    return {
      'is_dark_mode': _isDarkMode,
      'is_system_dark_mode': _isSystemDarkMode,
      'is_high_contrast': _isHighContrast,
      'contrast_ratio': _contrastRatio,
      'current_brightness': _isDarkMode ? 'dark' : 'light',
    };
  }

  /// Dispose service
  void dispose() {
    try {
      debugPrint('INFO: Dark mode service disposed');
    } catch (e) {
      debugPrint('ERROR: Error disposing dark mode service: $e');
    }
  }
}
