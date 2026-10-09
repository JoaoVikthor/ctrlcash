import 'package:flutter/material.dart';

class OfferLimitBanner extends StatelessWidget {
  final int current;

  const OfferLimitBanner({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final remaining = 15 - current;
    final atLimit = remaining <= 0;
    final text = atLimit
        ? 'Limite de 15 ofertas atingido'
        : 'Restam $remaining ofertas';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
