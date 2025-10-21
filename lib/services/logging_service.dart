import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Log levels untuk aplikasi
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Service untuk logging yang proper menggantikan debugPrint
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static LoggingService get instance => _instance;
  LoggingService._internal();

  final List<LogEntry> _logEntries = [];
  static const int maxLogEntries = 1000;

  /// Log debug message
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log info message
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log warning message
  static void warning(String message,
      {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log error message
  static void error(String message,
      {String? tag, Map<String, dynamic>? data, dynamic error}) {
    _log(LogLevel.error, message, tag: tag, data: data, error: error);
  }

  /// Log critical message
  static void critical(String message,
      {String? tag, Map<String, dynamic>? data, dynamic error}) {
    _log(LogLevel.critical, message, tag: tag, data: data, error: error);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    dynamic error,
  }) {
    final logTag = tag ?? AppConstants.logTag;
    final logEntry = LogEntry(
      level: level,
      message: message,
      tag: logTag,
      data: data,
      error: error,
      timestamp: DateTime.now(),
    );

    // Add to log entries
    instance._addLogEntry(logEntry);

    // Print to console based on level and settings
    if (_shouldLog(level)) {
      _printLog(logEntry);
    }

    // Log to developer console in debug mode
    if (kDebugMode) {
      developer.log(
        message,
        name: logTag,
        level: _getLogLevelValue(level),
        error: error,
        time: logEntry.timestamp,
      );
    }
  }

  /// Add log entry to internal storage
  void _addLogEntry(LogEntry entry) {
    _logEntries.add(entry);

    // Remove old entries if we exceed max
    if (_logEntries.length > maxLogEntries) {
      _logEntries.removeAt(0);
    }
  }

  /// Check if we should log this level
  static bool _shouldLog(LogLevel level) {
    if (!AppConstants.enableDebugLogs) return false;

    switch (level) {
      case LogLevel.debug:
        return AppConstants.enableDebugLogs;
      case LogLevel.info:
        return true;
      case LogLevel.warning:
        return true;
      case LogLevel.error:
        return true;
      case LogLevel.critical:
        return true;
    }
  }

  /// Print log to console
  static void _printLog(LogEntry entry) {
    final levelIcon = _getLevelIcon(entry.level);
    final timestamp = _formatTimestamp(entry.timestamp);
    final tag = entry.tag;
    final message = entry.message;

    String logMessage = '$levelIcon [$timestamp] [$tag] $message';

    if (entry.data != null && entry.data!.isNotEmpty) {
      logMessage += '\nData: ${entry.data}';
    }

    if (entry.error != null) {
      logMessage += '\nError: ${entry.error}';
    }

    debugPrint(logMessage);
  }

  /// Get icon for log level
  static String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }

  /// Format timestamp
  static String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Get log level value for developer.log
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }

  /// Get all log entries
  List<LogEntry> getLogEntries() => List.unmodifiable(_logEntries);

  /// Get log entries by level
  List<LogEntry> getLogEntriesByLevel(LogLevel level) {
    return _logEntries.where((entry) => entry.level == level).toList();
  }

  /// Get log entries by tag
  List<LogEntry> getLogEntriesByTag(String tag) {
    return _logEntries.where((entry) => entry.tag == tag).toList();
  }

  /// Clear all log entries
  void clearLogs() {
    _logEntries.clear();
  }

  /// Export logs to string
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== DOA MAPS LOGS ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total entries: ${_logEntries.length}');
    buffer.writeln();

    for (final entry in _logEntries) {
      buffer.writeln(
          '${_formatTimestamp(entry.timestamp)} [${entry.level.name.toUpperCase()}] [${entry.tag}] ${entry.message}');

      if (entry.data != null && entry.data!.isNotEmpty) {
        buffer.writeln('  Data: ${entry.data}');
      }

      if (entry.error != null) {
        buffer.writeln('  Error: ${entry.error}');
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get log statistics
  Map<String, dynamic> getLogStatistics() {
    final stats = <String, int>{};

    for (final entry in _logEntries) {
      final key = '${entry.level.name}_${entry.tag}';
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return {
      'total_entries': _logEntries.length,
      'by_level': stats,
      'oldest_entry':
          _logEntries.isNotEmpty ? _logEntries.first.timestamp : null,
      'newest_entry':
          _logEntries.isNotEmpty ? _logEntries.last.timestamp : null,
    };
  }
}

/// Log entry class
class LogEntry {
  final LogLevel level;
  final String message;
  final String tag;
  final Map<String, dynamic>? data;
  final dynamic error;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    required this.tag,
    this.data,
    this.error,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LogEntry(level: ${level.name}, message: $message, tag: $tag, timestamp: $timestamp)';
  }
}

/// Extension untuk memudahkan logging
extension LoggingExtension on Object {
  /// Log debug message
  void logDebug(String message, {Map<String, dynamic>? data}) {
    LoggingService.debug(message, tag: runtimeType.toString(), data: data);
  }

  /// Log info message
  void logInfo(String message, {Map<String, dynamic>? data}) {
    LoggingService.info(message, tag: runtimeType.toString(), data: data);
  }

  /// Log warning message
  void logWarning(String message, {Map<String, dynamic>? data}) {
    LoggingService.warning(message, tag: runtimeType.toString(), data: data);
  }

  /// Log error message
  void logError(String message, {Map<String, dynamic>? data, dynamic error}) {
    LoggingService.error(message,
        tag: runtimeType.toString(), data: data, error: error);
  }

  /// Log critical message
  void logCritical(String message,
      {Map<String, dynamic>? data, dynamic error}) {
    LoggingService.critical(message,
        tag: runtimeType.toString(), data: data, error: error);
  }
}

/// Specialized logging for different services
class ServiceLogger {
  static void locationService(String message, {Map<String, dynamic>? data}) {
    LoggingService.info(message, tag: 'LocationService', data: data);
  }

  static void databaseService(String message, {Map<String, dynamic>? data}) {
    LoggingService.info(message, tag: 'DatabaseService', data: data);
  }

  static void notificationService(String message,
      {Map<String, dynamic>? data}) {
    LoggingService.info(message, tag: 'NotificationService', data: data);
  }

  static void encryptionService(String message, {Map<String, dynamic>? data}) {
    LoggingService.info(message, tag: 'EncryptionService', data: data);
  }

  static void backgroundService(String message, {Map<String, dynamic>? data}) {
    LoggingService.info(message, tag: 'BackgroundService', data: data);
  }

  // Add missing methods
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    LoggingService.info(message, tag: tag, data: data);
  }

  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    LoggingService.debug(message, tag: tag, data: data);
  }

  static void warning(String message,
      {String? tag, Map<String, dynamic>? data}) {
    LoggingService.warning(message, tag: tag, data: data);
  }

  static void error(String message,
      {String? tag, Map<String, dynamic>? data, dynamic error}) {
    LoggingService.error(message, tag: tag, data: data, error: error);
  }

  static void critical(String message,
      {String? tag, Map<String, dynamic>? data, dynamic error}) {
    LoggingService.critical(message, tag: tag, data: data, error: error);
  }
}
