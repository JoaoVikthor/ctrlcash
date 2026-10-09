import 'package:flutter/material.dart';

import '../utils/format.dart';
import '../utils/offer_comparator.dart';
import 'active_offer_marker.dart';
import 'best_price_chip.dart';
import 'delta_price_text.dart';

class OfferCard extends StatelessWidget {
  final RankedOffer ranked;
  final int totalOffers;
  final VoidCallback onSet;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const OfferCard({
    super.key,
    required this.ranked,
    required this.totalOffers,
    required this.onSet,
    required this.onEdit,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final offer = ranked.offer;
    final enabled = offer.isActive;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF142A20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.supplier,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCurrencyAbs(offer.packagePrice)} · ${offer.packageQuantity.toStringAsFixed(offer.packageQuantity % 1 == 0 ? 0 : 2)}',
                        style: const TextStyle(
                          color: Color(0xFF7A8B83),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ranked.isActive) ...[
                  const ActiveOfferMarker(active: true),
                  if (ranked.isBest) ...[
                    const SizedBox(width: 6),
                    const BestPriceChip(label: 'também é a melhor'),
                  ],
                ] else if (ranked.isBest)
                  const BestPriceChip(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  formatCurrencyAbs(offer.pricePerUnit),
                  style: const TextStyle(
                    color: Color(0xFFB89775),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '/un',
                  style: TextStyle(
                    color: Color(0xFF7A8B83),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (ranked.isActive)
                  const SizedBox.shrink()
                else if (ranked.deltaVsActive.abs() < 0.005)
                  const Text(
                    'sem referência',
                    style: TextStyle(
                      color: Color(0xFF7A8B83),
                      fontSize: 10,
                    ),
                  )
                else
                  DeltaPriceText(delta: ranked.deltaVsActive),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ranked.isActive)
                  Tooltip(
                    message: 'Oferta ativa',
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF165A41),
                        size: 22,
                      ),
                    ),
                  )
                else
                  _action(
                    Icons.check_circle_outline,
                    'Usar no ticket',
                    onSet,
                  ),
                const SizedBox(width: 8),
                _action(Icons.edit_outlined, 'Editar', onEdit),
                const SizedBox(width: 8),
                _action(
                  enabled
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  enabled ? 'Desativar' : 'Ativar',
                  onToggle,
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  _action(
                    Icons.delete_outline,
                    'Excluir',
                    onDelete!,
                    color: const Color(0xFF7A8B83),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color ?? const Color(0xFFB89775),
            size: 22,
          ),
        ),
      ),
    );
  }
}
