import 'dart:math';
import '../models/prospect.dart';
import '../models/team.dart';

class CpuDraftStrategy {
  final Random _rng = Random();

  Prospect choose({
    required Team? team,
    required List<Prospect> board,
    double randomness = 0.1,
  }) {
    if (board.isEmpty) throw StateError('No prospects available');

    // Sort by consensus rank (lower = better). Null ranks go to bottom.
    final sorted = [...board]..sort((a, b) {
      final ar = a.rank ?? 999999;
      final br = b.rank ?? 999999;
      return ar.compareTo(br);
    });

    // Needs boost: if team has needs list, prefer matching positions.
    final needs = (team?.needs ?? []).map((e) => e.toUpperCase()).toList();
    if (needs.isNotEmpty) {
      // Take a tighter window of top N and choose a need match if available.
      final window = sorted.take(22).toList();
      final needMatches = window.where((p) => needs.contains(p.position.toUpperCase())).toList();
      if (needMatches.isNotEmpty && _rng.nextDouble() > randomness) {
        return _weightedPick(needMatches);
      }
    }

    // Otherwise: pick from top window with slight randomness.
    final topN = max(5, (14 * (1 + randomness)).round());
    final window = sorted.take(topN).toList();
    return _weightedPick(window);
  }

  Prospect _weightedPick(List<Prospect> options) {
    if (options.length <= 1) return options.first;
    // Square to bias toward the top of the list while keeping some variance.
    final r = _rng.nextDouble();
    final idx = (r * r * options.length).floor().clamp(0, options.length - 1);
    return options[idx];
  }
}
