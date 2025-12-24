import 'dart:async';

class DraftClock {
  Timer? _timer;

  void start({
    required int seconds,
    required void Function(int remaining) onTick,
    required void Function() onExpired,
  }) {
    _timer?.cancel();
    var remaining = seconds;
    onTick(remaining);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining -= 1;
      if (remaining <= 0) {
        t.cancel();
        onTick(0);
        onExpired();
      } else {
        onTick(remaining);
      }
    });
  }

  void stop() => _timer?.cancel();
}
