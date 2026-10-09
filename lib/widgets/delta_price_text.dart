import 'package:flutter/material.dart';

import '../utils/format.dart';

class DeltaPriceText extends StatelessWidget {
  final double delta;
  final double fontSize;

  const DeltaPriceText({
    super.key,
    required this.delta,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (delta.abs() < 0.005) {
      return Semantics(
        label: 'sem diferença',
        child: Text(
          '—',
          style: TextStyle(
            color: const Color(0xFF7A8B83),
            fontSize: fontSize,
          ),
        ),
      );
    }

    final isNegative = delta < 0;
    final color = isNegative ? Colors.green : Colors.red;
    final sign = isNegative ? '−' : '+';
    final value = formatCurrencyAbs(delta.abs());
    final label = isNegative ? 'economia de $value' : 'aumento de $value';

    return Semantics(
      label: label,
      child: Text(
        '$sign$value',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
