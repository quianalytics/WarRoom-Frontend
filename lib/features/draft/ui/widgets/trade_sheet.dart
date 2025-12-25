import 'package:flutter/material.dart';
import '../../logic/draft_state.dart';
import '../../models/draft_pick.dart';
import '../../models/trade.dart';

class TradeSheetResult {
  final String partnerTeam;
  final List<TradeAsset> partnerAssets;
  final List<TradeAsset> userAssets;

  TradeSheetResult({
    required this.partnerTeam,
    required this.partnerAssets,
    required this.userAssets,
  });
}

class TradeSheet extends StatefulWidget {
  const TradeSheet({
    super.key,
    required this.state,
    required this.currentTeam,
  });

  final DraftState state;
  final String currentTeam;

  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  String? partner;
  final selectedPartner = <String, TradeAsset>{};
  final selectedUser = <String, TradeAsset>{};

  List<DraftPick> _futureOwnedPicksFor(String teamAbbr) {
    final picks = <DraftPick>[];
    for (var i = widget.state.currentIndex + 1; i < widget.state.order.length; i++) {
      final p = widget.state.order[i];
      if (p.teamAbbr.toUpperCase() == teamAbbr.toUpperCase()) {
        picks.add(p);
      }
    }
    return picks;
  }

  List<DraftPick> _ownedPicksIncludingCurrent(String teamAbbr) {
    final picks = _futureOwnedPicksFor(teamAbbr);
    final current = widget.state.currentPick;
    if (current != null &&
        current.teamAbbr.toUpperCase() == teamAbbr.toUpperCase()) {
      return [current, ...picks];
    }
    return picks;
  }

  List<FuturePick> _futureYearPicksFor(String teamAbbr) {
    final year = widget.state.year;
    final picks = <FuturePick>[];
    for (var y = year + 1; y <= year + 2; y++) {
      for (var r = 1; r <= 7; r++) {
        picks.add(FuturePick(teamAbbr: teamAbbr, year: y, round: r));
      }
    }
    return picks;
  }

  @override
  Widget build(BuildContext context) {
    final teams = widget.state.teams.map((t) => t.abbreviation.toUpperCase()).toList()..sort();
    final partnerTeams = teams.where((t) => t != widget.currentTeam.toUpperCase()).toList();

    final partnerPicks = partner == null ? <DraftPick>[] : _futureOwnedPicksFor(partner!);
    final userPicks = _ownedPicksIncludingCurrent(widget.currentTeam);

    final partnerFuture = partner == null ? <FuturePick>[] : _futureYearPicksFor(partner!);
    final userFuture = _futureYearPicksFor(widget.currentTeam);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Propose Trade', style: TextStyle(fontSize: 18))),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: partner,
              decoration: const InputDecoration(labelText: 'Trade partner', border: OutlineInputBorder()),
              items: partnerTeams.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() {
                partner = v;
                selectedPartner.clear();
                selectedUser.clear();
              }),
            ),

            const SizedBox(height: 12),

            if (partner == null)
              const Text('Select a partner team to see their future picks.')
            else
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Text(
                            '${widget.currentTeam.toUpperCase()} assets',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          ..._buildPickSection(
                            title: 'Current picks',
                            picks: userPicks,
                            selected: selectedUser,
                            ownerLabel: widget.currentTeam,
                          ),
                          ..._buildFutureSection(
                            title: 'Future picks',
                            picks: userFuture,
                            selected: selectedUser,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          Text(
                            '${partner!.toUpperCase()} assets',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          ..._buildPickSection(
                            title: 'Current picks',
                            picks: partnerPicks,
                            selected: selectedPartner,
                            ownerLabel: partner!,
                          ),
                          ..._buildFutureSection(
                            title: 'Future picks',
                            picks: partnerFuture,
                            selected: selectedPartner,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (partner == null || selectedPartner.isEmpty)
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                          TradeSheetResult(
                            partnerTeam: partner!.toUpperCase(),
                            partnerAssets: selectedPartner.values.toList(),
                            userAssets: selectedUser.values.toList(),
                          ),
                        );
                      },
                child: const Text('Submit Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPickSection({
    required String title,
    required List<DraftPick> picks,
    required Map<String, TradeAsset> selected,
    required String ownerLabel,
  }) {
    if (picks.isEmpty) {
      return [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        const Text('No remaining picks.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 10),
      ];
    }

    return [
      Text(title, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 6),
      ...picks.map((p) {
        final key = 'pick:${p.year}:${p.round}:${p.pickOverall}:${ownerLabel.toUpperCase()}';
        final isOn = selected.containsKey(key);
        return CheckboxListTile(
          dense: true,
          value: isOn,
          title: Text(p.label),
          subtitle: Text(
            'Owned by ${p.teamAbbr}${p.teamAbbr != p.originalTeamAbbr ? ' • via ${p.originalTeamAbbr}' : ''}',
          ),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                selected[key] = TradeAsset.pick(p);
              } else {
                selected.remove(key);
              }
            });
          },
        );
      }),
      const SizedBox(height: 10),
    ];
  }

  List<Widget> _buildFutureSection({
    required String title,
    required List<FuturePick> picks,
    required Map<String, TradeAsset> selected,
  }) {
    return [
      Text(title, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 6),
      ...picks.map((p) {
        final key = 'future:${p.teamAbbr}:${p.year}:${p.round}';
        final isOn = selected.containsKey(key);
        return CheckboxListTile(
          dense: true,
          value: isOn,
          title: Text('${p.year} Round ${p.round} (projected)'),
          subtitle: Text('Owned by ${p.teamAbbr}'),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                selected[key] = TradeAsset.future(p);
              } else {
                selected.remove(key);
              }
            });
          },
        );
      }),
      const SizedBox(height: 10),
    ];
  }

}
