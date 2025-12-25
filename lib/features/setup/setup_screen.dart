import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/local_store.dart';
import '../draft/logic/draft_speed.dart';
import '../../theme/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int year = 2026;
  bool canResume = false;
  DraftSpeedPreset speedPreset = DraftSpeedPreset.fast;
  String tradeFrequency = 'normal';
  String tradeStrictness = 'normal';

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

  Future<bool> _guardYearAvailability() async {
    if (year != 2027) return true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('2027 Draft Coming Soon'),
        content: const Text(
          'The 2027 draft mode is not available yet. Check back soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _refreshResume();
  }

  @override
  Widget build(BuildContext context) {
    final teamColors = _teamColorMap();

    return Scaffold(
      appBar: AppBar(title: const Text('WarRoom Draft Setup')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
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
                Row(
                  children: [
                    const Text('CPU Speed:'),
                    const SizedBox(width: 12),
                    DropdownButton<DraftSpeedPreset>(
                      value: speedPreset,
                      items: const [
                        DropdownMenuItem(
                          value: DraftSpeedPreset.slow,
                          child: Text('Slow'),
                        ),
                        DropdownMenuItem(
                          value: DraftSpeedPreset.normal,
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(
                          value: DraftSpeedPreset.fast,
                          child: Text('Fast'),
                        ),
                        DropdownMenuItem(
                          value: DraftSpeedPreset.instant,
                          child: Text('Instant'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => speedPreset = v ?? DraftSpeedPreset.fast);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Trade Frequency:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: tradeFrequency,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (v) {
                        setState(() => tradeFrequency = v ?? 'normal');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Trade Strictness:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: tradeStrictness,
                      items: const [
                        DropdownMenuItem(
                          value: 'lenient',
                          child: Text('Lenient'),
                        ),
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'strict', child: Text('Strict')),
                      ],
                      onChanged: (v) {
                        setState(() => tradeStrictness = v ?? 'normal');
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
                        title: Text(
                          abbr,
                          style: TextStyle(
                            color: _readableTeamColor(
                              teamColors[abbr] ?? AppColors.text,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        : () async {
                            if (!await _guardYearAvailability()) return;
                            final teams = selected.toList()..sort();
                            context.go(
                              '/draft?year=$year&teams=${teams.join(',')}&speed=${speedPreset.name}&tradeFreq=$tradeFrequency&tradeStrict=$tradeStrictness',
                            );
                          },
                    child: const Text('Start Mock Draft'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: canResume
                        ? () async {
                            if (!await _guardYearAvailability()) return;
                            context.go(
                              '/draft?year=$year&teams=${(selected.toList()..sort()).join(',')}&resume=1&speed=${speedPreset.name}&tradeFreq=$tradeFrequency&tradeStrict=$tradeStrictness',
                            );
                          }
                        : null,
                    child: const Text('Resume Draft'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color> _teamColorMap() {
    final map = <String, Color>{};
    for (final t in allTeams) {
      final color = _colorForAbbr(t);
      if (color != null) {
        map[t] = color;
      }
    }
    return map;
  }

  Color? _colorForAbbr(String abbr) {
    switch (abbr) {
      case 'ARI':
        return const Color(0xFF97233F);
      case 'ATL':
        return const Color(0xFFA71930);
      case 'BAL':
        return const Color(0xFF241773);
      case 'BUF':
        return const Color(0xFF00338D);
      case 'CAR':
        return const Color(0xFF0085CA);
      case 'CHI':
        return const Color(0xFFC83803);
      case 'CIN':
        return const Color(0xFFFB4F14);
      case 'CLE':
        return const Color(0xFF311D00);
      case 'DAL':
        return const Color(0xFF003594);
      case 'DEN':
        return const Color(0xFFFB4F14);
      case 'DET':
        return const Color(0xFF0076B6);
      case 'GB':
        return const Color(0xFF203731);
      case 'HOU':
        return const Color(0xFF03202F);
      case 'IND':
        return const Color(0xFF002C5F);
      case 'JAX':
        return const Color(0xFF006778);
      case 'KC':
        return const Color(0xFFE31837);
      case 'LV':
        return const Color(0xFFA5ACAF);
      case 'LAC':
        return const Color(0xFF0080C6);
      case 'LAR':
        return const Color(0xFF003594);
      case 'MIA':
        return const Color(0xFF008E97);
      case 'MIN':
        return const Color(0xFF4F2683);
      case 'NE':
        return const Color(0xFF002244);
      case 'NO':
        return const Color(0xFFD3BC8D);
      case 'NYG':
        return const Color(0xFF0B2265);
      case 'NYJ':
        return const Color(0xFF125740);
      case 'PHI':
        return const Color(0xFF004C54);
      case 'PIT':
        return const Color(0xFFFFB612);
      case 'SF':
        return const Color(0xFFAA0000);
      case 'SEA':
        return const Color(0xFF002244);
      case 'TB':
        return const Color(0xFFD50A0A);
      case 'TEN':
        return const Color(0xFF0C2340);
      case 'WAS':
        return const Color(0xFF5A1414);
    }
    return null;
  }

  Color _readableTeamColor(Color color) {
    if (color.computeLuminance() >= 0.45) return color;
    return Color.lerp(color, Colors.white, 0.4) ?? color;
  }
}
