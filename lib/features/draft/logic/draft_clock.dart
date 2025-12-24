import 'dart:async';

class DraftClock {
  Timer? _timer;
  int _remaining = 0;
  bool _running = false;

  void start({
    required int seconds,
    required void Function(int remaining) onTick,
    required void Function() onExpired,
  }) {
    stop();
    _remaining = seconds;
    _running = true;

    onTick(_remaining);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_running) return;

      _remaining -= 1;
      if (_remaining <= 0) {
        _remaining = 0;
        onTick(0);
        t.cancel();
        _timer = null;
        _running = false;
        onExpired();
      } else {
        onTick(_remaining);
      }
    });
  }

  /// Pause the countdown (does not reset remaining).
  void pause() {
    _running = false;
  }

  /// Resume the countdown (continues from remaining).
  void resume() {
    if (_timer == null) return; // not started / already expired
    _running = true;
  }

  /// Stop and reset.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _remaining = 0;
  }

  int get remaining => _remaining;
  bool get isRunning => _running;
}

