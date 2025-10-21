import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';
import '../services/copy_share_service.dart';
import '../services/logging_service.dart';
import '../utils/error_handler.dart';

/// Widget untuk copy dan share functionality
class CopyShareWidgets {
  /// Show copy/share options dialog
  static Future<void> showCopyShareDialog({
    required BuildContext context,
    PrayerModel? prayer,
    LocationModel? location,
    String? customText,
  }) async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => CopyShareBottomSheet(
          prayer: prayer,
          location: location,
          customText: customText,
        ),
      );
    } catch (e) {
      ServiceLogger.error('Failed to show copy/share dialog', error: e);
      ErrorHandler.handleError(context, e);
    }
  }

  /// Copy button widget
  static Widget copyButton({
    required String text,
    String? label,
    VoidCallback? onCopied,
  }) {
    return IconButton(
      icon: const Icon(Icons.copy),
      tooltip: 'Copy to clipboard',
      onPressed: () async {
        try {
          final success =
              await CopyShareService.copyToClipboard(text, label: label);
          if (success && onCopied != null) {
            onCopied();
          }
        } catch (e) {
          ServiceLogger.error('Failed to copy text', error: e);
        }
      },
    );
  }

  /// Share button widget
  static Widget shareButton({
    required String text,
    String? subject,
    VoidCallback? onShared,
  }) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share',
      onPressed: () async {
        try {
          final success =
              await CopyShareService.shareText(text, subject: subject);
          if (success && onShared != null) {
            onShared();
          }
        } catch (e) {
          ServiceLogger.error('Failed to share text', error: e);
        }
      },
    );
  }

  /// Prayer copy/share buttons
  static Widget prayerCopyShareButtons({
    required PrayerModel prayer,
    VoidCallback? onCopied,
    VoidCallback? onShared,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        copyButton(
          text: _buildPrayerText(prayer),
          label: 'Prayer: ${prayer.title}',
          onCopied: onCopied,
        ),
        shareButton(
          text: _buildPrayerText(prayer),
          subject: 'Doa: ${prayer.title}',
          onShared: onShared,
        ),
      ],
    );
  }

  /// Location copy/share buttons
  static Widget locationCopyShareButtons({
    required LocationModel location,
    VoidCallback? onCopied,
    VoidCallback? onShared,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        copyButton(
          text: _buildLocationText(location),
          label: 'Location: ${location.name}',
          onCopied: onCopied,
        ),
        shareButton(
          text: _buildLocationText(location),
          subject: 'Location: ${location.name}',
          onShared: onShared,
        ),
      ],
    );
  }

  /// Build prayer text for copy/share
  static String _buildPrayerText(PrayerModel prayer) {
    return '''
${prayer.title}

Arabic:
${prayer.arabicText}

Latin:
${prayer.latinText}

Indonesian:
${prayer.indonesianText}

Reference: ${prayer.reference}
''';
  }

  /// Build location text for copy/share
  static String _buildLocationText(LocationModel location) {
    return '''
${location.name}

Type: ${location.type}
Address: ${location.address ?? 'N/A'}
Coordinates: ${location.latitude}, ${location.longitude}
Radius: ${location.radius}m
''';
  }
}

/// Bottom sheet untuk copy/share options
class CopyShareBottomSheet extends StatefulWidget {
  final PrayerModel? prayer;
  final LocationModel? location;
  final String? customText;

  const CopyShareBottomSheet({
    super.key,
    this.prayer,
    this.location,
    this.customText,
  });

  @override
  State<CopyShareBottomSheet> createState() => _CopyShareBottomSheetState();
}

class _CopyShareBottomSheetState extends State<CopyShareBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.copy, color: Colors.blue),
              const SizedBox(width: 10),
              const Text(
                'Copy & Share',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          if (widget.prayer != null) _buildPrayerContent(),
          if (widget.location != null) _buildLocationContent(),
          if (widget.customText != null) _buildCustomContent(),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _shareContent,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Export buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _exportToJson,
                  icon: const Icon(Icons.download),
                  label: const Text('Export JSON'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _exportToPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerContent() {
    final prayer = widget.prayer!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prayer: ${prayer.title}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          prayer.arabicText,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          prayer.latinText,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          prayer.indonesianText,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLocationContent() {
    final location = widget.location!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location: ${location.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text('Type: ${location.type}'),
        Text('Address: ${location.address ?? 'N/A'}'),
        Text('Coordinates: ${location.latitude}, ${location.longitude}'),
        Text('Radius: ${location.radius}m'),
      ],
    );
  }

  Widget _buildCustomContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Text',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.customText!,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard() async {
    setState(() => _isLoading = true);

    try {
      String text = '';
      String label = '';

      if (widget.prayer != null) {
        text = CopyShareWidgets._buildPrayerText(widget.prayer!);
        label = 'Prayer: ${widget.prayer!.title}';
      } else if (widget.location != null) {
        text = CopyShareWidgets._buildLocationText(widget.location!);
        label = 'Location: ${widget.location!.name}';
      } else if (widget.customText != null) {
        text = widget.customText!;
        label = 'Custom Text';
      }

      final success =
          await CopyShareService.copyToClipboard(text, label: label);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard!')),
          );
        }
      }
    } catch (e) {
      ServiceLogger.error('Failed to copy to clipboard', error: e);
      if (mounted) {
        ErrorHandler.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareContent() async {
    setState(() => _isLoading = true);

    try {
      String text = '';
      String subject = '';

      if (widget.prayer != null) {
        text = CopyShareWidgets._buildPrayerText(widget.prayer!);
        subject = 'Doa: ${widget.prayer!.title}';
      } else if (widget.location != null) {
        text = CopyShareWidgets._buildLocationText(widget.location!);
        subject = 'Location: ${widget.location!.name}';
      } else if (widget.customText != null) {
        text = widget.customText!;
        subject = 'Custom Text';
      }

      await CopyShareService.shareText(text, subject: subject);
    } catch (e) {
      ServiceLogger.error('Failed to share content', error: e);
      if (mounted) {
        ErrorHandler.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportToJson() async {
    setState(() => _isLoading = true);

    try {
      // This would need to be implemented based on what data to export
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export to JSON - Coming soon!')),
        );
      }
    } catch (e) {
      ServiceLogger.error('Failed to export to JSON', error: e);
      if (mounted) {
        ErrorHandler.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportToPdf() async {
    setState(() => _isLoading = true);

    try {
      // This would need to be implemented based on what data to export
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export to PDF - Coming soon!')),
        );
      }
    } catch (e) {
      ServiceLogger.error('Failed to export to PDF', error: e);
      if (mounted) {
        ErrorHandler.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
