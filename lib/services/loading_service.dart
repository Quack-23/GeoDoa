import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// Service untuk mengelola loading states secara konsisten
class LoadingService extends ChangeNotifier {
  static final LoadingService _instance = LoadingService._internal();
  static LoadingService get instance => _instance;
  LoadingService._internal();

  final Map<String, bool> _loadingStates = {};
  final Map<String, String> _loadingMessages = {};
  final Map<String, double> _loadingProgress = {};

  /// Cek apakah ada loading state aktif
  bool get isLoading => _loadingStates.values.any((loading) => loading);

  /// Cek loading state untuk key tertentu
  bool isLoadingForKey(String key) => _loadingStates[key] ?? false;

  /// Dapatkan loading message untuk key tertentu
  String getLoadingMessage(String key) => _loadingMessages[key] ?? 'Memuat...';

  /// Dapatkan loading progress untuk key tertentu
  double getLoadingProgress(String key) => _loadingProgress[key] ?? 0.0;

  /// Dapatkan semua loading states
  Map<String, bool> get allLoadingStates => Map.unmodifiable(_loadingStates);

  /// Mulai loading state
  void startLoading(String key, {String? message, double? progress}) {
    _loadingStates[key] = true;
    _loadingMessages[key] = message ?? 'Memuat...';
    _loadingProgress[key] = progress ?? 0.0;

    debugPrint('DEBUG: Started loading: $key - message: $message, progress: $progress');

    notifyListeners();
  }

  /// Update loading message
  void updateLoadingMessage(String key, String message) {
    if (_loadingStates[key] == true) {
      _loadingMessages[key] = message;
      debugPrint('DEBUG: Updated loading message: $key - $message');
      notifyListeners();
    }
  }

  /// Update loading progress
  void updateLoadingProgress(String key, double progress) {
    if (_loadingStates[key] == true) {
      _loadingProgress[key] = progress.clamp(0.0, 1.0);
      debugPrint('DEBUG: Updated loading progress: $key - $progress');
      notifyListeners();
    }
  }

  /// Selesai loading state
  void stopLoading(String key) {
    _loadingStates[key] = false;
    _loadingMessages.remove(key);
    _loadingProgress.remove(key);

    debugPrint('DEBUG: Stopped loading: $key');
    notifyListeners();
  }

  /// Selesai semua loading states
  void stopAllLoading() {
    _loadingStates.clear();
    _loadingMessages.clear();
    _loadingProgress.clear();

    debugPrint('DEBUG: Stopped all loading states');
    notifyListeners();
  }

  /// Loading untuk operasi database
  void startDatabaseLoading(String operation) {
    startLoading('database_$operation', message: 'Mengakses database...');
  }

  void stopDatabaseLoading(String operation) {
    stopLoading('database_$operation');
  }

  /// Loading untuk operasi API
  void startApiLoading(String operation) {
    startLoading('api_$operation', message: 'Memuat data dari server...');
  }

  void stopApiLoading(String operation) {
    stopLoading('api_$operation');
  }

  /// Loading untuk operasi lokasi
  void startLocationLoading(String operation) {
    startLoading('location_$operation', message: 'Mendeteksi lokasi...');
  }

  void stopLocationLoading(String operation) {
    stopLoading('location_$operation');
  }

  /// Loading untuk operasi notifikasi
  void startNotificationLoading(String operation) {
    startLoading('notification_$operation', message: 'Mengirim notifikasi...');
  }

  void stopNotificationLoading(String operation) {
    stopLoading('notification_$operation');
  }

  /// Loading untuk operasi enkripsi
  void startEncryptionLoading(String operation) {
    startLoading('encryption_$operation', message: 'Memproses data...');
  }

  void stopEncryptionLoading(String operation) {
    stopLoading('encryption_$operation');
  }

  /// Loading untuk operasi scan lokasi
  void startScanLoading() {
    startLoading('scan_locations', message: 'Memindai lokasi di sekitar...');
  }

  void updateScanProgress(double progress) {
    updateLoadingProgress('scan_locations', progress);
  }

  void stopScanLoading() {
    stopLoading('scan_locations');
  }

  /// Loading untuk operasi save data
  void startSaveLoading(String dataType) {
    startLoading('save_$dataType', message: 'Menyimpan data...');
  }

  void stopSaveLoading(String dataType) {
    stopLoading('save_$dataType');
  }

  /// Loading untuk operasi load data
  void startLoadLoading(String dataType) {
    startLoading('load_$dataType', message: 'Memuat data...');
  }

  void stopLoadLoading(String dataType) {
    stopLoading('load_$dataType');
  }
}

/// Widget untuk menampilkan loading indicator
class LoadingWidget extends StatelessWidget {
  final String? loadingKey;
  final String? message;
  final double? progress;
  final Color? color;
  final double size;

  const LoadingWidget({
    super.key,
    this.loadingKey,
    this.message,
    this.progress,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingService>(
      builder: (context, loadingService, child) {
        final isLoading = loadingKey != null
            ? loadingService.isLoadingForKey(loadingKey!)
            : loadingService.isLoading;

        final loadingMessage = loadingKey != null
            ? loadingService.getLoadingMessage(loadingKey!)
            : message ?? 'Memuat...';

        final loadingProgress = loadingKey != null
            ? loadingService.getLoadingProgress(loadingKey!)
            : progress ?? 0.0;

        if (!isLoading) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loadingProgress > 0.0) ...[
                CircularProgressIndicator(
                  value: loadingProgress,
                  color: color ?? Theme.of(context).primaryColor,
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Text(
                  '${(loadingProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    color: color ?? Theme.of(context).primaryColor,
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.spacingSmall),
              Text(
                loadingMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget untuk menampilkan loading overlay
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final String? loadingKey;
  final String? message;
  final Color? backgroundColor;
  final bool dismissible;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.loadingKey,
    this.message,
    this.backgroundColor,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingService>(
      builder: (context, loadingService, child) {
        final isLoading = loadingKey != null
            ? loadingService.isLoadingForKey(loadingKey!)
            : loadingService.isLoading;

        final loadingMessage = loadingKey != null
            ? loadingService.getLoadingMessage(loadingKey!)
            : message ?? 'Memuat...';

        return Stack(
          children: [
            this.child,
            if (isLoading)
              Container(
                color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingLarge),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppConstants.spacingMedium),
                        Text(
                          loadingMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Extension untuk memudahkan penggunaan loading service
extension LoadingExtension on BuildContext {
  /// Tampilkan loading dialog
  void showLoadingDialog(String message) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Tutup loading dialog
  void hideLoadingDialog() {
    Navigator.of(this).pop();
  }
}
