import 'package:flutter/material.dart';
import '../utils/responsive_layout.dart';

class SentencePanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSpeak;
  final VoidCallback onClear;
  final bool compact;

  const SentencePanel({
    super.key,
    required this.controller,
    required this.onSpeak,
    required this.onClear,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AacLayoutProvider.maybeOf(context);
    final isCompact = compact || (layout?.phraseCompact ?? false);
    final iconSize = layout?.actionIconSize ?? 22.0;

    if (isCompact) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration.collapsed(
                      hintText: 'Type a sentence'),
                  minLines: 1,
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up, size: iconSize),
                onPressed: onSpeak,
                tooltip: 'Speak sentence',
              ),
              IconButton(
                icon: Icon(Icons.clear, size: iconSize),
                onPressed: onClear,
                tooltip: 'Clear',
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sentence Mode',
                style: TextStyle(
                    fontSize: layout?.isPhone == true ? 14 : 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type or build a full sentence',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: layout?.useSidePanel == true ? 5 : 3,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.volume_up, size: iconSize),
                  onPressed: onSpeak,
                  tooltip: 'Speak sentence',
                ),
                IconButton(
                  icon: Icon(Icons.clear_all, size: iconSize),
                  onPressed: onClear,
                  tooltip: 'Clear sentence',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
