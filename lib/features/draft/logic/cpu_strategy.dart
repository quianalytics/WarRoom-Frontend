import 'dart:math';
import '../models/prospect.dart';
import '../models/team.dart';

class CpuDraftStrategy {
  final Random _rng = Random();

  Prospect choose({
    required Team? team,
    required List<Prospect> board,
    double randomness = 0.15,
  }) {
    if (board.isEmpty) throw StateError('No prospects available');

    // Sort by consensus rank (lower = better). Null ranks go to bottom.
    final sorted = [...board]..sort((a, b) {
      final ar = a.consensusRank ?? 999999;
      final br = b.consensusRank ?? 999999;
      return ar.compareTo(br);
    });

    // Needs boost: if team has needs list, prefer matching positions.
    final needs = (team?.needs ?? []).map((e) => e.toUpperCase()).toList();
    if (needs.isNotEmpty) {
      // Take a window of top N and choose a need match if available.
      final window = sorted.take(30).toList();
      final needMatches = window.where((p) => needs.contains(p.position.toUpperCase())).toList();
      if (needMatches.isNotEmpty && _rng.nextDouble() > randomness) {
        return needMatches[_rng.nextInt(needMatches.length)];
      }
    }

    // Otherwise: pick from top window with slight randomness.
    final topN = max(5, (20 * (1 + randomness)).round());
    final window = sorted.take(topN).toList();
    return window[_rng.nextInt(window.length)];
  }
}
