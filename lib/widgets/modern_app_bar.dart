import 'package:flutter/material.dart';

/// Modern gradient app bar widget that's reusable across screens
///
/// Features:
/// - Gradient background dengan dark mode support
/// - Icon dengan background
/// - Title & subtitle
/// - Optional back button
/// - Consistent styling
class ModernAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? gradientStartColor;
  final Color? gradientEndColor;

  const ModernAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.showBackButton = false,
    this.onBackPressed,
    this.gradientStartColor,
    this.gradientEndColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default gradient colors
    final startColor = gradientStartColor ??
        (isDark
            ? const Color(0xFF1B5E20)
            : Theme.of(context).colorScheme.primary);
    final endColor = gradientEndColor ??
        (isDark
            ? const Color(0xFF2E7D32).withOpacity(0.8)
            : Theme.of(context).colorScheme.primary.withOpacity(0.8));

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (optional)
          if (showBackButton) ...[
            IconButton(
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],

          // Icon container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
