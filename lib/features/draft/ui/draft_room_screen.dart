import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../logic/draft_controller.dart';
import '../logic/draft_speed.dart';
import '../logic/draft_state.dart';
import '../models/trade.dart';
import '../models/prospect.dart';
import '../models/draft_pick.dart';
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
    required this.speedPreset,
    required this.tradeFrequency,
    required this.tradeStrictness,
  });

  final int year;
  final List<String> controlledTeams;
  final bool resume;
  final DraftSpeedPreset speedPreset;
  final double tradeFrequency;
  final double tradeStrictness;

  @override
  ConsumerState<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends ConsumerState<DraftRoomScreen> {
  String search = '';
  String? positionFilter;
  String? pickLogTeamFilter; // null = All Teams
  bool _pickLogInitialized = false;
  bool _bootstrapped = false;
  bool recapCollapsed = false;
  final ScrollController _pickLogScroll = ScrollController();
  int _lastPickCount = 0;
  bool _tradeDialogOpen = false;
  String? _lastTradeOfferId;
  bool _resumeAfterTradeDialog = false;
  final GlobalKey _lastPickTileKey = GlobalKey();
  String? _lastPickFocusId;
  late double _tradeFrequency;
  late double _tradeStrictness;
  bool _showedDraftComplete = false;
  bool _listenersBound = false;

  @override
  void initState() {
    super.initState();
    _tradeFrequency = widget.tradeFrequency;
    _tradeStrictness = widget.tradeStrictness;

    // Avoid Riverpod provider mutation during build/lifecycle.
    Future.microtask(() async {
      if (!mounted || _bootstrapped) return;
      _bootstrapped = true;

      final controller = ref.read(draftControllerProvider.notifier);
      controller.setTradeSettings(
        frequency: _tradeFrequency,
        strictness: _tradeStrictness,
      );

      if (widget.resume) {
        await controller.resumeSavedDraft(widget.year);
        controller.setSpeedPreset(widget.speedPreset);
      } else {
        controller.start(
          year: widget.year,
          userTeams: widget.controlledTeams
              .map((e) => e.toUpperCase())
              .toList(),
          speedPreset: widget.speedPreset,
        );
      }
    });
  }

  @override
  void dispose() {
    _pickLogScroll.dispose();
    super.dispose();
  }

  Future<bool?> _showTradeOfferDialog(
    BuildContext context,
    TradeOffer offer,
  ) {
    final teamColors = _teamColorMap(ref.read(draftControllerProvider));
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Trade Offer'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${offer.fromTeam} offers',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _readableTeamColor(
                      teamColors[offer.fromTeam.toUpperCase()] ??
                          AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...offer.fromAssets.map((a) => Text('• ${_assetLabel(a)}')),
                const SizedBox(height: 12),
                Text(
                  'In exchange for ${offer.toTeam}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _readableTeamColor(
                      teamColors[offer.toTeam.toUpperCase()] ??
                          AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...offer.toAssets.map((a) => Text('• ${_assetLabel(a)}')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  String _assetLabel(TradeAsset asset) {
    final pick = asset.pick;
    if (pick != null) {
      return 'Pick ${pick.pickOverall} (R${pick.round}.${pick.pickInRound}) • ${pick.teamAbbr}';
    }
    final future = asset.futurePick!;
    return '${future.year} Round ${future.round} • ${future.teamAbbr}';
  }

  Widget _tradeInboxButton(DraftState state) {
    final count = state.tradeInbox.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconPill(
          icon: Icons.swap_horiz,
          tooltip: 'Trade Inbox',
          onPressed: count == 0
              ? null
              : () => _showTradeInboxSheet(context, state),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showTradeInboxSheet(
    BuildContext context,
    DraftState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final current = ref.watch(draftControllerProvider);
            final controller = ref.read(draftControllerProvider.notifier);
            final teamColors = _teamColorMap(current);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Trade Center',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Panel(
                      padding: const EdgeInsets.all(12),
                      child: _tradeSettingsSection(controller),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Inbox (${current.tradeInbox.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (current.tradeInbox.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No pending trade offers.'),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: current.tradeInbox.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 16),
                          itemBuilder: (context, i) {
                            final offer = current.tradeInbox[i];
                            return Panel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${offer.fromTeam} offers',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _readableTeamColor(
                                        teamColors[
                                                offer.fromTeam.toUpperCase()] ??
                                            AppColors.text,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...offer.fromAssets
                                      .map((a) => Text('• ${_assetLabel(a)}')),
                                  const SizedBox(height: 10),
                                  Text(
                                    'In exchange for ${offer.toTeam}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _readableTeamColor(
                                        teamColors[
                                                offer.toTeam.toUpperCase()] ??
                                            AppColors.text,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...offer.toAssets
                                      .map((a) => Text('• ${_assetLabel(a)}')),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            controller.declineTradeOffer(offer);
                                          },
                                          child: const Text('Decline'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () {
                                            controller.acceptIncomingTrade(
                                              offer,
                                            );
                                          },
                                          child: const Text('Accept'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tradeSettingsSection(DraftController controller) {
    final freqOptions = const [
      ('Low', 0.12),
      ('Normal', 0.22),
      ('High', 0.35),
    ];
    final strictOptions = const [
      ('Lenient', -0.03),
      ('Normal', 0.0),
      ('Strict', 0.04),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trade Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Frequency:'),
            const SizedBox(width: 12),
            DropdownButton<double>(
              value: _tradeFrequency,
              items: freqOptions
                  .map(
                    (o) => DropdownMenuItem<double>(
                      value: o.$2,
                      child: Text(o.$1),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _tradeFrequency = v);
                controller.setTradeSettings(frequency: v);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Strictness:'),
            const SizedBox(width: 12),
            DropdownButton<double>(
              value: _tradeStrictness,
              items: strictOptions
                  .map(
                    (o) => DropdownMenuItem<double>(
                      value: o.$2,
                      child: Text(o.$1),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _tradeStrictness = v);
                controller.setTradeSettings(strictness: v);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftControllerProvider);
    final controller = ref.read(draftControllerProvider.notifier);
    _bindListeners();
    _maybeShowDraftCompletePrompt(state);

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
                onPressed: null, // handled by PopupMenuButton
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

          _tradeInboxButton(state),

          IconPill(
            icon: Icons.exit_to_app,
            tooltip: 'Exit',
            onPressed: () => _confirmExit(context),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(state.error!),
                ),
              )
            : _content(context, state),
      ),
    );
  }

  void _bindListeners() {
    if (_listenersBound) return;
    _listenersBound = true;
    _listenForTradeOffers();
    _listenForCpuTradeLogs();
  }

  void _maybeShowDraftCompletePrompt(DraftState state) {
    if (_showedDraftComplete) return;
    if (!state.isComplete || !mounted) return;
    _showedDraftComplete = true;
    Future.microtask(() async {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Draft Complete'),
          content: const Text('View your draft recap and grades?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('View Recap'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        context.goNamed('recap');
      }
    });
  }

  void _listenForTradeOffers() {
    ref.listen<DraftState>(draftControllerProvider, (prev, next) {
      final offer = next.pendingTrade;
      if (offer == null) return;
      final id = offer.id ??
          '${offer.fromTeam}_${offer.toTeam}_${offer.fromAssets.length}_${offer.toAssets.length}';
      if (_tradeDialogOpen || _lastTradeOfferId == id) return;

      _lastTradeOfferId = id;
      _tradeDialogOpen = true;

      final controller = ref.read(draftControllerProvider.notifier);
      if (next.clockRunning) {
        _resumeAfterTradeDialog = true;
        controller.pauseClock();
      } else {
        _resumeAfterTradeDialog = false;
      }

      Future.microtask(() async {
        if (!mounted) return;
        final accepted = await _showTradeOfferDialog(context, offer);
        if (!mounted) return;
        if (accepted == true) {
          final ok = controller.acceptIncomingTrade(offer);
          if (!ok) controller.declinePendingTrade();
        } else {
          controller.declinePendingTrade();
        }
        if (_resumeAfterTradeDialog && mounted) {
          controller.resumeClock();
        }
        _tradeDialogOpen = false;
      });
    });
  }

  void _listenForCpuTradeLogs() {
    ref.listen<DraftState>(draftControllerProvider, (prev, next) {
      if (prev == null) return;
      if (next.tradeLogVersion == prev.tradeLogVersion) return;
      final message =
          next.tradeLog.isNotEmpty ? next.tradeLog.last.summary : null;
      if (message == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
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
    final teamColors = _teamColorMap(state);

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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final college = (p.college ?? '').trim();
                  final subtitle = isNarrow
                      ? [
                          p.position.toUpperCase(),
                          if (college.isNotEmpty) college,
                        ].join(' • ')
                      : college;

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
                        if (!isNarrow) ...[
                          const SizedBox(width: 8),
                          _posPill(p.position),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    // Keep the call-to-action compact so the player name doesn't get squeezed
                    // on smaller screens.
                    trailing: canPick
                        ? (isNarrow
                            ? FilledButton(
                                onPressed: () => controller.draftProspect(p),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.blue,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '+',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () => controller.draftProspect(p),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Draft'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.blue,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ))
                        : null,
                  );
                },
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
    final teamColors = _teamColorMap(state);
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

    // Default to the first user-controlled team only once.
    if (!_pickLogInitialized &&
        pickLogTeamFilter == null &&
        userTeams.isNotEmpty) {
      Future.microtask(() {
        if (!mounted) return;
        setState(() {
          pickLogTeamFilter = userTeams.first;
          _pickLogInitialized = true;
        });
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

    final recapRows = selectedTeam == null
        ? _buildRecapRowsAll(state)
        : _buildRecapRows(state, selectedTeam);

    // Slightly reorder picks for filtered view: by pick overall.
    if (selectedTeam != null) {
      recapRows.sort((a, b) => a.pick.pickOverall.compareTo(b.pick.pickOverall));
    }

    if (selectedTeam == null) {
      if (picks.length > _lastPickCount) {
        _lastPickCount = picks.length;
        final lastMade = state.picksMade.isNotEmpty
            ? state.picksMade.last.pick
            : null;
        final focusId = lastMade == null ? null : _pickKey(lastMade);
        if (focusId != null && focusId != _lastPickFocusId) {
          _lastPickFocusId = focusId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final ctx = _lastPickTileKey.currentContext;
            if (ctx == null) return;
            Scrollable.ensureVisible(
              ctx,
              alignment: 1.0,
              duration: const Duration(milliseconds: 200),
            );
          });
        }
      }
    } else {
      _lastPickCount = picks.length;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
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
                      child: Text(
                        '$abbr ($c)',
                        style: TextStyle(
                          color: _readableTeamColor(
                            teamColors[abbr] ?? AppColors.text,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ],
                    onChanged: (v) => setState(() {
                      pickLogTeamFilter = v;
                      _pickLogInitialized = true;
                    }),
                  ),
                ),
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
            child: recapRows.isEmpty
                ? const Center(child: Text('No picks yet.'))
                : ListView.separated(
                    controller: _pickLogScroll,
                    itemCount: recapRows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final row = recapRows[i];
                      final pick = row.pick;
                      final prospect = row.prospect;
                      final detail = prospect == null
                          ? 'Upcoming pick'
                          : '${prospect.position}${(prospect.college == null || prospect.college!.isEmpty) ? '' : ' • ${prospect.college}'}';
                      final via = _viaLabel(pick);

                      final key = selectedTeam == null &&
                              _lastPickFocusId == _pickKey(pick)
                          ? _lastPickTileKey
                          : ValueKey('pick-${_pickKey(pick)}');
                      final teamColor = _readableTeamColor(
                        teamColors[pick.teamAbbr.toUpperCase()] ??
                            AppColors.textMuted,
                      );
                      return ListTile(
                        key: key,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          prospect?.name ?? 'Pick ${pick.pickOverall}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: prospect == null
                                ? AppColors.textMuted
                                : AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          '${pick.pickOverall}. ${pick.teamAbbr}  •  R${pick.round}.${pick.pickInRound.toString().padLeft(2, '0')}$via  •  $detail',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: teamColor),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  List<_RecapRow> _buildRecapRows(DraftState state, String selectedTeam) {
    final made = state.picksMade
        .where((p) => p.teamAbbr == selectedTeam)
        .toList();
    final madeKeys = made.map((p) => _pickKey(p.pick)).toSet();

    final upcoming = state.order
        .where((p) => p.teamAbbr == selectedTeam)
        .where((p) => !madeKeys.contains(_pickKey(p)))
        .toList();

    return [
      ...made.map(
        (p) => _RecapRow(
          pick: p.pick,
          prospect: p.prospect,
        ),
      ),
      ...upcoming.map(
        (p) => _RecapRow(
          pick: p,
          prospect: null,
        ),
      ),
    ];
  }

  List<_RecapRow> _buildRecapRowsAll(DraftState state) {
    final madeByPick = <String, PickResult>{};
    for (final pr in state.picksMade) {
      madeByPick[_pickKey(pr.pick)] = pr;
    }

    final rows = <_RecapRow>[];
    for (final pick in state.order) {
      final pr = madeByPick[_pickKey(pick)];
      rows.add(_RecapRow(pick: pick, prospect: pr?.prospect));
    }
    return rows;
  }

  String _pickKey(DraftPick pick) {
    return '${pick.year}-${pick.round}-${pick.pickOverall}-${pick.pickInRound}';
  }

  String _viaLabel(DraftPick pick) {
    final original = pick.originalTeamAbbr.toUpperCase();
    final current = pick.teamAbbr.toUpperCase();
    if (original.isEmpty || original == current) return '';
    return ' • via $original';
  }

  Map<String, Color> _teamColorMap(DraftState state) {
    final map = <String, Color>{};
    for (final t in state.teams) {
      final abbr = t.abbreviation.toUpperCase();
      final color = _parseTeamColor(t.colors);
      if (color != null) {
        map[abbr] = color;
      }
    }
    map['CHI'] = const Color(0xFFC83803);
    return map;
  }

  Color? _parseTeamColor(List<String>? colors) {
    if (colors == null || colors.isEmpty) return null;
    for (final raw in colors) {
      final c = _parseColorString(raw);
      if (c != null) return c;
    }
    return null;
  }

  Color? _parseColorString(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('0x')) {
      value = value.substring(2);
    }
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    if (value.length != 8) return null;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  Color _readableTeamColor(Color color) {
    if (color.computeLuminance() >= 0.45) return color;
    return Color.lerp(color, Colors.white, 0.4) ?? color;
  }

  Widget _onClockFooter(DraftState state) {
    final controller = ref.read(draftControllerProvider.notifier);
    final teamColors = _teamColorMap(state);

    final canTrade = !state.isComplete && state.currentPick != null;
    final canRun = !state.isUserOnClock && !state.isComplete;

    return Row(
      children: [
        Expanded(
          child: state.isComplete
              ? const Text(
                  'Draft complete',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted),
                )
              : RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.textMuted),
                    children: [
                      const TextSpan(text: 'On the clock: '),
                      TextSpan(
                        text: state.onClockTeam,
                        style: TextStyle(
                          color: _readableTeamColor(
                            teamColors[state.onClockTeam] ?? AppColors.text,
                          ),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' • ${state.currentPick?.label}',
                      ),
                    ],
                  ),
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

class _RecapRow {
  final DraftPick pick;
  final Prospect? prospect;

  const _RecapRow({
    required this.pick,
    required this.prospect,
  });
}
