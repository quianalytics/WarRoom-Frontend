import 'dart:math';
import '../models/draft_pick.dart';
import '../models/prospect.dart';
import '../models/team.dart';
import '../models/trade.dart';

class TradeContext {
  final DraftPick currentPick;
  final Team? fromTeam;
  final Team? toTeam;
  final List<Prospect> availableProspects;
  final int currentYear;

  TradeContext({
    required this.currentPick,
    required this.fromTeam,
    required this.toTeam,
    required this.availableProspects,
    required this.currentYear,
  });
}

/// Rich Hill-style value curve (approximation). Replace with exact table if needed.
class RichHillChart {
  double valueForPick(int overall) {
    final pick = overall.clamp(1, 300);
    const maxValue = 1000.0;
    final curve = pow(0.95, pick - 1);
    final value = maxValue * curve;
    return value < 1 ? 1 : value;
  }
}

class TradeEngine {
  final RichHillChart chart = RichHillChart();

  bool accept(TradeOffer offer, {required TradeContext context}) {
    final give = _totalValue(offer.toAssets, context);
    final get = _totalValue(offer.fromAssets, context);
    final threshold = _acceptThreshold(offer, context);

    // toTeam accepts if it receives enough value relative to what it gives
    return get >= give * threshold;
  }

  double _totalValue(List<TradeAsset> assets, TradeContext context) {
    return assets.fold<double>(
      0,
      (sum, asset) => sum + _assetValue(asset, context),
    );
  }

  double _assetValue(TradeAsset asset, TradeContext context) {
    final pickOverall = asset.pickOverall ?? _estimateOverall(asset.round);
    var value = chart.valueForPick(pickOverall);

    final yearDelta = asset.year - context.currentYear;
    if (yearDelta > 0) {
      value *= pow(0.9, yearDelta).toDouble(); // future pick discount
    }

    return value;
  }

  int _estimateOverall(int round) {
    final r = round.clamp(1, 7);
    final midInRound = 16;
    return ((r - 1) * 32) + midInRound;
  }

  double _acceptThreshold(TradeOffer offer, TradeContext context) {
    var threshold = 0.92;

    // Earlier picks demand stronger returns.
    final overall = context.currentPick.pickOverall;
    if (overall <= 5) {
      threshold += 0.08;
    } else if (overall <= 10) {
      threshold += 0.05;
    } else if (overall <= 20) {
      threshold += 0.03;
    } else if (overall <= 32) {
      threshold += 0.02;
    }

    // If top prospects match team needs, be less willing to move.
    threshold += _needsPremium(context.toTeam, context.availableProspects);
    threshold += _eliteBoardPremium(context.availableProspects);

    // Future picks add uncertainty.
    if (_hasFutureAssets(offer.fromAssets, context.currentYear)) {
      threshold += 0.02;
    }

    // Trade-down incentive if receiving multiple later picks.
    threshold -= _tradeDownIncentive(offer, context.currentPick);

    return threshold.clamp(0.85, 1.15);
  }

  double _needsPremium(Team? team, List<Prospect> board) {
    final needs = team?.needs
            ?.map((e) => e.toUpperCase())
            .toSet() ??
        <String>{};
    if (needs.isEmpty) return 0;

    final ranked = board
        .where((p) => p.rank != null)
        .toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));

    final window = ranked.take(25).toList();
    final matches = window
        .where((p) => needs.contains(p.position.toUpperCase()))
        .length;

    if (matches >= 3) return 0.06;
    if (matches >= 1) return 0.03;
    return 0;
  }

  double _eliteBoardPremium(List<Prospect> board) {
    final ranked = board
        .where((p) => p.rank != null)
        .toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));
    if (ranked.isEmpty) return 0;
    final best = ranked.first.rank!;
    if (best <= 5) return 0.04;
    if (best <= 10) return 0.02;
    return 0;
  }

  bool _hasFutureAssets(List<TradeAsset> assets, int currentYear) {
    return assets.any((a) => a.year > currentYear);
  }

  double _tradeDownIncentive(TradeOffer offer, DraftPick currentPick) {
    final incoming = offer.fromAssets
        .where((a) => a.pickOverall != null)
        .map((a) => a.pickOverall!)
        .toList();
    if (incoming.length < 2) return 0;

    final laterPicks =
        incoming.where((o) => o > currentPick.pickOverall).toList();
    if (laterPicks.length < 2) return 0;

    final avgIncoming =
        laterPicks.reduce((a, b) => a + b) / laterPicks.length;
    final delta = avgIncoming - currentPick.pickOverall;

    if (delta >= 20) return 0.04;
    if (delta >= 10) return 0.03;
    if (delta >= 5) return 0.02;
    return 0;
  }
}
