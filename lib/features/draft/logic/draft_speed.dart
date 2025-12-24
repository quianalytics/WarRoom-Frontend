enum DraftSpeedPreset { slow, normal, fast, instant }

class DraftSpeed {
  final int userClockSeconds;
  final int cpuClockSeconds;
  final int cpuThinkMinSeconds;
  final int cpuThinkMaxSeconds;

  const DraftSpeed({
    required this.userClockSeconds,
    required this.cpuClockSeconds,
    required this.cpuThinkMinSeconds,
    required this.cpuThinkMaxSeconds,
  });

  static DraftSpeed forPreset(DraftSpeedPreset p) {
    switch (p) {
      case DraftSpeedPreset.slow:
        return const DraftSpeed(userClockSeconds: 180, cpuClockSeconds: 45, cpuThinkMinSeconds: 4, cpuThinkMaxSeconds: 10);
      case DraftSpeedPreset.normal:
        return const DraftSpeed(userClockSeconds: 120, cpuClockSeconds: 25, cpuThinkMinSeconds: 2, cpuThinkMaxSeconds: 6);
      case DraftSpeedPreset.fast:
        return const DraftSpeed(userClockSeconds: 60, cpuClockSeconds: 12, cpuThinkMinSeconds: 1, cpuThinkMaxSeconds: 3);
      case DraftSpeedPreset.instant:
        return const DraftSpeed(userClockSeconds: 60, cpuClockSeconds: 1, cpuThinkMinSeconds: 0, cpuThinkMaxSeconds: 0);
    }
  }
}
