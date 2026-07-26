import 'package:flutter/material.dart';

import '../models/symbol_tile.dart';
import '../utils/responsive_layout.dart';

class PhrasePanel extends StatelessWidget {
  final List<SymbolTile> phrase;
  final VoidCallback onClear;
  final VoidCallback onSpeak;
  final ValueChanged<int> onRemoveSymbol;
  final bool compact;

  const PhrasePanel({
    super.key,
    required this.phrase,
    required this.onClear,
    required this.onSpeak,
    required this.onRemoveSymbol,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AacLayoutProvider.maybeOf(context);
    final isCompact = compact || (layout?.phraseCompact ?? false);
    final chipHeight = layout?.isPhone == true ? 36.0 : 44.0;
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
                child: SizedBox(
                  height: chipHeight,
                  child: phrase.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Tap symbols to build',
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: layout?.isPhone == true ? 12 : 13)))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, i) {
                            final symbol = phrase[i];
                            return InputChip(
                              label: Text(symbol.label,
                                  style: TextStyle(
                                      fontSize: layout?.isPhone == true ? 12 : 13)),
                              onDeleted: () => onRemoveSymbol(i),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemCount: phrase.length,
                        ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up, size: iconSize),
                onPressed: phrase.isEmpty ? null : onSpeak,
                tooltip: 'Speak phrase',
              ),
              IconButton(
                icon: Icon(Icons.clear, size: iconSize),
                onPressed: phrase.isEmpty ? null : onClear,
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
        padding: EdgeInsets.all(layout?.isPhone == true ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Phrase Builder',
                      style: TextStyle(
                          fontSize: layout?.isPhone == true ? 14 : 16,
                          fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up, size: iconSize),
                  onPressed: phrase.isEmpty ? null : onSpeak,
                  tooltip: 'Speak phrase',
                ),
                IconButton(
                  icon: Icon(Icons.clear_all, size: iconSize),
                  onPressed: phrase.isEmpty ? null : onClear,
                  tooltip: 'Clear phrase',
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (phrase.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(child: Text('Tap symbols to build a message', style: TextStyle(color: Colors.black54))),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: phrase.asMap().entries.map((entry) {
                  final index = entry.key;
                  final symbol = entry.value;
                  return InputChip(
                    label: Text('${symbol.emoji} ${symbol.label}'),
                    onDeleted: () => onRemoveSymbol(index),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
