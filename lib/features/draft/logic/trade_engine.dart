import '../models/draft_pick.dart';

class TradeOffer {
  final String fromTeam; // acquiring team
  final String toTeam;   // current pick owner
  final List<DraftPick> fromAssets; // picks offered by fromTeam
  final List<DraftPick> toAssets;   // picks going to fromTeam (typically current pick)
  TradeOffer({
    required this.fromTeam,
    required this.toTeam,
    required this.fromAssets,
    required this.toAssets,
  });
}

/// Simple value chart stub. Replace with JJ/Rich Hill tables later.
class PickValueChart {
  double valueOf(DraftPick p) {
    // crude decreasing curve; good enough for MVP trade accept/decline
    final x = p.pickOverall.toDouble();
    return 3000 / (1 + (x / 20));
  }
}

class TradeEngine {
  final PickValueChart chart = PickValueChart();

  bool accept(TradeOffer offer, {double threshold = 0.92}) {
    final give = offer.toAssets.fold<double>(0, (s, p) => s + chart.valueOf(p));
    final get = offer.fromAssets.fold<double>(0, (s, p) => s + chart.valueOf(p));

    // toTeam accepts if it receives enough value relative to what it gives
    return get >= give * threshold;
  }
}
