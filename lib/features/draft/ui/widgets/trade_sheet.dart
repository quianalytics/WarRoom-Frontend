import 'package:flutter/material.dart';
import '../../logic/draft_state.dart';
import '../../models/draft_pick.dart';

class TradeSheetResult {
  final String partnerTeam;
  final List<DraftPick> partnerPicksSelected;
  TradeSheetResult({required this.partnerTeam, required this.partnerPicksSelected});
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
  final selected = <String, DraftPick>{}; // key by pickOverall-round

  @override
  Widget build(BuildContext context) {
    final teams = widget.state.teams.map((t) => t.abbreviation.toUpperCase()).toList()..sort();
    final partnerTeams = teams.where((t) => t != widget.currentTeam.toUpperCase()).toList();

    final availablePartnerPicks = <DraftPick>[];
    if (partner != null) {
      for (final p in widget.state.order.skip(widget.state.currentIndex + 1)) {
        if (p.teamAbbr.toUpperCase() == partner!.toUpperCase()) {
          availablePartnerPicks.add(p);
        }
      }
    }

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
                selected.clear();
              }),
            ),

            const SizedBox(height: 12),

            if (partner == null)
              const Text('Select a partner team to see their future picks.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availablePartnerPicks.length,
                  itemBuilder: (context, i) {
                    final p = availablePartnerPicks[i];
                    final key = '${p.round}-${p.pickOverall}';
                    final isOn = selected.containsKey(key);

                    return CheckboxListTile(
                      dense: true,
                      value: isOn,
                      title: Text('${p.label}'),
                      subtitle: Text('Owned by ${p.teamAbbr}${p.teamAbbr != p.originalTeamAbbr ? ' • via ${p.originalTeamAbbr}' : ''}'),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selected[key] = p;
                          } else {
                            selected.remove(key);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (partner == null || selected.isEmpty)
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                          TradeSheetResult(
                            partnerTeam: partner!.toUpperCase(),
                            partnerPicksSelected: selected.values.toList(),
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
}
