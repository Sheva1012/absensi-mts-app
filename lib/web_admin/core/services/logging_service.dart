import 'package:flutter/foundation.dart';

/// Structured logging service for application
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();

  /// Private constructor for singleton pattern
  LoggingService._internal();

  /// Get the singleton instance
  factory LoggingService() => _instance;

  /// Log info level message
  void info(String message, {String? tag}) {
    debugPrint('$_formatTag(tag, "INFO") $message');
  }

  /// Log debug level message
  void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_formatTag(tag, "DEBUG") $message');
    }
  }

  /// Log warning level message
  void warning(String message, {String? tag}) {
    debugPrint('$_formatTag(tag, "WARNING") $message');
  }

  /// Log error with optional stack trace
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    debugPrint('$_formatTag(tag, "ERROR") $message');
    if (error != null) {
      debugPrint('Exception: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
    // TODO: Integrate with Sentry for production
  }

  /// Log network request
  void network(
    String method,
    String url, {
    int? statusCode,
    String? error,
    String? tag,
  }) {
    final result = error != null ? 'FAILED' : 'SUCCESS';
    final status = statusCode != null ? ' - $statusCode' : '';
    debug(
      '[$method] $url$status - $result',
      tag: tag ?? 'Network',
    );
    if (error != null) {
      this.error('Network error: $error', tag: tag ?? 'Network');
    }
  }

  /// Log database operation
  void database(String operation, String table, {String? details, String? tag}) {
    debug(
      '[$operation] $table${details != null ? ' - $details' : ''}',
      tag: tag ?? 'Database',
    );
  }

  /// Log state change
  void stateChange(String state, {Map<String, dynamic>? data, String? tag}) {
    final dataStr =
        data != null ? ' - ${data.toString()}' : '';
    debug(
      'State changed: $state$dataStr',
      tag: tag ?? 'State',
    );
  }

  /// Format tag for logging
  static String _formatTag(String? tag, String level) {
    final displayTag = tag ?? 'App';
    return '[$level] [$displayTag]';
  }
}

/// Global logging service instance
final log = LoggingService();
