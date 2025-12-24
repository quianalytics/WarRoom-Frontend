import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/local_store.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int year = 2026;
  bool canResume = false;

  // Temporary static list. Next step: load from /teams.
  final allTeams = const [
    'ARI',
    'ATL',
    'BAL',
    'BUF',
    'CAR',
    'CHI',
    'CIN',
    'CLE',
    'DAL',
    'DEN',
    'DET',
    'GB',
    'HOU',
    'IND',
    'JAX',
    'KC',
    'LV',
    'LAC',
    'LAR',
    'MIA',
    'MIN',
    'NE',
    'NO',
    'NYG',
    'NYJ',
    'PHI',
    'PIT',
    'SF',
    'SEA',
    'TB',
    'TEN',
    'WAS',
  ];

  final selected = <String>{};

  Future<void> _refreshResume() async {
    final has = await LocalStore.hasDraft(year);
    if (!mounted) return;
    setState(() => canResume = has);
  }

  @override
  void initState() {
    super.initState();
    _refreshResume();
  }

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
                  onChanged: (v) {
                    final newYear = v ?? 2026;
                    setState(() => year = newYear);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _refreshResume();
                    });
                  },
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
            if (selected.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Select at least one team to control.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selected.isEmpty
                    ? null // <- DISABLED when no teams selected
                    : () {
                        final teams = selected.toList()..sort();
                        context.go(
                          '/draft?year=$year&teams=${teams.join(',')}',
                        );
                      },
                child: const Text('Start Mock Draft'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canResume
                    ? () => context.go(
                        '/draft?year=$year&teams=${(selected.toList()..sort()).join(',')}&resume=1',
                      )
                    : null,
                child: const Text('Resume Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
