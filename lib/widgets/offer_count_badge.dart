import 'package:flutter/material.dart';

class OfferCountBadge extends StatelessWidget {
  final int count;

  const OfferCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count == 0 ? 'sem ofertas' : '$count ofertas';
    final bg = count == 0
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF165A41).withValues(alpha: 0.2);
    final textColor =
        count == 0 ? const Color(0xFF7A8B83) : const Color(0xFFB89775);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
