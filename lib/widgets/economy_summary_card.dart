import 'package:flutter/material.dart';

import '../utils/format.dart';
import '../utils/offer_comparator.dart';
import '../utils/product_calculator.dart';

class EconomySummaryCard extends StatelessWidget {
  final TicketScenario? scenario;
  final TicketResult ticket;
  final void Function(String ingredientId) onViewOffers;

  const EconomySummaryCard({
    super.key,
    required this.scenario,
    required this.ticket,
    required this.onViewOffers,
  });

  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);
  static const Color _colorTextSec = Color(0xFF7A8B83);

  bool get _hasAnyOffers =>
      ticket.lines.any((l) =>
          !l.missing && l.ingredient != null && l.ingredient!.offers.isNotEmpty);

  TicketLineSaving? get _topSaving {
    if (scenario == null || scenario!.lines.isEmpty) return null;
    return scenario!.lines
        .reduce((a, b) => a.saving > b.saving ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (scenario != null && scenario!.totalSaving > 0 && !scenario!.stillLoss) {
      return _buildEconomyCase(context);
    }

    if (scenario != null && scenario!.stillLoss) {
      return _buildStillLossCase(context);
    }

    if (_hasAnyOffers) {
      return _buildStableCase(context);
    }

    return _buildNoDataCase(context);
  }

  Widget _buildEconomyCase(BuildContext context) {
    final top = _topSaving!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.green.withValues(alpha: 0.35), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Melhor fornecedor possível',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '−${formatCurrencyAbs(scenario!.totalSaving)} no custo dos ingredientes',
            style: const TextStyle(
                color: Colors.green,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nada foi alterado no ticket.',
            style: TextStyle(color: _colorTextSec, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => onViewOffers(top.ingredientId),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ver ofertas de ${top.ingredientName}'),
          ),
        ],
      ),
    );
  }

  Widget _buildStableCase(BuildContext context) {
    final offerCount = ticket.lines
        .where((l) =>
            !l.missing && l.ingredient != null && l.ingredient!.offers.isNotEmpty)
        .fold<int>(0, (sum, l) => sum + l.ingredient!.offers.length);
    final fewOffers = offerCount <= 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Fornecedores já estáveis',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fewOffers
                ? 'As ofertas ativas deste produto já são as melhores entre as cadastradas. Poucas ofertas cadastradas — cadastre mais para comparar.'
                : 'As ofertas ativas deste produto já são as melhores entre as cadastradas.',
            style: const TextStyle(color: _colorTextSec, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStillLossCase(BuildContext context) {
    final top = _topSaving;
    final profit = scenario!.simulatedProfit;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.red.withValues(alpha: 0.35), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Ainda dá prejuízo com o melhor preço',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '−${formatCurrencyAbs(profit)} ainda de prejuízo',
            style: const TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mesmo usando o melhor fornecedor de cada insumo, o ticket ainda fica no vermelho. Considere revisar o preço de venda ou os custos fixos.',
            style: TextStyle(color: _colorTextSec, fontSize: 12),
          ),
          if (top != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => onViewOffers(top.ingredientId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ver ofertas'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDataCase(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront_outlined, color: _colorGold, size: 18),
              SizedBox(width: 8),
              Text(
                'Sem dados de fornecedores',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre ofertas nos insumos para descobrir se há economia possível.',
            style: TextStyle(color: _colorTextSec, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => onViewOffers(''),
            style: OutlinedButton.styleFrom(
              foregroundColor: _colorGold,
              side: const BorderSide(color: _colorGold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Gerenciar insumos'),
          ),
        ],
      ),
    );
  }
}
