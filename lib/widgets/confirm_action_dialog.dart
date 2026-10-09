import 'package:flutter/material.dart';

class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String body;
  final String? note;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.body,
    this.note,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    String? note,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: title,
        body: body,
        note: note,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final noteText = note;
    return AlertDialog(
      backgroundColor: const Color(0xFF142A20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (noteText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                noteText,
                style: const TextStyle(
                  color: Color(0xFF7A8B83),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Color(0xFFB89775),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Confirmar',
            style: TextStyle(
              color: Color(0xFF165A41),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
