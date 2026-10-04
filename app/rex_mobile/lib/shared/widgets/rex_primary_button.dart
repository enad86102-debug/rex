import 'package:flutter/material.dart';

import '../../core/design/rex_colors.dart';

class RexPrimaryButton extends StatelessWidget {
  const RexPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext c) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: RexColors.gold,
        foregroundColor: RexColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ),
  );
}
