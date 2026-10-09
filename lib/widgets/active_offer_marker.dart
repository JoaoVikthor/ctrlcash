import 'package:flutter/material.dart';

class ActiveOfferMarker extends StatelessWidget {
  final bool active;

  const ActiveOfferMarker({super.key, this.active = true});

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF165A41),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'ATIVA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'INATIVA',
        style: TextStyle(
          color: Color(0xFF7A8B83),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
