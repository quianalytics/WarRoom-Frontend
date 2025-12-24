import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../logic/draft_state.dart';
import '../models/prospect.dart';
import 'package:go_router/go_router.dart';

enum PickLogSortMode { pick, team }

class DraftRoomScreen extends ConsumerStatefulWidget {
  const DraftRoomScreen({
    super.key,
    required this.year,
    required this.controlledTeams,
  });
  
  final int year;
  final List<String> controlledTeams;

  @override
  ConsumerState<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends ConsumerState<DraftRoomScreen> {
  String search = '';
  String? positionFilter;
  String? pickLogTeamFilter; // null = All Teams


  @override
  void initState() {
    super.initState();
    // Start draft on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(draftControllerProvider.notifier)
          .start(
            year: widget.year,
            userTeams: widget.controlledTeams
                .map((e) => e.toUpperCase())
                .toList(),
            clockSeconds: 180, // set to 180 for faster testing; bump later
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftControllerProvider);
    final controller = ref.read(draftControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('WarRoom Mock Draft ${widget.year}'),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Exit draft?'),
                  content: const Text('Your current draft will not be saved.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                // Navigates back to setup screen
                if (context.mounted) context.go('/');
              }
            },
            child: const Text('Exit'),
          ),
          IconButton(
            tooltip: state.clockRunning ? 'Pause' : 'Resume',
            onPressed: () => state.clockRunning
                ? ref.read(draftControllerProvider.notifier).pauseClock()
                : ref.read(draftControllerProvider.notifier).resumeClock(),
            icon: Icon(state.clockRunning ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),

      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(state.error!),
              ),
            )
          : _content(context, state),
    );
  }

  Widget _content(BuildContext context, DraftState state) {
    final pick = state.currentPick;

    final filtered =
        state.availableProspects.where((p) {
          if (search.isNotEmpty &&
              !p.name.toLowerCase().contains(search.toLowerCase()))
            return false;
          if (positionFilter != null &&
              positionFilter!.isNotEmpty &&
              p.position.toUpperCase() != positionFilter) {
            return false;
          }
          return true;
        }).toList()..sort((a, b) {
          final ar = a.rank ?? 999999;
          final br = b.rank ?? 999999;
          return ar.compareTo(br);
        });

    final topBoard = filtered
        .take(100)
        .toList(); // avoid rendering thousands at once

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _header(state),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                // Big board
                Expanded(flex: 3, child: _bigBoardPanel(state, topBoard)),
                const SizedBox(width: 12),
                // Pick log
                Expanded(flex: 2, child: _pickLogPanel(state)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (pick != null) _onClockFooter(state),
        ],
      ),
    );
  }

  Widget _header(DraftState state) {
    final m = (state.secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (state.secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            state.currentPick?.label ?? 'Complete',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'OTC: ${state.onClockTeam}',
            style: const TextStyle(fontSize: 18),
          ),
          Text('$m:$s', style: const TextStyle(fontSize: 18)),
          if (state.isUserOnClock)
            const Chip(label: Text('USER PICK'))
          else
            const Chip(label: Text('CPU PICK')),
        ],
      ),
    );
  }

  Widget _bigBoardPanel(DraftState state, List<Prospect> board) {
    final controller = ref.read(draftControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: positionFilter,
                  hint: const Text('Pos'),
                  items:
                      <String?>[
                            null,
                            'QB',
                            'RB',
                            'WR',
                            'TE',
                            'OT',
                            'IOL',
                            'EDGE',
                            'DL',
                            'LB',
                            'CB',
                            'S',
                          ]
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p ?? 'All'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => positionFilter = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: board.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = board[i];
                final canPick = state.isUserOnClock && !state.isComplete;

                return ListTile(
                  dense: true,
                  title: Text('${p.rank ?? '-'}  ${p.name}'),
                  subtitle: Text('${p.position} • ${p.college ?? ''}'.trim()),
                  trailing: canPick
                      ? FilledButton(
                          onPressed: () => controller.draftProspect(p),
                          child: const Text('Draft'),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _pickLogPanel(DraftState state) {
  // Build dropdown options from picks that have occurred so far
  final teamCounts = <String, int>{};
  for (final pr in state.picksMade) {
    teamCounts[pr.teamAbbr] = (teamCounts[pr.teamAbbr] ?? 0) + 1;
  }

  final teams = teamCounts.keys.toList()..sort();

  // If current filter team no longer exists (e.g., new draft), reset it
  if (pickLogTeamFilter != null && !teamCounts.containsKey(pickLogTeamFilter)) {
    pickLogTeamFilter = null;
  }

  // Apply filter
  final picks = pickLogTeamFilter == null
      ? state.picksMade
      : state.picksMade.where((p) => p.teamAbbr == pickLogTeamFilter).toList();

  return Container(
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pickLogTeamFilter == null ? 'Pick Log' : '${pickLogTeamFilter!} Picks',
                style: const TextStyle(fontSize: 16),
              ),
              DropdownButton<String?>(
                value: pickLogTeamFilter,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Teams'),
                  ),
                  ...teams.map((abbr) {
                    final c = teamCounts[abbr] ?? 0;
                    return DropdownMenuItem<String?>(
                      value: abbr,
                      child: Text('$abbr ($c)'),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => pickLogTeamFilter = v),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: picks.isEmpty
              ? const Center(child: Text('No picks yet.'))
              : ListView.builder(
                  itemCount: picks.length,
                  itemBuilder: (context, i) {
                    final pr = picks[i];
                    return ListTile(
                      dense: true,
                      title: Text('${pr.pick.pickOverall}. ${pr.teamAbbr} - ${pr.prospect.name}'),
                      subtitle: Text('${pr.prospect.position} • ${pr.prospect.college ?? ''}'.trim()),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

  Widget _onClockFooter(DraftState state) {
    // Later: add a Trade button that opens a bottom sheet to propose trades
    final controller = ref.read(draftControllerProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: Text(
            state.isComplete
                ? 'Draft complete'
                : 'On the clock: ${state.onClockTeam} • ${state.currentPick?.label}',
          ),
        ),
        if (!state.isUserOnClock && !state.isComplete)
          FilledButton(
            onPressed: () => controller.autoPick(),
            child: const Text('Force CPU Pick'),
          ),
      ],
    );
  }
}
