import 'package:flutter/material.dart';

import '../models/price_audit_log.dart';
import '../utils/format.dart';

class AuditEntryTile extends StatelessWidget {
  final PriceAuditLog log;

  const AuditEntryTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final destructive = _isDestructive(log.action);
    final icon = _iconFor(log.action);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: destructive ? Colors.red : const Color(0xFFB89775),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _detail(),
                  style: const TextStyle(
                    color: Color(0xFF7A8B83),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _time(),
                  style: const TextStyle(
                    color: Color(0xFF7A8B83),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDestructive(String action) => action.contains('.delete');

  IconData _iconFor(String action) {
    if (action.contains('.create')) return Icons.add_circle_outline;
    if (action.contains('.update')) return Icons.edit_outlined;
    if (action.contains('.delete')) return Icons.delete_outline;
    if (action.contains('setActive') || action.contains('toggleActive')) {
      return Icons.check_circle_outline;
    }
    if (action.contains('migration')) return Icons.sync;
    return Icons.receipt_long;
  }

  String _detail() {
    final previous = log.previousPrice;
    final next = log.newPrice;
    final supplier = log.supplier;

    if (previous != null && next != null) {
      return 'de ${formatCurrencyAbs(previous)} para ${formatCurrencyAbs(next)}';
    }
    if (next != null) {
      return 'novo valor: ${formatCurrencyAbs(next)}';
    }
    if (supplier != null && supplier.isNotEmpty) {
      return supplier;
    }
    return '';
  }

  String _time() {
    final timestamp = log.timestamp;
    if (timestamp == null) return '';
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${formatDateShort(timestamp)} · $hour:$minute';
  }
}
