import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../logic/draft_speed.dart';
import '../logic/draft_state.dart';
import '../models/trade.dart';
import '../models/prospect.dart';
import 'widgets/trade_sheet.dart';
import '../../../ui/icon_pill.dart';
import '../../../ui/panel.dart';
import '../../../theme/app_theme.dart';

class DraftRoomScreen extends ConsumerStatefulWidget {
  const DraftRoomScreen({
    super.key,
    required this.year,
    required this.controlledTeams,
    required this.resume,
  });

  final int year;
  final List<String> controlledTeams;
  final bool resume;

  @override
  ConsumerState<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends ConsumerState<DraftRoomScreen> {
  String search = '';
  String? positionFilter;
  String? pickLogTeamFilter; // null = All Teams
  bool _bootstrapped = false;
  bool recapCollapsed = false;

  @override
  void initState() {
    super.initState();

    // Avoid Riverpod provider mutation during build/lifecycle.
    Future.microtask(() {
      if (!mounted || _bootstrapped) return;
      _bootstrapped = true;

      final controller = ref.read(draftControllerProvider.notifier);

      if (widget.resume) {
        controller.resumeSavedDraft(widget.year);
      } else {
        controller.start(
          year: widget.year,
          userTeams: widget.controlledTeams
              .map((e) => e.toUpperCase())
              .toList(),
          speedPreset: DraftSpeedPreset.fast,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftControllerProvider);
    final controller = ref.read(draftControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.year} Mock Draft'),
        actions: [
          // Draft speed
          PopupMenuButton<DraftSpeedPreset>(
            tooltip: 'Speed',
            onSelected: controller.setSpeedPreset,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: DraftSpeedPreset.slow,
                child: Text('Speed: Slow'),
              ),
              PopupMenuItem(
                value: DraftSpeedPreset.normal,
                child: Text('Speed: Normal'),
              ),
              PopupMenuItem(
                value: DraftSpeedPreset.fast,
                child: Text('Speed: Fast'),
              ),
              PopupMenuItem(
                value: DraftSpeedPreset.instant,
                child: Text('Speed: Instant'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: IconPill(
                icon: Icons.speed,
                tooltip: 'Speed',
                onPressed: () {}, // handled by PopupMenuButton
              ),
            ),
          ),

          IconPill(
            icon: state.clockRunning ? Icons.pause : Icons.play_arrow,
            tooltip: state.clockRunning ? 'Pause' : 'Resume',
            onPressed: () {
              state.clockRunning
                  ? controller.pauseClock()
                  : controller.resumeClock();
            },
          ),

          IconPill(
            icon: Icons.exit_to_app,
            tooltip: 'Exit',
            onPressed: () => _confirmExit(context),
          ),

          const SizedBox(width: 8),
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

  Future<void> _confirmExit(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit draft?'),
        content: const Text('Press Resume Draft on the home page if you would like to finish.'),
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

    if (ok == true && context.mounted) {
      context.go('/');
    }
  }

  Widget _content(BuildContext context, DraftState state) {
    final pick = state.currentPick;

    final filtered =
        state.availableProspects.where((p) {
          if (search.isNotEmpty &&
              !p.name.toLowerCase().contains(search.toLowerCase())) {
            return false;
          }
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

    final topBoard = filtered.take(150).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Panel(child: _header(context, state)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                // Big board expands to full width when recap is collapsed
                Expanded(
                  flex: recapCollapsed ? 1 : 3,
                  child: _bigBoardPanel(state, topBoard),
                ),
                const SizedBox(width: 12),

                if (recapCollapsed)
                  SizedBox(
                    width: 44, // slim rail
                    child: _recapRail(state),
                  )
                else
                  Expanded(flex: 2, child: Panel(child: _pickLogPanel(state))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (pick != null) Panel(child: _onClockFooter(state)),
        ],
      ),
    );
  }

  Widget _recapRail(DraftState state) {
    return Panel(
      padding: EdgeInsets.zero, // no padding
      child: Center(
        child: IconButton(
          tooltip: 'Expand recap',
          onPressed: () => setState(() => recapCollapsed = false),
          icon: const Icon(Icons.chevron_left, size: 22),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DraftState state) {
    final m = (state.secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (state.secondsRemaining % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            state.currentPick?.label ?? 'Draft complete',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.blue.withOpacity(0.5)),
          ),
          child: Text(
            'OTC: ${state.onClockTeam}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$m:$s',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        _statusChip(state),
      ],
    );
  }

  Widget _statusChip(DraftState state) {
    final isUser = state.isUserOnClock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      decoration: BoxDecoration(
        color: isUser ? AppColors.blue.withOpacity(0.15) : AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isUser ? AppColors.blue.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Text(
        isUser ? 'USER PICK' : 'CPU PICK',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _bigBoardPanel(DraftState state, List<Prospect> board) {
    final controller = ref.read(draftControllerProvider.notifier);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: positionFilter,
                hint: const Text('Pos'),
                items:
                    const <String?>[
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
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            itemCount: board.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = board[i];
              final canPick = state.isUserOnClock && !state.isComplete;

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                title: Row(
                  children: [
                    _rankPill(p.rank),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // Explicit color avoids theme edge-cases and ensures visibility
                        // even when trailing actions are present.
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _posPill(p.position),
                  ],
                ),
                subtitle: Text(
                  p.college ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                // Keep the call-to-action compact so the player name doesn't get squeezed
                // on smaller screens.
                trailing: canPick
                    ? FilledButton.tonalIcon(
                        onPressed: () => controller.draftProspect(p),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Draft'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rankPill(int? rank) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        (rank ?? 0) == 0 ? '-' : '$rank',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _posPill(String pos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.blue.withOpacity(0.35)),
      ),
      child: Text(
        pos.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _pickLogPanel(DraftState state) {
    // Dropdown options from ALL teams (so it exists even before picks happen)
    final allTeams =
        state.teams.map((t) => t.abbreviation.toUpperCase()).toList()..sort();
    final userTeams =
        widget.controlledTeams.map((t) => t.toUpperCase()).toList();
    final userSet = userTeams.toSet();
    final orderedTeams = [
      ...userTeams,
      ...allTeams.where((t) => !userSet.contains(t)),
    ];

    final counts = <String, int>{};
    for (final t in allTeams) {
      counts[t] = 0;
    }
    for (final pr in state.picksMade) {
      counts[pr.teamAbbr] = (counts[pr.teamAbbr] ?? 0) + 1;
    }

    // Default to the first user-controlled team if no filter is set.
    if (pickLogTeamFilter == null && userTeams.isNotEmpty) {
      Future.microtask(() {
        if (!mounted) return;
        setState(() => pickLogTeamFilter = userTeams.first);
      });
    }

    // Reset filter if team disappears (edge cases)
    if (pickLogTeamFilter != null && !allTeams.contains(pickLogTeamFilter)) {
      pickLogTeamFilter = null;
    }

    final selectedTeam = pickLogTeamFilter;

    final picks = selectedTeam == null
        ? state.picksMade
        : state.picksMade.where((p) => p.teamAbbr == selectedTeam).toList();

    final teamObj = selectedTeam == null
        ? null
        : state.teams.firstWhere(
            (t) => t.abbreviation.toUpperCase() == selectedTeam,
            orElse: () => state.teams.first,
          );

    final roster = selectedTeam == null
        ? const <PickResult>[]
        : state.picksMade.where((p) => p.teamAbbr == selectedTeam).toList();

    // Slightly reorder picks for filtered view: by pick overall.
    if (selectedTeam != null) {
      picks.sort((a, b) => a.pick.pickOverall.compareTo(b.pick.pickOverall));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: pickLogTeamFilter,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Teams'),
                  ),
                  ...orderedTeams.map((abbr) {
                    final c = counts[abbr] ?? 0;
                    return DropdownMenuItem<String?>(
                      value: abbr,
                      child: Text('$abbr ($c)'),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => pickLogTeamFilter = v),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: recapCollapsed ? 'Expand recap' : 'Collapse recap',
              onPressed: () => setState(() => recapCollapsed = !recapCollapsed),
              icon: Icon(
                recapCollapsed ? Icons.chevron_left : Icons.chevron_right,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 6),
        const Divider(height: 1),
        const SizedBox(height: 6),
        if (!recapCollapsed)
          Expanded(
            child: picks.isEmpty
                ? const Center(child: Text('No picks yet.'))
                : ListView.separated(
                    itemCount: picks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final pr = picks[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        // Put the player name first so it remains visible on narrow layouts.
                        title: Text(
                          pr.prospect.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          '${pr.pick.pickOverall}. ${pr.teamAbbr}  •  R${pr.pick.round}.${pr.pick.pickInRound.toString().padLeft(2, '0')}  •  ${pr.prospect.position}${(pr.prospect.college == null || pr.prospect.college!.isEmpty) ? '' : ' • ${pr.prospect.college}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _onClockFooter(DraftState state) {
    final controller = ref.read(draftControllerProvider.notifier);

    final canTrade = !state.isComplete && state.currentPick != null;
    final canRun = !state.isUserOnClock && !state.isComplete;

    return Row(
      children: [
        Expanded(
          child: Text(
            state.isComplete
                ? 'Draft complete'
                : 'On the clock: ${state.onClockTeam} • ${state.currentPick?.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        // if (canRun)
        //   FilledButton(
        //     onPressed: () => controller.runToNextUserPick(),
        //     child: const Text('Run to My Next Pick'),
        //   ),
        if (canRun) const SizedBox(width: 8),
        if (canRun)
          OutlinedButton(
            onPressed: () => controller.autoPick(),
            child: const Text('Force CPU Pick'),
          ),
        if (canTrade) ...[
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () async {
              final result = await showModalBottomSheet<TradeSheetResult>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    TradeSheet(
                      state: state,
                      userTeams: widget.controlledTeams,
                    ),
              );
              if (result == null) return;

              final pick = state.currentPick!;
              final offer = TradeOffer(
                fromTeam: result.partnerTeam,
                toTeam: result.userTeam,
                fromAssets: result.partnerAssets,
                toAssets: result.userAssets,
              );

              final ok = controller.proposeTrade(offer);
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Trade accepted' : 'Trade rejected'),
                ),
              );
            },
            child: const Text('Trade'),
          ),
        ],
      ],
    );
  }
}
