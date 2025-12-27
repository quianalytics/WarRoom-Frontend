import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/challenges/draft_challenges.dart';
import '../logic/draft_controller.dart';
import '../logic/draft_speed.dart';
import '../logic/draft_state.dart';
import '../models/trade.dart';
import '../models/prospect.dart';
import '../models/draft_pick.dart';
import '../models/team.dart';
import 'widgets/trade_sheet.dart';
import '../../../ui/icon_pill.dart';
import '../../../ui/panel.dart';
import '../../../ui/pick_card.dart';
import '../../../ui/war_room_background.dart';
import '../../../ui/staggered_reveal.dart';
import '../../../ui/section_frame.dart';
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
    this.resumeId,
    this.resumePick,
  });

  final int year;
  final List<String> controlledTeams;
  final bool resume;
  final DraftSpeedPreset speedPreset;
  final double tradeFrequency;
  final double tradeStrictness;
  final String? resumeId;
  final int? resumePick;

  @override
  ConsumerState<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

enum _ExitAction { cancel, exit, save }

class _TradeHeatTeam {
  const _TradeHeatTeam({
    required this.teamAbbr,
    required this.nextPickOverall,
    required this.upScore,
    required this.downScore,
  });

  final String teamAbbr;
  final int nextPickOverall;
  final double upScore;
  final double downScore;
}

