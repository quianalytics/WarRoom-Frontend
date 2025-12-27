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

    // Needs-aware scoring: stay near BPA but nudge toward priority needs.
    final needs = (team?.needs ?? []).map((e) => e.toUpperCase()).toList();
    if (needs.isNotEmpty) {
      final window = sorted.take(32).toList();
      final scored = window
          .map(
            (p) => _ScoredProspect(
              p,
              _scoreProspect(p, needs, randomness),
            ),
          )
          .toList()
        ..sort((a, b) => a.score.compareTo(b.score));
      final ranked = scored.map((s) => s.prospect).toList();
      final topN = max(6, (10 * (1 + randomness)).round());
      return _weightedPick(ranked.take(topN).toList());
    }

    // Fallback: pick from top window with slight randomness.
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

  double _scoreProspect(
    Prospect prospect,
    List<String> needs,
    double randomness,
  ) {
    final rank = (prospect.rank ?? 999999).toDouble();
    final pos = prospect.position.toUpperCase();
    final needIndex = needs.indexOf(pos);
    if (needIndex == -1) return rank;
    // Earlier needs get a stronger bonus, but randomness softens the pull.
    final priority = (needs.length - needIndex).clamp(1, 6);
    final bonus = (priority * 2.0) * (1 - (randomness * 0.5));
    return rank - bonus;
  }
}

class _ScoredProspect {
  final Prospect prospect;
  final double score;

  const _ScoredProspect(this.prospect, this.score);
}
