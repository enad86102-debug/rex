import 'package:flutter/material.dart';

import 'rex_card.dart';
import 'rex_player_seat.dart';

class RexTable extends StatelessWidget {
  const RexTable({super.key, required this.animation});

  final Animation<double> animation;
  static const animatedCardsPerDeal = 8;
  static const _labels = [
    'شمال / North',
    'شرق / East',
    'جنوب / South',
    'غرب / West',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final center = Offset(size.width / 2, size.height / 2);
        final seats = [
          Offset(center.dx, 37),
          Offset(size.width - 46, center.dy),
          Offset(center.dx, size.height - 37),
          Offset(46, center.dy),
        ];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: 35,
              right: 35,
              top: 36,
              bottom: 36,
              child: DecoratedBox(
                key: const ValueKey('table-surface'),
                decoration: BoxDecoration(
                  color: const Color(0xFF255248),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFF9F8458), width: 5),
                ),
              ),
            ),
            for (var i = 0; i < seats.length; i++)
              Positioned(
                left: seats[i].dx - 46,
                top: seats[i].dy - 33,
                width: 92,
                child: RexPlayerSeat(
                  key: ValueKey('seat-$i'),
                  label: _labels[i],
                  local: i == 2,
                ),
              ),
            Positioned(
              key: const ValueKey('center-deck'),
              left: center.dx - 25,
              top: center.dy - 34,
              width: 54,
              height: 72,
              child: const Stack(
                children: [
                  Positioned(
                    left: 6,
                    top: 6,
                    child: RexCard.back(width: 42, height: 58),
                  ),
                  Positioned(
                    left: 3,
                    top: 3,
                    child: RexCard.back(width: 42, height: 58),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: RexCard.back(width: 42, height: 58),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) => Stack(
                children: [
                  for (var i = 0; i < animatedCardsPerDeal; i++)
                    if (animation.value > i * 0.09 &&
                        animation.value < i * 0.09 + 0.30)
                      _flight(i, center, seats[i % seats.length]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _flight(int index, Offset center, Offset target) {
    final rawProgress = ((animation.value - index * 0.09) / 0.30).clamp(
      0.0,
      1.0,
    );
    final progress = Curves.easeInOut.transform(rawProgress);
    final point = Offset.lerp(center, target, progress)!;
    return Positioned(
      left: point.dx - 18,
      top: point.dy - 25,
      child: Transform.rotate(
        angle: progress * (index.isEven ? 0.25 : -0.25),
        child: RexCard.back(key: ValueKey('deal-flight-$index')),
      ),
    );
  }
}
