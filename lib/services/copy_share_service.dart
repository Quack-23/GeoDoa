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
      debugPrint('Text copied to clipboard (${text.length} chars)');
      return true;
    } catch (e) {
      debugPrint('ERROR: Failed to copy to clipboard: $e');
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
      debugPrint('Text shared (${text.length} chars)');
      return true;
    } catch (e) {
      debugPrint('ERROR: Failed to share text: $e');
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
      debugPrint('File shared: $filePath');
      return true;
    } catch (e) {
      debugPrint('ERROR: Failed to share file: $e');
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

      debugPrint(
          'Locations exported to JSON: ${file.path} (${locations.length} locations)');

      return file.path;
    } catch (e) {
      debugPrint('ERROR: Failed to export locations to JSON: $e');
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

      debugPrint(
          'Prayers exported to JSON: ${file.path} (${prayers.length} prayers)');

      return file.path;
    } catch (e) {
      debugPrint('ERROR: Failed to export prayers to JSON: $e');
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
                            pw.Text('Category: ${location.locationCategory}'),
                            pw.Text(
                                'SubCategory: ${location.locationSubCategory}'),
                            pw.Text('Type: ${location.realSub}'),
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

      debugPrint(
          'Data exported to PDF: ${file.path} (${locations.length} locations, ${prayers.length} prayers)');

      return file.path;
    } catch (e) {
      debugPrint('ERROR: Failed to export to PDF: $e');
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

        debugPrint('Data imported from JSON: ${file.path}');

        return data;
      }

      return null;
    } catch (e) {
      debugPrint('ERROR: Failed to import from JSON: $e');
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
      debugPrint('ERROR: Failed to copy prayer: $e');
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
      debugPrint('ERROR: Failed to share prayer: $e');
      return false;
    }
  }

  /// Copy location info
  static Future<bool> copyLocation(LocationModel location) async {
    try {
      final text = '''
${location.name}

Category: ${location.locationCategory}
SubCategory: ${location.locationSubCategory}
Type: ${location.realSub}
Address: ${location.address ?? 'N/A'}
Coordinates: ${location.latitude}, ${location.longitude}
Radius: ${location.radius}m
''';

      return await copyToClipboard(text, label: 'Location: ${location.name}');
    } catch (e) {
      debugPrint('ERROR: Failed to copy location: $e');
      return false;
    }
  }

  /// Share location
  static Future<bool> shareLocation(LocationModel location) async {
    try {
      final text = '''
${location.name}

Category: ${location.locationCategory}
SubCategory: ${location.locationSubCategory}
Type: ${location.realSub}
Address: ${location.address ?? 'N/A'}
Coordinates: ${location.latitude}, ${location.longitude}
Radius: ${location.radius}m
''';

      return await shareText(text, subject: 'Location: ${location.name}');
    } catch (e) {
      debugPrint('ERROR: Failed to share location: $e');
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
