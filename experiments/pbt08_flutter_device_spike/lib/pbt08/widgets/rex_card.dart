import 'package:flutter/material.dart';

class RexCard extends StatelessWidget {
  const RexCard({
    super.key,
    required this.rank,
    required this.suit,
    this.width = 48,
    this.height = 68,
  }) : faceDown = false;
  const RexCard.back({super.key, this.width = 36, this.height = 50})
    : rank = '',
      suit = '',
      faceDown = true;

  final String rank;
  final String suit;
  final double width;
  final double height;
  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    final ink = suit == '♥' || suit == '♦'
        ? const Color(0xFFAD3D3D)
        : const Color(0xFF243332);
    return Semantics(
      label: faceDown ? 'Experimental card back' : 'Sample card $rank $suit',
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: faceDown ? const Color(0xFF213F43) : const Color(0xFFF8F2E6),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: faceDown
                  ? const Color(0xFFE4B976)
                  : const Color(0xFFD4CBB9),
            ),
          ),
          child: faceDown
              ? const Center(
                  child: Icon(
                    Icons.diamond_outlined,
                    color: Color(0xFFE4B976),
                    size: 20,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank,
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(suit, style: TextStyle(color: ink, fontSize: 12)),
                      Expanded(
                        child: Center(
                          child: Text(
                            suit,
                            style: TextStyle(color: ink, fontSize: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
