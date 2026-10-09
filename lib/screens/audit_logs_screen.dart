import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/price_audit_log.dart';
import '../providers/ingredient_provider.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/audit_entry_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/search_field.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorCard = Color(0xFF142A20);
  static const Color _colorTextSec = Color(0xFF7A8B83);

  String _query = '';
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<IngredientProvider>();

    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: const AppBrandedHeader(title: 'Auditoria', showBack: true),
      body: StreamBuilder<List<PriceAuditLog>>(
        stream: provider.auditLogs,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              message: 'Não foi possível carregar o histórico.',
              onRetry: () => setState(() {}),
            );
          }
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasData) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sem registros',
              message: 'Nenhuma alteração de preço foi registrada ainda.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB89775),
              ),
            );
          }

          final logs = _applyFilters(snapshot.data!);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registro de ações',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tudo que altera custos, ofertas e produtos aparece aqui.',
                      style: TextStyle(
                        color: _colorTextSec,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppSearchField(
                      hint: 'Buscar por ação, produto ou fornecedor…',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 12),
                    AppFilterChipRow(
                      options: const [
                        'Tudo',
                        'Insumos',
                        'Ofertas',
                        'Produtos',
                        'Sistema',
                      ],
                      selectedIndex: _filterIndex,
                      onSelected: (index) =>
                          setState(() => _filterIndex = index),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: logs.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long,
                        title: 'Nenhuma ação registrada',
                        message:
                            'Alterações em insumos, ofertas e produtos aparecerão aqui.',
                      )
                    : _buildTimeline(logs),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(List<PriceAuditLog> logs) {
    final groups = _groupByDay(logs);
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final dayLogs = groups[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _dayLabel(key),
                style: const TextStyle(
                  color: _colorTextSec,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: _colorCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ...dayLogs.asMap().entries.map((entry) {
                    final log = entry.value;
                    final isLast = entry.key == dayLogs.length - 1;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => _showDetail(context, log),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AuditEntryTile(log: log),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                            color: Colors.white24,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDetail(BuildContext context, PriceAuditLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _iconFor(log.action),
                      color: _isDestructive(log.action)
                          ? Colors.red
                          : const Color(0xFFB89775),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        log.summary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _fullTimestamp(log),
                  style: const TextStyle(
                    color: _colorTextSec,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                if (log.previousPrice != null && log.newPrice != null)
                  Text(
                    'Anterior: ${formatCurrencyAbs(log.previousPrice!)} → Novo: ${formatCurrencyAbs(log.newPrice!)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  )
                else if (log.newPrice != null)
                  Text(
                    'Novo valor: ${formatCurrencyAbs(log.newPrice!)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                if (log.supplier != null && log.supplier!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fornecedor: ${log.supplier}',
                    style: const TextStyle(
                      color: _colorTextSec,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<PriceAuditLog> _applyFilters(List<PriceAuditLog> logs) {
    final query = _query.trim().toLowerCase();
    var result = logs;

    if (query.isNotEmpty) {
      result = result.where((log) {
        final text =
            '${log.action} ${log.summary} ${log.supplier ?? ''}'.toLowerCase();
        return text.contains(query);
      }).toList();
    }

    switch (_filterIndex) {
      case 1:
        result = result.where((log) => log.entityType == 'ingredient').toList();
      case 2:
        result = result.where((log) => log.entityType == 'offer').toList();
      case 3:
        result = result.where((log) => log.entityType == 'product').toList();
      case 4:
        result = result.where((log) {
          return log.entityType == 'migration' ||
              log.source == 'system' ||
              !['ingredient', 'offer', 'product']
                  .contains(log.entityType);
        }).toList();
    }

    return result;
  }

  Map<DateTime, List<PriceAuditLog>> _groupByDay(List<PriceAuditLog> logs) {
    final groups = <DateTime, List<PriceAuditLog>>{};
    for (final log in logs) {
      final timestamp = log.timestamp;
      if (timestamp == null) continue;
      final day = DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day,
      );
      groups.putIfAbsent(day, () => []).add(log);
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (day == today) return 'Hoje';
    if (day == yesterday) return 'Ontem';
    return formatDate(day);
  }

  String _fullTimestamp(PriceAuditLog log) {
    final timestamp = log.timestamp;
    if (timestamp == null) return '';
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${formatDate(timestamp)} às $hour:$minute';
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
}