class _DraftRoomScreenState extends ConsumerState<DraftRoomScreen>
    with SingleTickerProviderStateMixin {
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
  int _lastTradeLogCount = 0;
  bool _listenersBound = false;
  bool _tradeTickerVisible = false;
  final List<String> _tradeTickerQueue = [];
  String? _tradeTickerCurrent;
  int _tradeTickerToken = 0;
  late final AnimationController _shimmerController;
  int _lastPickSoundCount = 0;
  bool _soundHapticsEnabled = true;
  bool _tradePopupsEnabled = true;
  final Set<String> _tradeBaitIds = {};
  StreamSubscription<Set<String>>? _badgeSubscription;

  @override
  void initState() {
    super.initState();
    _tradeFrequency = widget.tradeFrequency;
    _tradeStrictness = widget.tradeStrictness;
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadSoundSettings();
    _listenForBadgeToasts();

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
        if (widget.resumeId != null && widget.resumeId!.isNotEmpty) {
          await controller.resumeSavedDraftById(
            widget.resumeId!,
            resumePick: widget.resumePick,
          );
        } else {
          await controller.resumeSavedDraft(
            widget.year,
            resumePick: widget.resumePick,
          );
        }
        controller.setSpeedPreset(widget.speedPreset);
      } else {
        controller.start(
          year: widget.year,
          userTeams: widget.controlledTeams
              .map((e) => e.toUpperCase())
              .toList(),
          speedPreset: widget.speedPreset,
          saveDraft: false,
        );
      }
    });
  }

  Future<void> _loadSoundSettings() async {
    final enabled = await LocalStore.getSoundHapticsEnabled();
    final tradePopups = await LocalStore.getTradePopupsEnabled();
    if (!mounted) return;
    setState(() {
      _soundHapticsEnabled = enabled;
      _tradePopupsEnabled = tradePopups;
    });
  }

  @override
  void dispose() {
    _pickLogScroll.dispose();
    _shimmerController.dispose();
    _badgeSubscription?.cancel();
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
                ...offer.fromAssets.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _assetCard(a, teamColors),
                  ),
                ),
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
                ...offer.toAssets.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _assetCard(a, teamColors),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Ignore'),
            ),
            OutlinedButton(
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

  Widget _assetCard(TradeAsset asset, Map<String, Color> teamColors) {
    final pick = asset.pick;
    final teamAbbr =
        pick?.teamAbbr.toUpperCase() ?? asset.futurePick!.teamAbbr.toUpperCase();
    final glow = teamColors[teamAbbr] ?? AppColors.blue;
    return PickCard(
      glowColor: glow,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        _assetLabel(asset),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _tradeInboxButton(DraftState state) {
    final count = state.tradeInbox.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconPill(
          icon: Icons.swap_horiz,
          tooltip: 'Trade Inbox',
          onPressed: () => _showTradeInboxSheet(context, state),
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

  Widget _draftHqButton(DraftState state) {
    return IconPill(
      icon: Icons.insights,
      tooltip: 'Draft HQ',
      onPressed: () => _showDraftHqSheet(context),
    );
  }

  Future<void> _showDraftHqSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final current = ref.watch(draftControllerProvider);
            final teamColors = _teamColorMap(current);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              minChildSize: 0.55,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        const SliverToBoxAdapter(
                          child: Text(
                            'Draft HQ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'User Team Needs',
                            child: _userNeedsSection(current, teamColors),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'User Needs Heat',
                            child: _userNeedsHeatSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'BPA vs Need',
                            child: _bpaVsNeedSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Run Predictor',
                            child: _runPredictorSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Trade Market Heat Map',
                            child: _tradeMarketHeatSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Draft Board Optimizer',
                            child: _draftBoardOptimizerSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Trade Bait',
                            child: _tradeBaitSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Reach / Steal Alerts',
                            child: _reachStealSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Trade Value Deltas',
                            child: _tradeDeltaSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Next User Pick',
                            child: _nextPickSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
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
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        const SliverToBoxAdapter(
                          child: Text(
                            'Trade Center',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: Panel(
                            padding: const EdgeInsets.all(12),
                            child: _tradeSettingsSection(controller),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionFrame(
                            title: 'Trade Market',
                            child: _tradeMarketSection(current),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            text: 'Inbox (${current.tradeInbox.length})',
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 8),
                        ),
                        if (current.tradeInbox.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('No pending trade offers.'),
                            ),
                          )
                        else
                          SliverList.separated(
                            itemCount: current.tradeInbox.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final offer = current.tradeInbox[i];
                              return SectionFrame(
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
                                    ...offer.fromAssets.map(
                                      (a) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: _assetCard(a, teamColors),
                                      ),
                                    ),
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
                                    ...offer.toAssets.map(
                                      (a) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: _assetCard(a, teamColors),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              controller.declineTradeOffer(
                                                offer,
                                              );
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
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
            const Expanded(child: Text('Trade Popups')),
            Switch(
              value: _tradePopupsEnabled,
              onChanged: (v) async {
                setState(() => _tradePopupsEnabled = v);
                await LocalStore.setTradePopupsEnabled(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
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

  Team? _teamByAbbr(DraftState state, String abbr) {
    final u = abbr.toUpperCase();
    for (final team in state.teams) {
      if (team.abbreviation.toUpperCase() == u ||
          team.teamId.toUpperCase() == u) {
        return team;
      }
    }
    return null;
  }

  Widget _userNeedsSection(
    DraftState state,
    Map<String, Color> teamColors,
  ) {
    if (state.userTeams.isEmpty) {
      return const Text('No user-controlled teams selected.');
    }
    final teams = state.userTeams
        .map((abbr) => _teamByAbbr(state, abbr))
        .whereType<Team>()
        .toList();
    if (teams.isEmpty) {
      return const Text('No needs data available.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final team in teams) ...[
          Text(
            team.abbreviation.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _readableTeamColor(
                teamColors[team.abbreviation.toUpperCase()] ?? AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if ((team.needs ?? const <String>[]).isEmpty)
            const Text('No needs data available.')
          else
            _needsChips(team.needs!),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _userNeedsHeatSection(DraftState state) {
    final counts = <String, int>{};
    for (final abbr in state.userTeams) {
      final team = _teamByAbbr(state, abbr);
      final needs = team?.needs ?? const <String>[];
      for (final need in needs) {
        final key = need.toUpperCase();
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const Text('No needs data for user teams.');
    }
    final pills = entries
        .take(6)
        .map((e) => _marketPill('${e.key} x${e.value}'))
        .toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pills,
    );
  }

  Widget _nextPickSection(DraftState state) {
    final gap = _nextUserPickGap(state);
    if (gap == null) {
      return const Text('No upcoming user pick.');
    }
    final label = gap == 0 ? 'On the clock' : '+$gap picks';
    return Row(
      children: [
        _marketPill('Next user pick: $label'),
      ],
    );
  }

  Widget _needsChips(List<String> needs) {
    final chips = needs.map((need) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          need.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _bpaVsNeedSection(DraftState state) {
    final pick = _nextUserPick(state);
    if (pick == null) {
      return const Text('No upcoming user picks.');
    }
    final team = _teamByAbbr(state, pick.teamAbbr);
    final needs = team?.needs ?? const <String>[];
    final ranked = [...state.availableProspects]
      ..sort((a, b) {
        final ar = a.rank ?? 999999;
        final br = b.rank ?? 999999;
        return ar.compareTo(br);
      });
    if (ranked.isEmpty) {
      return const Text('No prospects available.');
    }
    final bpa = ranked.first;
    final needMatch = needs.isEmpty
        ? null
        : ranked.firstWhere(
            (p) => needs.contains(p.position.toUpperCase()),
            orElse: () => bpa,
          );
    final bpaRank = bpa.rank ?? 999999;
    final needRank = needMatch?.rank ?? 999999;
    final delta = needRank - bpaRank;
    final label = needs.isEmpty
        ? 'No needs data for ${pick.teamAbbr.toUpperCase()}'
        : delta == 0
        ? 'Need match equals BPA'
        : delta > 0
        ? 'Need match is +$delta ranks from BPA'
        : 'Need match is ${delta.abs()} ranks better than BPA';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BPA: ${bpa.name} (${bpa.position}) • #$bpaRank',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        if (needs.isEmpty)
          const Text('No needs data available for this team.')
        else
          Text(
            'Best need: ${needMatch?.name ?? '—'} (${needMatch?.position ?? '-'}) • #$needRank',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        const SizedBox(height: 8),
        Text(label),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: needs.isEmpty
              ? 0.5
              : (1 / (1 + (delta.abs() / 8))).clamp(0.15, 1.0),
          backgroundColor: AppColors.surface2,
          valueColor: AlwaysStoppedAnimation<Color>(
            delta <= 4 ? AppColors.blue : AppColors.textMuted,
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _runPredictorSection(DraftState state) {
    final recent = state.picksMade.reversed.take(6).toList();
    if (recent.length < 3) {
      return const Text('Not enough picks yet to detect runs.');
    }
    final counts = <String, int>{};
    for (final pr in recent) {
      final pos = pr.prospect.position.toUpperCase();
      counts[pos] = (counts[pos] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hottest = entries.first;
    final confidence = (hottest.value / recent.length).clamp(0.2, 1.0);
    final hotLabel = hottest.value >= 3
        ? 'Hot: ${hottest.key} (${hottest.value}/${recent.length})'
        : 'No strong run detected';

    final needs = state.userTeams
        .map((abbr) => _teamByAbbr(state, abbr))
        .whereType<Team>()
        .expand((t) => t.needs ?? const <String>[])
        .map((n) => n.toUpperCase())
        .toList();
    final needMatches = needs.toSet();
    final warning = needMatches.contains(hottest.key) && hottest.value >= 3
        ? 'Watch out: your needs overlap with the hottest run.'
        : 'Runs look stable for your needs.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _marketPill(hotLabel),
        const SizedBox(height: 8),
        Text(
          warning,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 8,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  hottest.value >= 3 ? AppColors.blue : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(confidence * 100).round()}%'),
          ],
        ),
      ],
    );
  }

  Widget _tradeMarketHeatSection(DraftState state) {
    final currentPick = state.currentPick?.pickOverall ?? 1;
    final prospects = [...state.availableProspects]
      ..sort((a, b) {
        final ar = a.rank ?? 999999;
        final br = b.rank ?? 999999;
        return ar.compareTo(br);
      });
    final topProspects = prospects.take(40).toList();
    if (topProspects.isEmpty || state.order.isEmpty) {
      return const Text('No trade heat data available yet.');
    }

    final heat = <_TradeHeatTeam>[];
    for (final team in state.teams) {
      final needs = team.needs ?? const <String>[];
      if (needs.isEmpty) continue;
      DraftPick? nextPick;
      for (final pick in state.order) {
        if (pick.pickOverall < currentPick) continue;
        if (pick.teamAbbr.toUpperCase() == team.abbreviation.toUpperCase()) {
          nextPick = pick;
          break;
        }
      }
      if (nextPick == null) continue;
      final needMatches = topProspects
          .where((p) => needs.contains(p.position.toUpperCase()))
          .toList();
      if (needMatches.isEmpty) continue;
      final demand = max(1, needMatches.length);
      final supplyBeforePick = needMatches
          .where((p) => (p.rank ?? 999999) <= nextPick!.pickOverall)
          .length;
      final distanceFactor =
          ((nextPick.pickOverall - currentPick) / 20).clamp(0.0, 1.0);
      final scarcity = 1 - (supplyBeforePick / demand);
      final upScore = (scarcity * 0.7 + distanceFactor * 0.3).clamp(0.0, 1.0);

      final abundance = (supplyBeforePick / demand).clamp(0.0, 1.0);
      final earlyFactor =
          (1 - ((nextPick.pickOverall - currentPick) / 12).clamp(0.0, 1.0))
              .clamp(0.0, 1.0);
      final picksSoon = state.order
          .where((p) =>
              p.pickOverall >= currentPick &&
              p.pickOverall <= currentPick + 20 &&
              p.teamAbbr.toUpperCase() == team.abbreviation.toUpperCase())
          .length;
      final extra = picksSoon >= 2 ? 0.15 : 0.0;
      final downScore =
          (abundance * 0.6 + earlyFactor * 0.3 + extra).clamp(0.0, 1.0);

      heat.add(
        _TradeHeatTeam(
          teamAbbr: team.abbreviation.toUpperCase(),
          nextPickOverall: nextPick.pickOverall,
          upScore: upScore,
          downScore: downScore,
        ),
      );
    }

    if (heat.isEmpty) {
      return const Text('No trade heat data available yet.');
    }

    final teamColors = _teamColorMap(state);
    final upTeams = [...heat]
      ..sort((a, b) => b.upScore.compareTo(a.upScore));
    final downTeams = [...heat]
      ..sort((a, b) => b.downScore.compareTo(a.downScore));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Likely to Trade Up',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: upTeams.take(6).map((team) {
            final color = teamColors[team.teamAbbr] ?? AppColors.blue;
            return _heatPill(
              '${team.teamAbbr} ↑ P${team.nextPickOverall}',
              team.upScore,
              color,
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const Text(
          'Likely to Trade Down',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: downTeams.take(6).map((team) {
            final color = teamColors[team.teamAbbr] ?? AppColors.mint;
            return _heatPill(
              '${team.teamAbbr} ↓ P${team.nextPickOverall}',
              team.downScore,
              color,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _draftBoardOptimizerSection(DraftState state) {
    final pick = _nextUserPick(state);
    if (pick == null) {
      return const Text('No upcoming user picks.');
    }
    final team = _teamByAbbr(state, pick.teamAbbr);
    final needs = team?.needs ?? const <String>[];
    final ranked = [...state.availableProspects]
      ..sort((a, b) {
        final ar = a.rank ?? 999999;
        final br = b.rank ?? 999999;
        return ar.compareTo(br);
      });
    if (ranked.isEmpty) {
      return const Text('No prospects available.');
    }
    final bpa = ranked.first;
    final bestNeed = needs.isEmpty
        ? null
        : ranked.firstWhere(
            (p) => needs.contains(p.position.toUpperCase()),
            orElse: () => bpa,
          );
    final pickOverall = pick.pickOverall;
    final bpaRank = bpa.rank ?? pickOverall;
    final needRank = bestNeed?.rank ?? pickOverall;
    final gapToBpa = pickOverall - bpaRank;
    final gapToNeed = pickOverall - needRank;
    final onClock = state.currentPick?.pickOverall == pickOverall;

    String headline;
    String detail;
    if (needs.isEmpty) {
      headline = 'Hold: BPA is the cleanest value.';
      detail =
          'BPA ${bpa.name} (${bpa.position}) is ranked #$bpaRank for Pick $pickOverall.';
    } else if (bestNeed == bpa) {
      headline = 'BPA aligns with a top need.';
      detail =
          '${bpa.position} fits ${pick.teamAbbr.toUpperCase()} and is ranked #$bpaRank.';
    } else if (gapToBpa <= -6) {
      final target = max(1, pickOverall - gapToBpa.abs());
      headline = 'Consider trading up.';
      detail =
          'BPA ${bpa.name} is ranked #$bpaRank; target Pick ~$target to secure him.';
    } else if (gapToNeed >= 8) {
      headline = 'Consider trading down.';
      detail =
          'Best need (${bestNeed?.position}) is ranked #$needRank; likely available later.';
    } else {
      headline = 'Hold and stay flexible.';
      detail =
          'BPA is #$bpaRank; best need is #$needRank for Pick $pickOverall.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _marketPill(
              onClock ? 'On the clock' : 'Next pick: P$pickOverall',
            ),
            const SizedBox(width: 8),
            _marketPill(pick.teamAbbr.toUpperCase()),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          headline,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _tradeBaitSection(DraftState state) {
    if (_tradeBaitIds.isEmpty) {
      return const Text('No trade bait selected yet.');
    }
    final byId = {
      for (final p in state.availableProspects) p.id: p,
    };
    final picks = _tradeBaitIds
        .map((id) => byId[id])
        .whereType<Prospect>()
        .toList()
      ..sort((a, b) {
        final ar = a.rank ?? 999999;
        final br = b.rank ?? 999999;
        return ar.compareTo(br);
      });
    if (picks.isEmpty) {
      return const Text('Trade bait left the board.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...picks.take(5).map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• ${p.name} (${p.position})${p.rank == null ? '' : ' • #${p.rank}'}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reachStealSection(DraftState state) {
    final userTeams = state.userTeams.map((t) => t.toUpperCase()).toSet();
    final recent = state.picksMade
        .where((p) => userTeams.contains(p.teamAbbr.toUpperCase()))
        .toList()
        .reversed
        .take(8)
        .toList();
    if (recent.isEmpty) {
      return const Text('No user picks yet.');
    }
    final alerts = recent
        .where((p) => p.prospect.rank != null)
        .map((p) {
          final rank = p.prospect.rank!;
          final overall = p.pick.pickOverall;
          final delta = overall - rank;
          final label = delta >= 10
              ? 'Steal'
              : delta <= -10
              ? 'Reach'
              : null;
          return (p, delta, label);
        })
        .where((t) => t.$3 != null)
        .toList();
    if (alerts.isEmpty) {
      return const Text('No reach/steal alerts for user picks.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alerts.map((t) {
        final pr = t.$1;
        final delta = t.$2;
        final label = t.$3!;
        final color = label == 'Steal' ? AppColors.blue : AppColors.textMuted;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              _marketPill(label, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pr.prospect.name} (${pr.prospect.position}) • Pick ${pr.pick.pickOverall} • Rank #${pr.prospect.rank}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                delta >= 0 ? '+$delta' : '$delta',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _tradeDeltaSection(DraftState state) {
    final userTeams = state.userTeams.map((t) => t.toUpperCase()).toSet();
    final allOffers = <TradeOffer>[
      ...state.tradeInbox,
      if (state.pendingTrade != null) state.pendingTrade!,
    ];
    final dedupedActiveOffers = _dedupeOffers(allOffers);
    final userOffers = allOffers.where(
      (o) =>
          userTeams.contains(o.fromTeam.toUpperCase()) ||
          userTeams.contains(o.toTeam.toUpperCase()),
    ).toList();
    final accepted = _dedupeOffers(state.tradeLog.map(_tradeLogToOffer).toList());
    final acceptedUser = accepted.where(
      (o) =>
          userTeams.contains(o.fromTeam.toUpperCase()) ||
          userTeams.contains(o.toTeam.toUpperCase()),
    ).toList();
    if (userOffers.isEmpty && acceptedUser.isEmpty) {
      return const Text('No user trade offers to analyze.');
    }

    final activeOffers = _dedupeOffers(userOffers);
    final acceptedOffers = acceptedUser;

    final activeEntries = activeOffers.take(3).map((offer) {
      final perspective = _tradeDeltaPerspective(offer, userTeams);
      final delta = _tradeValueDeltaFor(
        offer,
        state.year,
        perspective,
      );
      final label = delta >= 0
          ? '+${delta.toStringAsFixed(0)}'
          : delta.toStringAsFixed(0);
      final color = delta >= 0 ? AppColors.blue : AppColors.textMuted;
      final details = _tradeDetails(offer);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${offer.fromTeam} → ${offer.toTeam} (${perspective ?? '—'})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }).toList();
    final acceptedEntries = acceptedOffers.take(3).map((offer) {
      final perspective = _tradeDeltaPerspective(offer, userTeams);
      final delta = _tradeValueDeltaFor(
        offer,
        state.year,
        perspective,
      );
      final label = delta >= 0
          ? '+${delta.toStringAsFixed(0)}'
          : delta.toStringAsFixed(0);
      final color = delta >= 0 ? AppColors.blue : AppColors.textMuted;
      final details = _tradeDetails(offer);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${offer.fromTeam} → ${offer.toTeam} (${perspective ?? '—'})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeEntries.isNotEmpty) ...[
          Text(
            'Active offers (user team POV)',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...activeEntries.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: row,
            ),
          ),
        ],
        if (acceptedEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Accepted trades (user team POV)',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...acceptedEntries.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: row,
            ),
          ),
        ],
      ],
    );
  }

  DraftPick? _nextUserPick(DraftState state) {
    if (state.userTeams.isEmpty) return null;
    for (var i = state.currentIndex; i < state.order.length; i++) {
      final pick = state.order[i];
      if (state.userTeams.contains(pick.teamAbbr.toUpperCase())) {
        return pick;
      }
    }
    return null;
  }

  String? _tradeDeltaPerspective(
    TradeOffer offer,
    Set<String> userTeams,
  ) {
    final from = offer.fromTeam.toUpperCase();
    final to = offer.toTeam.toUpperCase();
    if (userTeams.contains(to)) return to;
    if (userTeams.contains(from)) return from;
    return null;
  }

  double _tradeValueDeltaFor(
    TradeOffer offer,
    int year,
    String? perspectiveTeam,
  ) {
    final give = _tradeAssetsValue(offer.toAssets, year);
    final get = _tradeAssetsValue(offer.fromAssets, year);
    if (perspectiveTeam == null) return get - give;
    final from = offer.fromTeam.toUpperCase();
    final to = offer.toTeam.toUpperCase();
    if (perspectiveTeam == to) {
      return get - give; // toTeam receives fromAssets
    }
    if (perspectiveTeam == from) {
      return give - get; // fromTeam receives toAssets
    }
    return get - give;
  }

  double _tradeAssetsValue(List<TradeAsset> assets, int year) {
    return assets.fold<double>(0, (sum, a) => sum + _assetValue(a, year));
  }

  List<TradeOffer> _dedupeOffers(List<TradeOffer> offers) {
    final seen = <String>{};
    final unique = <TradeOffer>[];
    for (final offer in offers) {
      final key = _offerKey(offer);
      if (seen.add(key)) {
        unique.add(offer);
      }
    }
    return unique;
  }

  String _offerKey(TradeOffer offer) {
    final from = offer.fromTeam.toUpperCase();
    final to = offer.toTeam.toUpperCase();
    final fromAssets = offer.fromAssets
        .map(_assetShortLabel)
        .join(',');
    final toAssets = offer.toAssets
        .map(_assetShortLabel)
        .join(',');
    return '$from|$to|$fromAssets|$toAssets';
  }

  String _tradeDetails(TradeOffer offer) {
    if (offer.fromAssets.isEmpty && offer.toAssets.isEmpty) return '';
    final from = offer.fromAssets.map(_assetShortLabel).join(', ');
    final to = offer.toAssets.map(_assetShortLabel).join(', ');
    if (from.isEmpty && to.isEmpty) return '';
    return '$from for $to';
  }

  String _assetShortLabel(TradeAsset asset) {
    final pick = asset.pick;
    if (pick != null) {
      return 'P${pick.pickOverall}';
    }
    final future = asset.futurePick!;
    return '${future.year} R${future.round}';
  }

  TradeOffer _tradeLogToOffer(TradeLogEntry entry) {
    final from = entry.fromTeam;
    final to = entry.toTeam;
    return TradeOffer(
      id: null,
      fromTeam: from,
      toTeam: to,
      fromAssets: entry.fromAssets,
      toAssets: entry.toAssets,
    );
  }

  double _assetValue(TradeAsset asset, int currentYear) {
    final pickOverall = asset.pickOverall ?? _estimateOverall(asset.round);
    var value = _richHillValue(pickOverall);
    final yearDelta = asset.year - currentYear;
    if (yearDelta > 0) {
      value *= pow(0.9, yearDelta).toDouble();
    }
    return value;
  }

  double _richHillValue(int overall) {
    final pick = overall.clamp(1, 300);
    const maxValue = 1000.0;
    final curve = pow(0.95, pick - 1);
    final value = maxValue * curve;
    return value < 1 ? 1 : value;
  }

  int _estimateOverall(int round) {
    final r = round.clamp(1, 7);
    const midInRound = 16;
    return ((r - 1) * 32) + midInRound;
  }

  Widget _tradeMarketSection(DraftState state) {
    final run = _positionRun(state);
    final nextPickGap = _nextUserPickGap(state);
    final onClock = state.currentPick?.teamAbbr.toUpperCase() ?? '—';
    final heat = _marketHeatLabel();
    final heatColor = switch (heat) {
      'Low' => AppColors.textMuted,
      'Warm' => AppColors.blue.withOpacity(0.7),
      'Hot' => AppColors.blue,
      _ => AppColors.mint,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _marketPill('Market: $heat', color: heatColor),
        _marketPill('On clock: $onClock'),
        _marketPill(
          nextPickGap == null
              ? 'Next user pick: —'
              : 'Next user pick: +$nextPickGap',
        ),
        if (run != null) _marketPill(run),
        _marketPill('Inbox: ${state.tradeInbox.length}'),
      ],
    );
  }

  String _marketHeatLabel() {
    final score = (_tradeFrequency * 0.7) + ((0.2 - _tradeStrictness) * 0.3);
    if (score < 0.25) return 'Low';
    if (score < 0.55) return 'Warm';
    if (score < 0.8) return 'Hot';
    return 'Frenzy';
  }

  String? _positionRun(DraftState state) {
    final recent = state.picksMade.reversed.take(6).toList();
    if (recent.length < 4) return null;
    final counts = <String, int>{};
    for (final pr in recent) {
      final pos = pr.prospect.position.toUpperCase();
      counts[pos] = (counts[pos] ?? 0) + 1;
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (top.isEmpty || top.first.value < 3) return null;
    return 'Run: ${top.first.key} (${top.first.value}/${recent.length})';
  }

  int? _nextUserPickGap(DraftState state) {
    if (state.userTeams.isEmpty || state.currentPick == null) return null;
    final currentOverall = state.currentPick!.pickOverall;
    var best = 999999;
    for (var i = state.currentIndex; i < state.order.length; i++) {
      final pick = state.order[i];
      if (!state.userTeams.contains(pick.teamAbbr.toUpperCase())) continue;
      best = pick.pickOverall;
      break;
    }
    if (best == 999999) return null;
    return best - currentOverall;
  }

  Widget _marketPill(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.text,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _heatPill(String label, double score, Color color) {
    final bg = color.withOpacity(0.12 + (0.35 * score));
    final border = color.withOpacity(0.35 + (0.4 * score));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: _readableTeamColor(color),
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftControllerProvider);
    final controller = ref.read(draftControllerProvider.notifier);
    _bindListeners();
    _maybeShowDraftCompletePrompt(state);
    _maybePresentPendingTrade(state);
    _maybeShowTradeTicker(state);
    _maybePlayPickFeedback(state);

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
          _draftHqButton(state),

          IconPill(
            icon: Icons.exit_to_app,
            tooltip: 'Exit',
            onPressed: () => _confirmExit(context),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: WarRoomBackground(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? _errorState(context, state)
            : _content(context, state),
      ),
    );
  }

  Widget _errorState(BuildContext context, DraftState state) {
    final controller = ref.read(draftControllerProvider.notifier);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Draft load failed',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                state.error ?? 'Something went wrong.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/setup'),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
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
                            saveDraft: false,
                          );
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bindListeners() {
    if (_listenersBound) return;
    _listenersBound = true;
    _listenForTradeOffers();
  }

  void _listenForBadgeToasts() {
    _badgeSubscription?.cancel();
    _badgeSubscription =
        ref.read(draftControllerProvider.notifier).badgeEarnedStream.listen(
      (badges) {
        if (!mounted || badges.isEmpty) return;
        final names = badges
            .map((id) => DraftChallenges.byId(id)?.title ?? id)
            .toList();
        final text = names.length == 1
            ? 'Badge earned: ${names.first}'
            : 'Badges earned: ${names.join(', ')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surface,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            content: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.mint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
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
      if (!_tradePopupsEnabled) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _presentTradeOffer(offer, next);
      });
    });
  }

  void _maybePresentPendingTrade(DraftState state) {
    final offer = state.pendingTrade;
    if (offer == null) return;
    if (!_tradePopupsEnabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _presentTradeOffer(offer, state);
    });
  }

  void _presentTradeOffer(TradeOffer offer, DraftState next) {
    final id = offer.id ??
        '${offer.fromTeam}_${offer.toTeam}_${offer.fromAssets.length}_${offer.toAssets.length}';
    if (_tradeDialogOpen || _lastTradeOfferId == id) return;

    _lastTradeOfferId = id;
    _tradeDialogOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _playTradeOfferFeedback();
      final controller = ref.read(draftControllerProvider.notifier);
      if (next.clockRunning) {
        _resumeAfterTradeDialog = true;
        controller.pauseClock();
      } else {
        _resumeAfterTradeDialog = false;
      }
      final accepted = await _showTradeOfferDialog(context, offer);
      if (!mounted) return;
      if (accepted == true) {
        controller.acceptIncomingTrade(offer);
      } else if (accepted == false) {
        controller.declineTradeOffer(offer);
      } else {
        controller.clearPendingTrade();
      }
      if (_resumeAfterTradeDialog && mounted) {
        controller.resumeClock();
      }
      _tradeDialogOpen = false;
    });
  }

  void _maybePlayPickFeedback(DraftState state) {
    if (!_soundHapticsEnabled) return;
    final count = state.picksMade.length;
    if (count <= _lastPickSoundCount) return;
    _lastPickSoundCount = count;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  void _playTradeOfferFeedback() {
    if (!_soundHapticsEnabled) return;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  void _maybeShowTradeTicker(DraftState state) {
    if (state.tradeLog.length <= _lastTradeLogCount) return;
    final newEntries =
        state.tradeLog.sublist(_lastTradeLogCount, state.tradeLog.length);
    _lastTradeLogCount = state.tradeLog.length;

    final userTeams =
        state.userTeams.map((t) => t.toUpperCase()).toSet();
    final summaries = newEntries.map((entry) {
      final from = entry.fromTeam.toUpperCase();
      final to = entry.toTeam.toUpperCase();
      final isUserTrade =
          userTeams.contains(from) || userTeams.contains(to);
      return isUserTrade ? 'USER TRADE: ${entry.summary}' : entry.summary;
    }).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _tradeTickerQueue.addAll(summaries);
        if (_tradeTickerCurrent == null && _tradeTickerQueue.isNotEmpty) {
          _tradeTickerCurrent = _tradeTickerQueue.removeAt(0);
        }
        _tradeTickerVisible = _tradeTickerCurrent != null;
        _tradeTickerToken += 1;
      });
    });
  }

  Widget _tradeTickerStrip() {
    final text = _tradeTickerCurrent ?? '';
    final token = _tradeTickerToken;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppGradients.panel,
          borderRadius: AppRadii.r12,
          border: Border.all(color: AppColors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign, size: 16, color: AppColors.blue),
            const SizedBox(width: 8),
            const Text(
              'TRADE ALERT:',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TradeTickerMarquee(
                text: text,
                onComplete: () {
                  if (!mounted) return;
                  if (token != _tradeTickerToken) return;
                  setState(() => _tradeTickerVisible = false);
                  Future.delayed(const Duration(milliseconds: 180), () {
                    if (!mounted) return;
                    if (token != _tradeTickerToken) return;
                    setState(() {
                      if (_tradeTickerQueue.isNotEmpty) {
                        _tradeTickerCurrent = _tradeTickerQueue.removeAt(0);
                        _tradeTickerVisible = true;
                        _tradeTickerToken += 1;
                      } else {
                        _tradeTickerCurrent = null;
                        _tradeTickerVisible = false;
                      }
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final controller = ref.read(draftControllerProvider.notifier);
    final action = await showDialog<_ExitAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit draft?'),
        content: const Text(
          'Would you like to save this draft so you can resume later?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.exit),
            child: const Text('Exit Without Saving'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.save),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    if (!context.mounted || action == null || action == _ExitAction.cancel) {
      return;
    }
    if (action == _ExitAction.save) {
      controller.setSavingEnabled(true);
      await controller.saveNow();
    }
    if (context.mounted) {
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
          if (_tradeTickerVisible && _tradeTickerQueue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _tradeTickerStrip(),
            ),
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
          child: _onClockLabel(
            state.currentPick?.label ?? 'Draft complete',
            shimmer: !state.isComplete,
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

  Widget _onClockLabel(String text, {required bool shimmer}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: AppRadii.r12,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (shimmer)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadii.r12,
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  final x = (_shimmerController.value * 2 - 0.5);
                  return Transform.translate(
                    offset: Offset(x * 120, 0),
                    child: Container(
                      width: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0x33A7E3FF),
                            Color(0x00FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = board[i];
              final canPick = state.isUserOnClock && !state.isComplete;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final usePlusOnly = !recapCollapsed && isNarrow;
                  final college = (p.college ?? '').trim();
                  final subtitle = isNarrow
                      ? [
                          p.position.toUpperCase(),
                          if (college.isNotEmpty) college,
                        ].join(' • ')
                      : college;
                  final action = canPick
                      ? (usePlusOnly
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
                      : null;

                  return StaggeredReveal(
                    index: i,
                    child: _tradeBaitSwipe(
                      p,
                      child: PickCard(
                        glowColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _rankPill(p.rank),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          maxLines: isNarrow ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
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
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    maxLines: isNarrow ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (action != null) ...[
                              const SizedBox(width: 10),
                              action,
                            ],
                          ],
                        ),
                      ),
                    ),
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _tradeBaitSwipe(Prospect prospect, {required Widget child}) {
    final isBait = _tradeBaitIds.contains(prospect.id);
    return Dismissible(
      key: ValueKey('bait-${prospect.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        setState(() {
          if (isBait) {
            _tradeBaitIds.remove(prospect.id);
          } else {
            _tradeBaitIds.add(prospect.id);
          }
        });
        return false;
      },
      background: Container(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isBait ? AppColors.blue.withOpacity(0.25) : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBait ? AppColors.blue : AppColors.border,
          ),
        ),
        child: Text(
          isBait ? 'Unmark Trade Bait' : 'Mark as Trade Bait',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      child: child,
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                      final teamColorRaw =
                          teamColors[pick.teamAbbr.toUpperCase()] ??
                              AppColors.blue;
                      final teamColor = _readableTeamColor(teamColorRaw);
                      return StaggeredReveal(
                        index: i,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 300;
                          final badge = Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 6 : 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: teamColorRaw.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: teamColorRaw.withOpacity(0.6),
                              ),
                            ),
                            child: Text(
                              '#${pick.pickOverall}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: teamColor,
                              ),
                            ),
                          );
                          return PickCard(
                            key: key,
                            glowColor: teamColorRaw,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: isNarrow
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      badge,
                                      const SizedBox(height: 8),
                                      Text(
                                        prospect?.name ??
                                            'Pick ${pick.pickOverall}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: prospect == null
                                              ? AppColors.textMuted
                                              : AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${pick.teamAbbr}  •  R${pick.round}.${pick.pickInRound.toString().padLeft(2, '0')}$via  •  $detail',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: teamColor),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      badge,
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prospect?.name ??
                                                  'Pick ${pick.pickOverall}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: prospect == null
                                                    ? AppColors.textMuted
                                                    : AppColors.text,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${pick.teamAbbr}  •  R${pick.round}.${pick.pickInRound.toString().padLeft(2, '0')}$via  •  $detail',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  TextStyle(color: teamColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
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

class _TradeTickerMarquee extends StatefulWidget {
  const _TradeTickerMarquee({
    required this.text,
    required this.onComplete,
  });

  final String text;
  final VoidCallback onComplete;

  @override
  State<_TradeTickerMarquee> createState() => _TradeTickerMarqueeState();
}

class _TradeTickerMarqueeState extends State<_TradeTickerMarquee>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late TextStyle _textStyle;
  double _viewportWidth = 0;
  static const double _speed = 36; // pixels per second
  static const double _gap = 48;
  Timer? _completeTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textStyle = DefaultTextStyle.of(context)
        .style
        .copyWith(color: AppColors.textMuted);
    _scheduleStart();
  }

  @override
  void didUpdateWidget(covariant _TradeTickerMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _started = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _scheduleStart();
    }
  }

  void _scheduleStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startScroll();
    });
  }

  Future<void> _startScroll() async {
    if (!mounted || _started) return;
    if (!_scrollController.hasClients) return;
    _started = true;
    _completeTimer?.cancel();
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) {
      _completeTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) widget.onComplete();
      });
      return;
    }
    final seconds = max / _speed;
    await _scrollController.animateTo(
      max,
      duration: Duration(milliseconds: (seconds * 1000).round()),
      curve: Curves.linear,
    );
    if (!mounted) return;
    _completeTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (_viewportWidth != width) {
          _viewportWidth = width;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _started = false;
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
            _scheduleStart();
          });
        }
        final leadIn = (_viewportWidth * 0.6).clamp(64.0, 200.0);
        return ClipRect(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                SizedBox(width: leadIn),
                Text(
                  widget.text,
                  maxLines: 1,
                  style: _textStyle,
                ),
                const SizedBox(width: _gap),
              ],
            ),
          ),
        );
      },
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
