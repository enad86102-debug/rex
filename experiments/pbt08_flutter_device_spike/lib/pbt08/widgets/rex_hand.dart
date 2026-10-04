import 'package:flutter/material.dart';

import 'rex_card.dart';

class RexHand extends StatelessWidget {
  const RexHand({super.key});

  // Fixed visual samples, not a shuffled deck or a game-rule contract.
  static const ranks = [
    'A',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K',
  ];
  static const suits = ['♠', '♥', '♣', '♦'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth / 7).clamp(36.0, 62.0);
          final step = (constraints.maxWidth - width) / (ranks.length - 1);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < ranks.length; i++)
                Positioned(
                  left: i * step,
                  top: (i - 6).abs() * 1.2,
                  child: Transform.rotate(
                    angle: (i - 6) * 0.015,
                    child: RexCard(
                      key: ValueKey('local-card-$i'),
                      rank: ranks[i],
                      suit: suits[i % suits.length],
                      width: width,
                      height: 88,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
