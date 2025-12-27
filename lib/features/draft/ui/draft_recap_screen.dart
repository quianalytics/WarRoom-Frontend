import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../logic/draft_state.dart';
import '../providers.dart';
import '../../../theme/app_theme.dart';
import '../../../ui/panel.dart';
import '../../../ui/pick_card.dart';
import '../../../ui/war_room_background.dart';
import '../../../ui/staggered_reveal.dart';

class DraftRecapScreen extends ConsumerStatefulWidget {
  const DraftRecapScreen({super.key});

  @override
  ConsumerState<DraftRecapScreen> createState() => _DraftRecapScreenState();
}

class _DraftRecapScreenState extends ConsumerState<DraftRecapScreen> {
  String? _teamFilter;
  bool _showAllTeams = false;
  bool _sortByTeam = false;
  final GlobalKey _recapKey = GlobalKey();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftControllerProvider);
    final userTeams =
        state.userTeams.map((t) => t.toUpperCase()).toList()..sort();
    final allTeams =
        state.teams.map((t) => t.abbreviation.toUpperCase()).toList()..sort();
    final visibleTeams = _showAllTeams ? allTeams : userTeams;
    final filter = _teamFilter;

    final teamColors = _teamColorMap(state);
    final picks = state.picksMade
        .where((p) => visibleTeams.contains(p.teamAbbr.toUpperCase()))
        .where((p) => filter == null || p.teamAbbr.toUpperCase() == filter)
        .toList()
      ..sort((a, b) {
        if (_sortByTeam) {
          final teamCmp = a.teamAbbr.compareTo(b.teamAbbr);
          if (teamCmp != 0) return teamCmp;
        }
        return a.pick.pickOverall.compareTo(b.pick.pickOverall);
      });
    final tradeEntries = _filteredTrades(
      state,
      userTeams,
      _teamFilter,
      showAllTeams: _showAllTeams,
      visibleTeams: visibleTeams,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Recap'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: _exporting ? null : () => _shareRecap(context),
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _exporting ? null : () => _saveRecap(context),
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: WarRoomBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: _recapKey,
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
                                  const Text('Scope:'),
                                  const SizedBox(width: 12),
                                  DropdownButton<bool>(
                                    value: _showAllTeams,
                                    items: const [
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text('My Teams'),
                                      ),
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text('All Teams'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        _showAllTeams = v ?? false;
                                        _teamFilter = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  const Text('Team:'),
                                  const SizedBox(width: 12),
                                  DropdownButton<String?>(
                                    value: _teamFilter,
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          _showAllTeams
                                              ? 'All Teams'
                                              : 'All',
                                        ),
                                      ),
                                      ...visibleTeams.map(
                                        (t) => DropdownMenuItem<String?>(
                                          value: t,
                                          child: Text(
                                            t,
                                            style: TextStyle(
                                              color: _readableTeamColor(
                                                teamColors[t] ??
                                                    AppColors.text,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _teamFilter = v);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text('Sort:'),
                                  const SizedBox(width: 12),
                                  DropdownButton<bool>(
                                    value: _sortByTeam,
                                    items: const [
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text('Pick Order'),
                                      ),
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text('Team A–Z'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _sortByTeam = v ?? false);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (tradeEntries.isNotEmpty) ...[
                          Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trades Made',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...tradeEntries.map(
                                  (t) => Text(
                                    '• ${t.summary}',
                                    style: TextStyle(
                                      color: _readableTeamColor(
                                        _tradeTextColor(t, teamColors),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Expanded(
                          child: ListView.separated(
                            itemCount: picks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final pr = picks[i];
                              final grade = _gradeForPick(pr);
                              final teamColorRaw =
                                  teamColors[pr.teamAbbr.toUpperCase()] ??
                                      AppColors.blue;
                              return StaggeredReveal(
                                index: i,
                                child: PickCard(
                                  glowColor: teamColorRaw,
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
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: teamColorRaw.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: teamColorRaw,
                                        ),
                                      ),
                                      child: Text(
                                        pr.teamAbbr.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: _readableTeamColor(
                                            teamColorRaw,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  ),
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
      ),
    );
  }

  Future<void> _shareRecap(BuildContext context) async {
    if (kIsWeb ||
        !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sharing is only supported on mobile and macOS.'),
        ),
      );
      return;
    }
    try {
      final bytes = await _captureRecap();
      if (bytes == null) return;
      final framed = await _frameRecap(bytes);
      if (framed == null) return;
      final file = await _writeTempFile(framed);
      if (file == null || !mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My WarRoom draft recap',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  Future<void> _saveRecap(BuildContext context) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery save is only supported on mobile.'),
        ),
      );
      return;
    }
    try {
      final bytes = await _captureRecap();
      if (bytes == null) return;
      final framed = await _frameRecap(bytes);
      if (framed == null) return;
      final result = await ImageGallerySaver.saveImage(
        framed,
        quality: 100,
        name: 'warroom_recap_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      final saved = result['isSuccess'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'Saved to Photos' : 'Failed to save screenshot',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<Uint8List?> _captureRecap() async {
    if (_exporting) return null;
    setState(() => _exporting = true);
    try {
      final boundary =
          _recapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<File?> _writeTempFile(Uint8List bytes) async {
    final dir = Directory.systemTemp;
    final file = File(
      '${dir.path}/warroom_recap_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file;
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
    if (delta >= 12) return const _Grade('A+', 98);
    if (delta >= 7) return const _Grade('A', 94);
    if (delta >= 3) return const _Grade('A-', 91);
    if (delta >= 0) return const _Grade('B+', 88);
    if (delta >= -3) return const _Grade('B', 84);
    if (delta >= -7) return const _Grade('B-', 81);
    if (delta >= -12) return const _Grade('C+', 78);
    if (delta >= -18) return const _Grade('C', 74);
    if (delta >= -27) return const _Grade('D', 68);
    return const _Grade('F', 60);
  }

  _Grade _avgScore(List<_Grade> grades) {
    final total = grades.fold<double>(0, (s, g) => s + g.score);
    final avg = total / grades.length;
    return _scoreToGrade(avg);
  }

  Future<Uint8List?> _frameRecap(Uint8List bytes) async {
    if (_exporting) return null;
    try {
      final state = ref.read(draftControllerProvider);
      final picks = state.picksMade
          .where((p) => state.userTeams
              .map((t) => t.toUpperCase())
              .contains(p.teamAbbr.toUpperCase()))
          .toList();
      final grades = picks.map(_gradeForPick).toList();
      final avg = _avgScore(grades);
      final recapImage = await _decodeImage(bytes);
      if (recapImage == null) return null;
      return _composeFramedImage(
        recapImage,
        picksCount: picks.length,
        avgGrade: avg.letter,
        avgScore: avg.score,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<Uint8List?> _composeFramedImage(
    ui.Image recap, {
    required int picksCount,
    required String avgGrade,
    required double avgScore,
  }) async {
    const padding = 40.0;
    const badgePadding = 10.0;
    const badgeRadius = 10.0;
    const borderRadius = 18.0;
    const frameColor = Color(0xFF0B0F16);
    const accent = Color(0xFF4ED6FF);
    final width = recap.width + (padding * 2).toInt();
    final height = recap.height + (padding * 2).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bgPaint = Paint()..color = frameColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padding,
        padding,
        recap.width.toDouble(),
        recap.height.toDouble(),
      ),
      const Radius.circular(borderRadius),
    );
    final framePaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(frameRect, framePaint);

    final borderPaint = Paint()
      ..color = accent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(frameRect, borderPaint);

    canvas.drawImage(recap, Offset(padding, padding), Paint());

    final titleStyle = const TextStyle(
      color: Color(0xFFF2F7FF),
      fontSize: 18,
      fontWeight: FontWeight.w800,
    );
    final title = _drawText(
      canvas,
      'WarRoom Draft Recap',
      Offset(padding, 14),
      titleStyle,
    );
    _drawText(
      canvas,
      'Powered by WarRoom',
      Offset(width - padding - title.width, height - 22),
      const TextStyle(
        color: Color(0x669DB2CC),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );

    final badgeY = padding - 18;
    final badge1 = _badgeText(
      canvas,
      'PICKS: $picksCount',
      Offset(padding, badgeY),
      badgePadding,
      badgeRadius,
    );
    _badgeText(
      canvas,
      'AVG GRADE: $avgGrade (${avgScore.toStringAsFixed(1)})',
      Offset(padding + badge1.width + 12, badgeY),
      badgePadding,
      badgeRadius,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  _TextLayout _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
    return _TextLayout(painter.width, painter.height);
  }

  _TextLayout _badgeText(
    Canvas canvas,
    String text,
    Offset offset,
    double padding,
    double radius,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFF2F7FF),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      painter.width + padding * 2,
      painter.height + padding * 1.2,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()..color = const Color(0xFF172033);
    final stroke = Paint()
      ..color = const Color(0x334ED6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, stroke);
    painter.paint(
      canvas,
      Offset(offset.dx + padding, offset.dy + padding * 0.4),
    );
    return _TextLayout(rect.width, rect.height);
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

  List<TradeLogEntry> _filteredTrades(
    DraftState state,
    List<String> userTeams,
    String? teamFilter, {
    required bool showAllTeams,
    required List<String> visibleTeams,
  }) {
    if (state.tradeLog.isEmpty) return const [];
    if (teamFilter != null) {
      return state.tradeLog
          .where((t) =>
              t.fromTeam.toUpperCase() == teamFilter ||
              t.toTeam.toUpperCase() == teamFilter)
          .toList();
    }
    final scope = showAllTeams
        ? visibleTeams.map((t) => t.toUpperCase()).toSet()
        : userTeams.map((t) => t.toUpperCase()).toSet();
    return state.tradeLog
        .where((t) =>
            scope.contains(t.fromTeam.toUpperCase()) ||
            scope.contains(t.toTeam.toUpperCase()))
        .toList();
  }

  Color _tradeTextColor(
    TradeLogEntry entry,
    Map<String, Color> teamColors,
  ) {
    final from = entry.fromTeam.toUpperCase();
    final to = entry.toTeam.toUpperCase();
    return teamColors[from] ??
        teamColors[to] ??
        AppColors.textMuted;
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
}

class _Grade {
  final String letter;
  final double score;

  const _Grade(this.letter, this.score);
}

class _TextLayout {
  final double width;
  final double height;

  const _TextLayout(this.width, this.height);
}
