import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int year = 2026;

  // Temporary static list. Next step: load from /teams.
  final allTeams = const [
    'ARI','ATL','BAL','BUF','CAR','CHI','CIN','CLE','DAL','DEN','DET','GB',
    'HOU','IND','JAX','KC','LV','LAC','LAR','MIA','MIN','NE','NO','NYG',
    'NYJ','PHI','PIT','SF','SEA','TB','TEN','WAS'
  ];

  final selected = <String>{'NYG'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WarRoom Draft Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Draft Year:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: year,
                  items: const [
                    DropdownMenuItem(value: 2026, child: Text('2026')),
                    DropdownMenuItem(value: 2027, child: Text('2027')),
                  ],
                  onChanged: (v) => setState(() => year = v ?? 2026),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Teams you control (select 1+):'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: allTeams.length,
                itemBuilder: (context, i) {
                  final abbr = allTeams[i];
                  final isOn = selected.contains(abbr);
                  return CheckboxListTile(
                    dense: true,
                    value: isOn,
                    title: Text(abbr),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          selected.add(abbr);
                        } else {
                          selected.remove(abbr);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        final teams = selected.toList()..sort();
                        context.go('/draft?year=$year&teams=${teams.join(',')}');
                      },
                child: const Text('Start Mock Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
