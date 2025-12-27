import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_theme.dart';
import '../../ui/panel.dart';
import '../../ui/war_room_background.dart';
import '../../core/storage/local_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final streak = await LocalStore.updateDraftStreak();
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _loaded = true;
    });
  }

  static const String _contactUrl = 'https://forms.gle/your-form-id';

  @override
  Widget build(BuildContext context) {
    final challenge = _dailyChallengeText();
    final badges = _streakBadges(_streak);
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
                            const SizedBox(height: 6),
                            Text(
                              challenge,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
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
    final challenges = [
      'No trades allowed. Can you still land your top target?',
      'Make at least 1 trade up and 1 trade down.',
      'Draft two players from the same conference.',
      'Hold your first pick and still secure a top-10 talent.',
      'Target a trench pick in Round 1.',
      'Find a “steal”: draft a player ranked 10+ spots higher.',
      'Draft for need: pick a top-3 team need in your first 2 rounds.',
    ];
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(start).inDays + 1;
    return challenges[dayOfYear % challenges.length];
  }

  List<String> _streakBadges(int streak) {
    final badges = <String>[];
    if (streak >= 3) badges.add('3-Day');
    if (streak >= 7) badges.add('1-Week');
    if (streak >= 14) badges.add('2-Week');
    if (streak >= 30) badges.add('30-Day');
    return badges;
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
