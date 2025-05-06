import 'package:logger/logger.dart';

/// A singleton logger utility for consistent logging throughout the app.
class AppLogger {
  // Private static instance
  static final AppLogger _instance = AppLogger._internal();

  // The underlying logger instance
  final Logger _logger;

  /// Factory constructor returns the singleton instance.
  factory AppLogger() => _instance;

  // Private constructor initializes the logger.
  AppLogger._internal()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
        );

  /// Logs an info message.
  void info(String message) {
    _logger.i(message);
  }

  /// Logs a debug message.
  void debug(String message) {
    _logger.d(message);
  }

  /// Logs a warning message.
  void warning(String message) {
    _logger.w(message);
  }

  /// Logs an error message, with optional error and stack trace.
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
