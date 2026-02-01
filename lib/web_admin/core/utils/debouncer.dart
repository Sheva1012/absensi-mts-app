import 'dart:async';

/// Debouncer utility to throttle function calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  /// Create a debouncer with specified delay
  Debouncer({required this.delay});

  /// Call the debounced function
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Dispose and clean up the debouncer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if debouncer is currently debouncing
  bool get isActive => _timer?.isActive ?? false;
}

typedef VoidCallback = void Function();

/// Throttler utility to limit function call frequency
class Throttler {
  final Duration duration;
  DateTime? _lastCallTime;
  Timer? _timer;

  /// Create a throttler with specified duration
  Throttler({required this.duration});

  /// Call the throttled function - returns true if executed, false if throttled
  bool call(VoidCallback action) {
    final now = DateTime.now();
    final lastCall = _lastCallTime;

    if (lastCall == null ||
        now.difference(lastCall).compareTo(duration) >= 0) {
      _lastCallTime = now;
      action();
      return true;
    }

    return false;
  }

  /// Dispose and clean up the throttler
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
