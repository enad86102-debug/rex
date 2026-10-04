import 'package:flutter/material.dart';

class RexPlayerSeat extends StatelessWidget {
  const RexPlayerSeat({super.key, required this.label, this.local = false});

  final String label;
  final bool local;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF294247),
            border: Border.all(
              color: local ? const Color(0xFFE4B976) : const Color(0xFF597374),
              width: 2,
            ),
          ),
          child: Icon(
            local ? Icons.person : Icons.person_outline,
            color: const Color(0xFFE8E5D9),
            size: 23,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF16282C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 10, color: Color(0xFFE8E5D9)),
          ),
        ),
      ],
    );
  }
}
