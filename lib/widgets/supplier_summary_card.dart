import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../utils/format.dart';
import '../utils/price_panel_aggregator.dart';
import 'delta_price_text.dart';

class SupplierSummaryCard extends StatefulWidget {
  final SupplierPanelEntry entry;
  final void Function(String ingredientId) onIngredientTap;

  const SupplierSummaryCard({
    super.key,
    required this.entry,
    required this.onIngredientTap,
  });

  @override
  State<SupplierSummaryCard> createState() => _SupplierSummaryCardState();
}

class _SupplierSummaryCardState extends State<SupplierSummaryCard> {
  bool _expanded = false;

  static const Color _colorCard = Color(0xFF142A20);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorTextSec = Color(0xFF7A8B83);

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fornece ${entry.productsCount} insumos · ★ melhor em ${entry.bestCount}',
                  style: const TextStyle(
                    color: _colorTextSec,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 10),
                _buildBestPills(),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            ...widget.entry.rows.map(_buildRow),
          ],
        ],
      ),
    );
  }

  Widget _buildBestPills() {
    final bestRows = widget.entry.rows.where((r) => r.isBest).toList();
    if (bestRows.isEmpty) return const SizedBox.shrink();
    final shown = bestRows.take(3).toList();
    final remaining = bestRows.length - shown.length;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...shown.map((r) => _bestPill(r.entry.ingredient.name)),
        if (remaining > 0) _countPill('+$remaining'),
      ],
    );
  }

  Widget _bestPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _colorGold, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: _colorGold, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _colorGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _colorTextSec,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRow(SupplierPanelRow row) {
    final ing = row.entry.ingredient;
    final color = _deltaColor(row.deltaVsBest);
    final label = row.isBest
        ? '★ melhor preço · ${row.position}º de ${row.ofTotal}'
        : '${row.position}º de ${row.ofTotal}';
    return GestureDetector(
      onTap: () => widget.onIngredientTap(ing.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _colorCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ing.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatCurrencyAbs(row.pricePerUnit)}/${ing.unit.label}',
                  style: const TextStyle(
                    color: _colorGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Semantics(
                  label: 'paga ${formatCurrencyAbs(row.deltaVsBest)} por unidade a mais que o melhor preço',
                  child: DeltaPriceText(delta: row.deltaVsBest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _deltaColor(double delta) {
    if (delta <= 0) return Colors.green;
    if (delta < 1) return Colors.orange;
    return Colors.red;
  }
}
