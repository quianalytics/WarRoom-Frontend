import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_theme.dart';
import '../../ui/panel.dart';
import '../../ui/war_room_background.dart';
import '../../core/storage/local_store.dart';
import '../../core/challenges/draft_challenges.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  bool _loaded = false;
  Timer? _challengeTimer;
  String _challengeText = '';
  Duration _challengeCountdown = Duration.zero;
  DateTime _challengeDay = DateTime.now();
  bool _dailyCompleted = false;
  Set<String> _badges = {};

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _updateChallengeMeta();
    _loadBadges();
    _challengeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateChallengeMeta(),
    );
  }

  Future<void> _loadStreak() async {
    final streak = await LocalStore.updateDraftStreak();
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _loaded = true;
    });
  }

  Future<void> _loadBadges() async {
    final badges = await LocalStore.getBadgeIds();
    final dailyDone =
        await LocalStore.isDailyChallengeCompleted(DateTime.now());
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _dailyCompleted = dailyDone;
    });
  }

  @override
  void dispose() {
    _challengeTimer?.cancel();
    super.dispose();
  }

  static const String _contactUrl = 'https://forms.gle/your-form-id';

  @override
  Widget build(BuildContext context) {
    final challenge = _challengeText.isEmpty
        ? _dailyChallengeText()
        : _challengeText;
    final badges = _streakBadges(_streak);
    final countdown = _formatCountdown(_challengeCountdown);
    return Scaffold(
      body: WarRoomBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Panel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to WarRoom.',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dominate the draft.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Panel(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Challenge',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resets in $countdown',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              challenge,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _dailyCompleted
                                    ? _badgeChip('Completed')
                                    : _badgeChip('In Progress'),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => _showBadges(context),
                                  child: const Text('View Badges'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  _loaded
                                      ? 'Draft streak: $_streak day${_streak == 1 ? '' : 's'}'
                                      : 'Draft streak: …',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (badges.isNotEmpty)
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.end,
                                      children: badges
                                          .map(
                                            (b) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface2,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: AppColors.border,
                                                ),
                                              ),
                                              child: Text(
                                                b,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.go('/setup'),
                          child: const Text('Start'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showAboutDialog(context),
                              child: const Text('About'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ContactUsScreen(
                                      url: _contactUrl,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Contact Us'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About WarRoom'),
        content: const Text(
          'WarRoom Draft Simulator helps you run NFL mock drafts with '
          'realistic CPU behavior, trade logic, and draft grading.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _dailyChallengeText() {
    final challenge = DraftChallenges.dailyChallengeFor(DateTime.now());
    return '${challenge.title}: ${challenge.description}';
  }

  void _updateChallengeMeta() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final next = midnight.difference(now);
    final text = _dailyChallengeText();
    if (!mounted) return;
    setState(() {
      _challengeText = text;
      _challengeCountdown = next;
      _challengeDay = DateTime(now.year, now.month, now.day);
    });
    LocalStore.isDailyChallengeCompleted(DateTime.now()).then((done) {
      if (!mounted) return;
      setState(() => _dailyCompleted = done);
    });
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  List<String> _streakBadges(int streak) {
    final badges = <String>[];
    if (streak >= 3) badges.add('3-Day');
    if (streak >= 7) badges.add('1-Week');
    if (streak >= 14) badges.add('2-Week');
    if (streak >= 30) badges.add('30-Day');
    return badges;
  }

  Widget _badgeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _difficultyChip(ChallengeDifficulty difficulty) {
    final color = switch (difficulty) {
      ChallengeDifficulty.easy => AppColors.mint,
      ChallengeDifficulty.medium => AppColors.blue,
      ChallengeDifficulty.hard => AppColors.accent,
      ChallengeDifficulty.elite => AppColors.blueDeep,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Text(
        difficulty.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Future<void> _showBadges(BuildContext context) async {
    await _loadBadges();
    if (!context.mounted) return;
    final groups = <ChallengeDifficulty, List<DraftChallenge>>{};
    for (final c in DraftChallenges.all) {
      groups.putIfAbsent(c.difficulty, () => []).add(c);
    }
    final order = const [
      ChallengeDifficulty.easy,
      ChallengeDifficulty.medium,
      ChallengeDifficulty.hard,
      ChallengeDifficulty.elite,
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Badges',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  '${_badges.length} / ${DraftChallenges.all.length} completed',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    itemCount: order.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final difficulty = order[i];
                      final list = groups[difficulty] ?? const [];
                      if (list.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            difficulty.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...list.map((badge) {
                            final earned = _badges.contains(badge.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: AppRadii.r12,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      earned
                                          ? Icons.verified
                                          : Icons.lock_outline,
                                      color: earned
                                          ? AppColors.blue
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            badge.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            badge.description,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _difficultyChip(badge.difficulty),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key, required this.url});

  final String url;

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
