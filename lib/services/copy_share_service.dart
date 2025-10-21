import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/location_model.dart';
import '../models/prayer_model.dart';
import 'package:flutter/foundation.dart';

/// Service untuk copy, share, export, dan import data
class CopyShareService {
  static final CopyShareService _instance = CopyShareService._internal();
  static CopyShareService get instance => _instance;
  CopyShareService._internal();

  /// Copy text to clipboard
  static Future<bool> copyToClipboard(String text, {String? label}) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ServiceLogger.info('Text copied to clipboard', data: {
        'text_length': text.length,
        'label': label,
      });
      return true;
    } catch (e) {
      ServiceLogger.error('Failed to copy to clipboard', error: e);
      return false;
    }
  }

  /// Share text
  static Future<bool> shareText(String text, {String? subject}) async {
    try {
      await Share.share(
        text,
        subject: subject,
      );
      ServiceLogger.info('Text shared', data: {
        'text_length': text.length,
        'subject': subject,
      });
      return true;
    } catch (e) {
      ServiceLogger.error('Failed to share text', error: e);
      return false;
    }
  }

  /// Share file
  static Future<bool> shareFile(String filePath, {String? text}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
      );
      ServiceLogger.info('File shared', data: {
        'file_path': filePath,
        'text': text,
      });
      return true;
    } catch (e) {
      ServiceLogger.error('Failed to share file', error: e);
      return false;
    }
  }

  /// Export locations to JSON
  static Future<String?> exportLocationsToJson(
      List<LocationModel> locations) async {
    try {
      final data = {
        'export_type': 'locations',
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'locations': locations.map((l) => l.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final fileName =
          'doa_locations_${DateTime.now().millisecondsSinceEpoch}.json';

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      ServiceLogger.info('Locations exported to JSON', data: {
        'file_path': file.path,
        'locations_count': locations.length,
      });

      return file.path;
    } catch (e) {
      ServiceLogger.error('Failed to export locations to JSON', error: e);
      return null;
    }
  }

  /// Export prayers to JSON
  static Future<String?> exportPrayersToJson(List<PrayerModel> prayers) async {
    try {
      final data = {
        'export_type': 'prayers',
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'prayers': prayers.map((p) => p.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final fileName =
          'doa_prayers_${DateTime.now().millisecondsSinceEpoch}.json';

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      ServiceLogger.info('Prayers exported to JSON', data: {
        'file_path': file.path,
        'prayers_count': prayers.length,
      });

      return file.path;
    } catch (e) {
      ServiceLogger.error('Failed to export prayers to JSON', error: e);
      return null;
    }
  }

  /// Export data to PDF
  static Future<String?> exportToPdf({
    required List<LocationModel> locations,
    required List<PrayerModel> prayers,
    String? title,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  title ?? 'Doa Geofencing Data Export',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Export Date: ${DateTime.now().toString()}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Locations section
              pw.Header(
                level: 1,
                child: pw.Text('Locations (${locations.length})'),
              ),
              pw.SizedBox(height: 10),
              ...locations
                  .map((location) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              location.name,
                              style: pw.TextStyle(
                                  fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Type: ${location.type}'),
                            pw.Text('Address: ${location.address ?? 'N/A'}'),
                            pw.Text(
                                'Coordinates: ${location.latitude}, ${location.longitude}'),
                            pw.Text('Radius: ${location.radius}m'),
                            pw.Divider(),
                          ],
                        ),
                      ))
                  .toList(),

              pw.SizedBox(height: 20),

              // Prayers section
              pw.Header(
                level: 1,
                child: pw.Text('Prayers (${prayers.length})'),
              ),
              pw.SizedBox(height: 10),
              ...prayers
                  .map((prayer) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              prayer.title,
                              style: pw.TextStyle(
                                  fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Category: ${prayer.category}'),
                            pw.Text('Location Type: ${prayer.locationType}'),
                            pw.Text('Arabic: ${prayer.arabicText}'),
                            pw.Text('Latin: ${prayer.latinText}'),
                            pw.Text('Indonesian: ${prayer.indonesianText}'),
                            pw.Divider(),
                          ],
                        ),
                      ))
                  .toList(),
            ];
          },
        ),
      );

      final fileName =
          'doa_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      ServiceLogger.info('Data exported to PDF', data: {
        'file_path': file.path,
        'locations_count': locations.length,
        'prayers_count': prayers.length,
      });

      return file.path;
    } catch (e) {
      ServiceLogger.error('Failed to export to PDF', error: e);
      return null;
    }
  }

  /// Import data from JSON file
  static Future<Map<String, dynamic>?> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        ServiceLogger.info('Data imported from JSON', data: {
          'file_path': file.path,
          'export_type': data['export_type'],
          'export_date': data['export_date'],
        });

        return data;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to import from JSON', error: e);
      return null;
    }
  }

  /// Copy prayer text
  static Future<bool> copyPrayer(PrayerModel prayer) async {
    try {
      final text = '''
${prayer.title}

Arabic:
${prayer.arabicText}

Latin:
${prayer.latinText}

Indonesian:
${prayer.indonesianText}

Reference: ${prayer.reference}
''';

      return await copyToClipboard(text, label: 'Prayer: ${prayer.title}');
    } catch (e) {
      ServiceLogger.error('Failed to copy prayer', error: e);
      return false;
    }
  }

  /// Share prayer
  static Future<bool> sharePrayer(PrayerModel prayer) async {
    try {
      final text = '''
${prayer.title}

Arabic:
${prayer.arabicText}

Latin:
${prayer.latinText}

Indonesian:
${prayer.indonesianText}

Reference: ${prayer.reference}
''';

      return await shareText(text, subject: 'Doa: ${prayer.title}');
    } catch (e) {
      ServiceLogger.error('Failed to share prayer', error: e);
      return false;
    }
  }

  /// Copy location info
  static Future<bool> copyLocation(LocationModel location) async {
    try {
      final text = '''
${location.name}

Type: ${location.type}
Address: ${location.address ?? 'N/A'}
Coordinates: ${location.latitude}, ${location.longitude}
Radius: ${location.radius}m
''';

      return await copyToClipboard(text, label: 'Location: ${location.name}');
    } catch (e) {
      ServiceLogger.error('Failed to copy location', error: e);
      return false;
    }
  }

  /// Share location
  static Future<bool> shareLocation(LocationModel location) async {
    try {
      final text = '''
${location.name}

Type: ${location.type}
Address: ${location.address ?? 'N/A'}
Coordinates: ${location.latitude}, ${location.longitude}
Radius: ${location.radius}m
''';

      return await shareText(text, subject: 'Location: ${location.name}');
    } catch (e) {
      ServiceLogger.error('Failed to share location', error: e);
      return false;
    }
  }

  /// Get export statistics
  static Map<String, dynamic> getExportStats() {
    return {
      'supported_formats': ['JSON', 'PDF'],
      'export_types': ['locations', 'prayers', 'combined'],
      'import_formats': ['JSON'],
      'share_options': ['text', 'file'],
    };
  }
}
