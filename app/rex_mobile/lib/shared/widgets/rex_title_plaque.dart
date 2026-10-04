import 'package:flutter/material.dart';

import '../../core/design/rex_colors.dart';

class RexTitlePlaque extends StatelessWidget {
  const RexTitlePlaque({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    decoration: BoxDecoration(
      color: RexColors.ink.withAlpha(230),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: RexColors.gold, width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14)],
    ),
    child: Text(
      text,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        color: RexColors.gold,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
