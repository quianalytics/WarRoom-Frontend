import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/draft_state.dart';
import '../providers.dart';
import '../../../theme/app_theme.dart';
import '../../../ui/panel.dart';

class DraftRecapScreen extends ConsumerStatefulWidget {
  const DraftRecapScreen({super.key});

  @override
  ConsumerState<DraftRecapScreen> createState() => _DraftRecapScreenState();
}

class _DraftRecapScreenState extends ConsumerState<DraftRecapScreen> {
  String? _teamFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftControllerProvider);
    final userTeams =
        state.userTeams.map((t) => t.toUpperCase()).toList()..sort();
    final filter = _teamFilter;

    final picks = state.picksMade
        .where((p) => userTeams.contains(p.teamAbbr.toUpperCase()))
        .where((p) => filter == null || p.teamAbbr.toUpperCase() == filter)
        .toList()
      ..sort((a, b) => a.pick.pickOverall.compareTo(b.pick.pickOverall));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Recap'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: picks.isEmpty
                ? const Center(
                    child: Text('No user picks found for this draft.'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _summary(picks),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Team:'),
                                const SizedBox(width: 12),
                                DropdownButton<String?>(
                                  value: _teamFilter,
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All User Teams'),
                                    ),
                                    ...userTeams.map(
                                      (t) => DropdownMenuItem<String?>(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    setState(() => _teamFilter = v);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: picks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final pr = picks[i];
                            final grade = _gradeForPick(pr);
                            return Panel(
                              child: Row(
                                children: [
                                  _gradeChip(grade.letter),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pr.prospect.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pick ${pr.pick.pickOverall} • ${pr.teamAbbr} • ${pr.prospect.position}${_collegeLabel(pr)}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _summary(List<PickResult> picks) {
    final grades = picks.map(_gradeForPick).toList();
    final avg = _avgScore(grades);
    return Row(
      children: [
        _gradeChip(avg.letter, large: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Draft Class',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '${picks.length} picks • Avg value ${avg.score.toStringAsFixed(1)}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _Grade _gradeForPick(PickResult pr) {
    final rank = pr.prospect.rank;
    if (rank == null) {
      return const _Grade('B', 85);
    }
    final delta = pr.pick.pickOverall - rank;
    if (delta >= 9) return const _Grade('A+', 98);
    if (delta >= 5) return const _Grade('A', 94);
    if (delta >= 2) return const _Grade('A-', 91);
    if (delta >= -1) return const _Grade('B+', 88);
    if (delta >= -4) return const _Grade('B', 84);
    if (delta >= -7) return const _Grade('B-', 81);
    if (delta >= -11) return const _Grade('C+', 78);
    if (delta >= -16) return const _Grade('C', 74);
    if (delta >= -24) return const _Grade('D', 68);
    return const _Grade('F', 60);
  }

  _Grade _avgScore(List<_Grade> grades) {
    final total = grades.fold<double>(0, (s, g) => s + g.score);
    final avg = total / grades.length;
    return _scoreToGrade(avg);
  }

  _Grade _scoreToGrade(double score) {
    if (score >= 97) return const _Grade('A+', 98);
    if (score >= 93) return const _Grade('A', 94);
    if (score >= 90) return const _Grade('A-', 91);
    if (score >= 87) return const _Grade('B+', 88);
    if (score >= 83) return const _Grade('B', 84);
    if (score >= 80) return const _Grade('B-', 81);
    if (score >= 77) return const _Grade('C+', 78);
    if (score >= 73) return const _Grade('C', 74);
    if (score >= 65) return const _Grade('D', 68);
    return const _Grade('F', 60);
  }

  Widget _gradeChip(String grade, {bool large = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.blue.withOpacity(0.45)),
      ),
      child: Text(
        grade,
        style: TextStyle(
          fontSize: large ? 18 : 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _collegeLabel(PickResult pr) {
    final college = pr.prospect.college ?? '';
    if (college.isEmpty) return '';
    return ' • $college';
  }
}

class _Grade {
  final String letter;
  final double score;

  const _Grade(this.letter, this.score);
}
