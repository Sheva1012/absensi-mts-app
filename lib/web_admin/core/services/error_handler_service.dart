import 'package:flutter/material.dart';
import 'package:web_admin_mts/web_admin/core/exceptions.dart';
import 'package:web_admin_mts/web_admin/core/services/logging_service.dart';

/// Service for handling and displaying errors to users
class ErrorHandlerService {
  /// Get user-friendly error message from exception
  static String getUserMessage(AppException exception) {
    if (exception is ValidationException) {
      return exception.message;
    } else if (exception is NetworkException) {
      return 'Koneksi jaringan gagal. Silakan periksa koneksi internet Anda.';
    } else if (exception is TimeoutException) {
      return 'Permintaan timeout. Silakan coba lagi.';
    } else if (exception is NotFoundException) {
      return 'Data tidak ditemukan.';
    } else if (exception is AccessDeniedException) {
      return 'Anda tidak memiliki akses ke fitur ini.';
    } else if (exception is AuthException) {
      return 'Autentikasi gagal. Silakan login kembali.';
    } else if (exception is ServerException) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
    } else if (exception is RepositoryException) {
      return 'Gagal memproses data. Silakan coba lagi.';
    } else if (exception is ConfigException) {
      return 'Konfigurasi aplikasi tidak valid.';
    }
    return 'Terjadi kesalahan yang tidak terduga.';
  }

  /// Show error snackbar in context
  static void showErrorSnackbar(BuildContext context, AppException exception) {
    final message = getUserMessage(exception);
    
    log.error('Error shown to user: $message', error: exception);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    AppException exception, {
    String title = 'Terjadi Kesalahan',
  }) async {
    final message = getUserMessage(exception);

    log.error('Error dialog shown: $message', error: exception);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Convert generic exception to AppException
  static AppException handleException(dynamic exception, StackTrace stackTrace) {
    log.error(
      'Converting exception to AppException',
      error: exception,
      stackTrace: stackTrace,
    );

    if (exception is AppException) {
      return exception;
    }

    return GenericException(
      message: 'Terjadi kesalahan yang tidak terduga',
      originalException: exception,
      stackTrace: stackTrace,
    );
  }
}
