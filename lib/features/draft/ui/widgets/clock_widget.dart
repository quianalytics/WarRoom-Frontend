import 'package:flutter/material.dart';

class DraftClockWidget extends StatelessWidget {
  const DraftClockWidget({super.key, required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Draft Clock'),
          Text('$m:$s', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
