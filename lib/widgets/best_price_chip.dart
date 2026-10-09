import 'package:flutter/material.dart';

class BestPriceChip extends StatelessWidget {
  final String label;

  const BestPriceChip({super.key, this.label = 'melhor'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF142A20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB89775),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFFB89775), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB89775),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
