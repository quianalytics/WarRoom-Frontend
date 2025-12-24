import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../logic/draft_state.dart';
import '../models/prospect.dart';

class DraftRoomScreen extends ConsumerStatefulWidget {
  const DraftRoomScreen({super.key, required this.year, required this.controlledTeams});

  final int year;
  final List<String> controlledTeams;

  @override
  ConsumerState<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends ConsumerState<DraftRoomScreen> {
  String search = '';
  String? positionFilter;

  @override
  void initState() {
    super.initState();
    // Start draft on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(draftControllerProvider.notifier).start(
            year: widget.year,
            userTeams: widget.controlledTeams.map((e) => e.toUpperCase()).toList(),
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
        title: Text('Mock Draft ${widget.year}'),
        actions: [
          IconButton(
            tooltip: state.clockRunning ? 'Pause' : 'Resume',
            onPressed: () => state.clockRunning ? controller.pauseClock() : controller.resumeClock(),
            icon: Icon(state.clockRunning ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(state.error!)))
              : _content(context, state),
    );
  }

  Widget _content(BuildContext context, DraftState state) {
    final pick = state.currentPick;

    final filtered = state.availableProspects.where((p) {
      if (search.isNotEmpty && !p.fullName.toLowerCase().contains(search.toLowerCase())) return false;
      if (positionFilter != null && positionFilter!.isNotEmpty && p.position.toUpperCase() != positionFilter) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final ar = a.consensusRank ?? 999999;
        final br = b.consensusRank ?? 999999;
        return ar.compareTo(br);
      });

    final topBoard = filtered.take(100).toList(); // avoid rendering thousands at once

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
                Expanded(
                  flex: 3,
                  child: _bigBoardPanel(state, topBoard),
                ),
                const SizedBox(width: 12),
                // Pick log
                Expanded(
                  flex: 2,
                  child: _pickLogPanel(state),
                ),
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
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(state.currentPick?.label ?? 'Complete', style: const TextStyle(fontSize: 18)),
          Text('OTC: ${state.onClockTeam}', style: const TextStyle(fontSize: 18)),
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
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search prospects…',
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
                  items: <String?>[null, 'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'EDGE', 'DL', 'LB', 'CB', 'S']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p ?? 'All')))
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
                  title: Text('${p.consensusRank ?? '-'}  ${p.fullName}'),
                  subtitle: Text('${p.position} • ${p.school ?? ''}'.trim()),
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
    return Container(
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Align(alignment: Alignment.centerLeft, child: Text('Pick Log', style: TextStyle(fontSize: 16))),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: state.picksMade.length,
              itemBuilder: (context, i) {
                final pr = state.picksMade[i];
                return ListTile(
                  dense: true,
                  title: Text('${pr.pick.pickOverall}. ${pr.teamAbbr} - ${pr.prospect.fullName}'),
                  subtitle: Text('${pr.prospect.position} • ${pr.prospect.school ?? ''}'.trim()),
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
            state.isComplete ? 'Draft complete' : 'On the clock: ${state.onClockTeam} • ${state.currentPick?.label}',
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
