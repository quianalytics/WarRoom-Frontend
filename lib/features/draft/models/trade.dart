import 'draft_pick.dart';

class FuturePick {
  final String teamAbbr;
  final int year;
  final int round;
  final int? projectedOverall;

  const FuturePick({
    required this.teamAbbr,
    required this.year,
    required this.round,
    this.projectedOverall,
  });
}

class TradeAsset {
  final DraftPick? pick;
  final FuturePick? futurePick;

  const TradeAsset.pick(this.pick) : futurePick = null;
  const TradeAsset.future(this.futurePick) : pick = null;

  int get year => pick?.year ?? futurePick!.year;
  int get round => pick?.round ?? futurePick!.round;
  int? get pickOverall => pick?.pickOverall ?? futurePick!.projectedOverall;
  String get teamAbbr => pick?.teamAbbr ?? futurePick!.teamAbbr;
}

class TradeOffer {
  final String fromTeam; // acquiring team
  final String toTeam; // current pick owner
  final List<TradeAsset> fromAssets; // assets offered by fromTeam
  final List<TradeAsset> toAssets; // assets going to fromTeam

  TradeOffer({
    required this.fromTeam,
    required this.toTeam,
    required this.fromAssets,
    required this.toAssets,
  });
}
