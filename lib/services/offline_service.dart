import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import '../services/logging_service.dart';
import '../utils/error_handler.dart';

/// Service untuk mendeteksi status koneksi internet
class OfflineService extends ChangeNotifier {
  static final OfflineService _instance = OfflineService._internal();
  static OfflineService get instance => _instance;
  OfflineService._internal();

  bool _isOffline = false;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  /// Status offline
  bool get isOffline => _isOffline;

  /// Status online
  bool get isOnline => !_isOffline;

  /// Status koneksi
  ConnectivityResult get connectionStatus => _connectionStatus;

  /// Jumlah percobaan reconnect
  int get reconnectAttempts => _reconnectAttempts;

  /// Initialize offline service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing offline service');

      // Cek status koneksi awal
      await _checkConnectivity();

      // Listen perubahan koneksi
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          ServiceLogger.error('Connectivity stream error', error: error);
        },
      );

      ServiceLogger.info('Offline service initialized successfully');
    } catch (e) {
      ServiceLogger.error('Failed to initialize offline service', error: e);
      throw AppError(
        'Gagal menginisialisasi offline service',
        code: 'OFFLINE_SERVICE_INIT_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Dispose service
  void dispose() {
    _connectivitySubscription?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  /// Cek status koneksi
  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      await _onConnectivityChanged(result);
    } catch (e) {
      ServiceLogger.error('Failed to check connectivity', error: e);
      _setOfflineStatus(true);
    }
  }

  /// Handle perubahan koneksi
  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    try {
      _connectionStatus = result;

      if (result == ConnectivityResult.none) {
        _setOfflineStatus(true);
        ServiceLogger.warning('Device is offline');
      } else {
        // Cek apakah benar-benar bisa connect ke internet
        final hasInternet = await _hasInternetConnection();

        if (hasInternet) {
          _setOfflineStatus(false);
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
          ServiceLogger.info('Device is online');
        } else {
          _setOfflineStatus(true);
          ServiceLogger.warning('Device has connection but no internet access');
        }
      }
    } catch (e) {
      ServiceLogger.error('Failed to handle connectivity change', error: e);
      _setOfflineStatus(true);
    }
  }

  /// Cek apakah benar-benar ada koneksi internet
  Future<bool> _hasInternetConnection() async {
    try {
      // Coba ping ke beberapa server
      final hosts = [
        'google.com',
        'cloudflare.com',
        '1.1.1.1',
      ];

      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (e) {
          // Continue to next host
        }
      }

      return false;
    } catch (e) {
      ServiceLogger.error('Failed to check internet connection', error: e);
      return false;
    }
  }

  /// Set status offline
  void _setOfflineStatus(bool isOffline) {
    if (_isOffline != isOffline) {
      _isOffline = isOffline;
      ServiceLogger.info('Offline status changed: $isOffline');
      notifyListeners();
    }
  }

  /// Coba reconnect
  Future<void> tryReconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      ServiceLogger.warning('Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    ServiceLogger.info(
        'Attempting to reconnect (attempt $_reconnectAttempts/$maxReconnectAttempts)');

    try {
      await _checkConnectivity();

      if (!_isOffline) {
        ServiceLogger.info('Reconnected successfully');
        return;
      }

      // Schedule next reconnect attempt
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(
        Duration(seconds: _reconnectAttempts * 2), // Exponential backoff
        () => tryReconnect(),
      );
    } catch (e) {
      ServiceLogger.error('Reconnect attempt failed', error: e);
    }
  }

  /// Reset reconnect attempts
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
  }

  /// Cek apakah operasi bisa dilakukan
  bool canPerformOperation(String operation) {
    switch (operation) {
      case 'api_call':
      case 'location_scan':
      case 'data_sync':
        return isOnline;
      case 'database_read':
      case 'database_write':
      case 'local_notification':
        return true; // Bisa dilakukan offline
      default:
        return isOnline;
    }
  }

  /// Dapatkan pesan offline untuk operasi tertentu
  String getOfflineMessage(String operation) {
    switch (operation) {
      case 'api_call':
        return 'Tidak ada koneksi internet. Beberapa fitur tidak tersedia.';
      case 'location_scan':
        return 'Tidak ada koneksi internet. Scan lokasi tidak tersedia.';
      case 'data_sync':
        return 'Tidak ada koneksi internet. Data akan disinkronkan saat online.';
      case 'notification':
        return 'Tidak ada koneksi internet. Notifikasi mungkin tertunda.';
      default:
        return 'Tidak ada koneksi internet.';
    }
  }

  /// Dapatkan pesan online
  String getOnlineMessage() {
    return 'Koneksi internet tersedia.';
  }
}

