import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    super.key,
    required this.child,
    required this.index,
    this.maxDelay = const Duration(milliseconds: 320),
    this.step = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 160),
  });

  final Widget child;
  final int index;
  final Duration maxDelay;
  final Duration step;
  final Duration duration;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delay = widget.step * widget.index;
    final capped = delay > widget.maxDelay ? widget.maxDelay : delay;
    _timer = Timer(capped, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: widget.duration,
      curve: AppMotion.revealCurve,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: widget.duration,
        curve: AppMotion.revealCurve,
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        child: widget.child,
      ),
    );
  }
}
