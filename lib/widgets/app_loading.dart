import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  final String? message;
  final bool fullscreen;
  final VoidCallback? onDismiss;

  const AppLoading(
      {super.key, this.message, this.fullscreen = true, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spinnerColor = isDark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    final loaderContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.95),
                Theme.of(context).colorScheme.secondary.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              ),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        if (onDismiss != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onDismiss,
            child: Text('Batal',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ]
      ],
    );

    if (!fullscreen) return loaderContent;

    // Fullscreen modal-like draggable sheet
    return GestureDetector(
      onTap: () {}, // absorb taps
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Dismissible(
            key: const Key('app_loading_dismissible'),
            direction: DismissDirection.down,
            onDismissed: (_) {
              if (onDismiss != null) onDismiss!();
            },
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: loaderContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