/// Widget untuk menampilkan status offline
class OfflineIndicator extends StatelessWidget {
  final String? operation;
  final Widget? child;
  final bool showWhenOnline;

  const OfflineIndicator({
    super.key,
    this.operation,
    this.child,
    this.showWhenOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        final isOffline = offlineService.isOffline;
        final canPerform = operation != null
            ? offlineService.canPerformOperation(operation!)
            : true;

        if (isOffline && !canPerform) {
          return _buildOfflineMessage(context, offlineService);
        }

        if (!isOffline && showWhenOnline) {
          return _buildOnlineMessage(context, offlineService);
        }

        return this.child ?? const SizedBox.shrink();
      },
    );
  }

  Widget _buildOfflineMessage(
      BuildContext context, OfflineService offlineService) {
    final message = operation != null
        ? offlineService.getOfflineMessage(operation!)
        : 'Tidak ada koneksi internet';

    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingSmall),
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      decoration: BoxDecoration(
        color: const Color(AppConstants.warningColorValue),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tidak Ada Internet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppConstants.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppConstants.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSmall),
          ElevatedButton.icon(
            onPressed: () => offlineService.tryReconnect(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(AppConstants.warningColorValue),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineMessage(
      BuildContext context, OfflineService offlineService) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSmall),
      color: const Color(AppConstants.successColorValue),
      child: Row(
        children: [
          const Icon(
            Icons.wifi,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: AppConstants.spacingSmall),
          Expanded(
            child: Text(
              offlineService.getOnlineMessage(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppConstants.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk menampilkan pesan offline di snackbar
class OfflineSnackBar extends StatelessWidget {
  final String? operation;
  final VoidCallback? onRetry;

  const OfflineSnackBar({
    super.key,
    this.operation,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        if (offlineService.isOffline) {
          final message = operation != null
              ? offlineService.getOfflineMessage(operation!)
              : 'Tidak ada koneksi internet';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white),
                    const SizedBox(width: AppConstants.spacingSmall),
                    Expanded(child: Text(message)),
                  ],
                ),
                backgroundColor: const Color(AppConstants.warningColorValue),
                duration: const Duration(seconds: 5),
                action: onRetry != null
                    ? SnackBarAction(
                        label: 'Coba Lagi',
                        textColor: Colors.white,
                        onPressed: onRetry!,
                      )
                    : null,
              ),
            );
          });
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Extension untuk memudahkan penggunaan offline service
extension OfflineExtension on BuildContext {
  /// Tampilkan pesan offline
  void showOfflineMessage(String operation) {
    final offlineService = OfflineService.instance;
    final message = offlineService.getOfflineMessage(operation);

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: AppConstants.spacingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(AppConstants.warningColorValue),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Coba Lagi',
          textColor: Colors.white,
          onPressed: () => offlineService.tryReconnect(),
        ),
      ),
    );
  }

  /// Tampilkan pesan online
  void showOnlineMessage() {
    final offlineService = OfflineService.instance;
    final message = offlineService.getOnlineMessage();

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white),
            const SizedBox(width: AppConstants.spacingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(AppConstants.successColorValue),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
