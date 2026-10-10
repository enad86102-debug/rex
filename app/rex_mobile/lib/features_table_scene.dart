import 'package:flutter/material.dart';

enum RexEnvironment { royalHall, wadiRum, petra, aqaba }

extension RexEnvironmentData on RexEnvironment {
  String get id => switch (this) {
    RexEnvironment.royalHall => 'royal_hall',
    RexEnvironment.wadiRum => 'wadi_rum',
    RexEnvironment.petra => 'petra',
    RexEnvironment.aqaba => 'aqaba',
  };

  String get arabicName => switch (this) {
    RexEnvironment.royalHall => 'القاعة الملكية',
    RexEnvironment.wadiRum => 'وادي رم',
    RexEnvironment.petra => 'البتراء',
    RexEnvironment.aqaba => 'العقبة',
  };
}

RexEnvironment rexEnvironmentFromId(String id) =>
    RexEnvironment.values.firstWhere(
      (environment) => environment.id == id,
      orElse: () => RexEnvironment.royalHall,
    );

class RexSeatDefinition {
  const RexSeatDefinition(this.id, this.anchor, this.perspective);
  final String id;
  final Alignment anchor;
  final String perspective;
}

const rexSeatDefinitions = <RexSeatDefinition>[
  RexSeatDefinition('north', Alignment(0, -.68), 'front'),
  RexSeatDefinition('east', Alignment(.68, 0), 'right_three_quarter'),
  RexSeatDefinition('south', Alignment(0, .68), 'front'),
  RexSeatDefinition('west', Alignment(-.68, 0), 'left_three_quarter'),
];

class TableScene extends StatelessWidget {
  const TableScene({super.key, required this.environment});
  final RexEnvironment environment;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: FractionallySizedBox(
        widthFactor: .96,
        heightFactor: .54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            EnvironmentLayer(environment: environment),
            const SeatLayer(),
            const TableSurface(),
            const TableOverlay(),
          ],
        ),
      ),
    ),
  );
}

class EnvironmentLayer extends StatelessWidget {
  const EnvironmentLayer({super.key, required this.environment});
  final RexEnvironment environment;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF102038), Color(0xFF061018)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Center(
      child: Text(
        'STAGING • ${environment.arabicName}',
        style: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
    ),
  );
}

class SeatLayer extends StatelessWidget {
  const SeatLayer({super.key});
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final seat in rexSeatDefinitions)
        Align(
          alignment: seat.anchor,
          child: SeatSlot(definition: seat),
        ),
    ],
  );
}

class SeatSlot extends StatelessWidget {
  const SeatSlot({super.key, required this.definition});
  final RexSeatDefinition definition;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 86,
    height: 76,
    child: Stack(
      alignment: Alignment.center,
      children: [
        ChairSlot(perspective: definition.perspective),
        CharacterSlot(seatId: definition.id),
      ],
    ),
  );
}

class CharacterSlot extends StatelessWidget {
  const CharacterSlot({super.key, required this.seatId});
  final String seatId;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    color: Colors.black.withAlpha(190),
    child: Text(
      '${seatId.toUpperCase()} • ART MISSING',
      style: const TextStyle(fontSize: 8, color: Colors.white),
    ),
  );
}

class ChairSlot extends StatelessWidget {
  const ChairSlot({super.key, required this.perspective});
  final String perspective;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/staging/rex_starter_kit/extracted_verified/${perspective == 'front' ? 'Chair_Blue_Gold_Front_Original.png' : 'Chair_Blue_Gold_Angled_Original.png'}',
    fit: BoxFit.contain,
  );
}

class TableSurface extends StatelessWidget {
  const TableSurface({super.key});
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/staging/rex_starter_kit/extracted_verified/Table_Emerald_Felt_Original.png',
        fit: BoxFit.contain,
      ),
      Image.asset(
        'assets/staging/rex_starter_kit/extracted_verified/Table_Royal_Gold_Frame_Original.png',
        fit: BoxFit.contain,
      ),
      const InteractiveCardLayer(),
    ],
  );
}

class InteractiveCardLayer extends StatelessWidget {
  const InteractiveCardLayer({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class TableOverlay extends StatelessWidget {
  const TableOverlay({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
