import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/ingredient_offer.dart';
import '../providers/ingredient_provider.dart';
import '../utils/format.dart';
import '../utils/offer_comparator.dart';
import '../widgets/active_offer_marker.dart';
import '../widgets/best_price_chip.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/offer_card.dart';
import '../widgets/offer_limit_banner.dart';
import '../widgets/search_field.dart';

class IngredientOffersScreen extends StatefulWidget {
  final String ingredientId;

  const IngredientOffersScreen({super.key, required this.ingredientId});

  @override
  State<IngredientOffersScreen> createState() => _IngredientOffersScreenState();
}

class _IngredientOffersScreenState extends State<IngredientOffersScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);
  static const Color _colorTextSec = Color(0xFF7A8B83);

  String _query = '';
  int _filterIndex = 0;
  bool _onlyEconomy = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngredientProvider>();
    final ingredient = provider.asMap[widget.ingredientId];

    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Voltar',
        ),
        title: Text(
          ingredient == null ? 'Ofertas' : 'Ofertas de ${ingredient.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, color: _colorGold),
            tooltip: 'Histórico de preços',
            onPressed: () => Navigator.pushNamed(context, '/audit-logs'),
          ),
        ],
      ),
      body: _buildBody(provider, ingredient),
      bottomNavigationBar: ingredient == null
          ? null
          : _buildBottomCTA(ingredient),
    );
  }

  Widget _buildBody(IngredientProvider provider, Ingredient? ingredient) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _colorGold),
      );
    }
    if (provider.error != null) {
      return ErrorState(
        message: 'Não foi possível carregar as ofertas.',
        onRetry: provider.reload,
      );
    }
    if (ingredient == null) {
      return const ErrorState(message: 'Insumo não encontrado.');
    }

    final offers = ingredient.offers;
    final ranked = OfferComparator.rankAll(
      offers,
      activeOfferId: ingredient.activeOffer?.id,
    );
    final filtered = _applyFilters(ranked);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        _buildSummaryCard(ingredient),
        if (OfferComparator.hasDifferentPackageSizes(offers)) ...[
          const SizedBox(height: 12),
          _buildPackageSizeBanner(),
        ],
        const SizedBox(height: 12),
        const Text(
          'Você escolhe qual oferta entra no ticket. O app não troca sozinho.',
          style: TextStyle(color: _colorTextSec, fontSize: 12),
        ),
        const SizedBox(height: 16),
        AppSearchField(
          hint: 'Buscar fornecedor…',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        AppFilterChipRow(
          options: const ['Todas', 'Ativas', 'Inativas', 'Padrão'],
          selectedIndex: _filterIndex,
          onSelected: (index) => setState(() => _filterIndex = index),
        ),
        const SizedBox(height: 12),
        _buildEconomyToggle(),
        const SizedBox(height: 16),
        _buildCounter(ingredient),
        const SizedBox(height: 16),
        if (offers.isEmpty) ...[
          _buildEmptyOrLegacy(ingredient),
        ] else if (filtered.isEmpty) ...[
          _buildNoFilterResult(),
        ] else ...[
          ...filtered.map((r) => _buildOfferCard(ingredient, r)),
        ],
        if (ingredient.offersCount >= 15) ...[
          const SizedBox(height: 16),
          OfferLimitBanner(current: ingredient.offersCount),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(Ingredient ingredient) {
    final active = ingredient.activeOffer;
    final best = ingredient.bestActiveOffer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ingredient.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preço por unidade de referência: ${formatCurrencyAbs(ingredient.pricePerUnit)}/${ingredient.unit.label}',
            style: const TextStyle(color: _colorTextSec, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (active != null) ...[
                const ActiveOfferMarker(active: true),
                const SizedBox(width: 2),
                Text(
                  active.supplier,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ] else
                const Text(
                  'Nenhuma oferta ativa',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              if (active != null &&
                  best != null &&
                  active.id == best.id) ...[
                const BestPriceChip(label: 'também é a melhor'),
              ] else if (best != null) ...[
                BestPriceChip(label: 'melhor: ${best.supplier}'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSizeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Atenção: embalagens de tamanhos diferentes. Compare o preço por unidade.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEconomyToggle() {
    return GestureDetector(
      onTap: () => setState(() => _onlyEconomy = !_onlyEconomy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _colorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _onlyEconomy
                ? _colorGold
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: _onlyEconomy ? _colorGold : _colorTextSec,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'só com economia',
              style: TextStyle(
                color: _onlyEconomy ? _colorGold : _colorTextSec,
                fontSize: 13,
                fontWeight:
                    _onlyEconomy ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(Ingredient ingredient) {
    final atLimit = ingredient.offersCount >= 15;
    return Row(
      children: [
        Text(
          '${ingredient.offersCount} de 15 ofertas',
          style: const TextStyle(color: _colorTextSec, fontSize: 12),
        ),
        if (atLimit) ...[
          const SizedBox(width: 8),
          const Text(
            'Limite de 15 atingido',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyOrLegacy(Ingredient ingredient) {
    final hasLegacy = ingredient.purchasePrice > 0 && ingredient.packageQuantity > 0;
    if (!hasLegacy) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: 'Nenhuma oferta cadastrada',
        message:
            'Cadastre fornecedores para comparar preços e escolher quem entra no ticket.',
        actionLabel: 'Adicionar oferta',
        onAction: () => Navigator.pushNamed(
          context,
          '/offer-form',
          arguments: {'ingredientId': ingredient.id},
        ),
      );
    }

    final legacy = OfferComparator.syntheticLegacyOffer(ingredient);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: _colorGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preço base do insumo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCurrencyAbs(legacy.pricePerUnit)}/${ingredient.unit.label}',
            style: const TextStyle(
              color: _colorGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cadastre ofertas para comparar.',
            style: TextStyle(color: _colorTextSec, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResult() {
    return Column(
      children: [
        const Icon(Icons.search_off, color: _colorTextSec, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Nenhuma oferta corresponde aos filtros.',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _query = '';
            _filterIndex = 0;
            _onlyEconomy = false;
          }),
          child: const Text(
            'Limpar filtros',
            style: TextStyle(color: _colorGold, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(Ingredient ingredient, RankedOffer ranked) {
    return OfferCard(
      ranked: ranked,
      totalOffers: ingredient.offersCount,
      onSet: () => _activateOffer(ingredient, ranked.offer),
      onEdit: () => Navigator.pushNamed(
        context,
        '/offer-form',
        arguments: {
          'ingredientId': ingredient.id,
          'offer': ranked.offer,
        },
      ),
      onToggle: () => _toggleOffer(ingredient, ranked.offer),
    );
  }

  Widget _buildBottomCTA(Ingredient ingredient) {
    final disabled = ingredient.offersCount >= 15;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ElevatedButton(
          onPressed: disabled
              ? null
              : () => Navigator.pushNamed(
                    context,
                    '/offer-form',
                    arguments: {'ingredientId': ingredient.id},
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _colorGreenPrimary,
            disabledBackgroundColor:
                _colorGreenPrimary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Adicionar oferta',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<RankedOffer> _applyFilters(List<RankedOffer> ranked) {
    final query = _query.trim().toLowerCase();
    var list = ranked.where((r) {
      final offer = r.offer;
      switch (_filterIndex) {
        case 1:
          return offer.isActive;
        case 2:
          return !offer.isActive;
        case 3:
          return offer.source == 'migration';
        default:
          return true;
      }
    }).where((r) {
      if (query.isEmpty) return true;
      return r.offer.supplier.toLowerCase().contains(query);
    }).toList();

    if (_onlyEconomy) {
      list = list
          .where((r) => !r.isActive && r.deltaVsActive < -0.005)
          .toList();
    }

    return list;
  }

  Future<void> _activateOffer(Ingredient ingredient, IngredientOffer offer) async {
    final delta = offer.pricePerUnit -
        (ingredient.activeOffer?.pricePerUnit ?? offer.pricePerUnit);
    String body;
    if (delta.abs() < 0.005) {
      body = '${offer.supplier} · ${formatCurrencyAbs(offer.pricePerUnit)}/un';
    } else if (delta < 0) {
      body =
          '${offer.supplier} · ${formatCurrencyAbs(offer.pricePerUnit)}/un\nEconomia de ${formatCurrencyAbs(delta.abs())} por unidade em relação à ativa.';
    } else {
      body =
          '${offer.supplier} · ${formatCurrencyAbs(offer.pricePerUnit)}/un\nFicará ${formatCurrencyAbs(delta)} mais caro por unidade.';
    }

    final provider = context.read<IngredientProvider>();

    final ok = await ConfirmActionDialog.show(
      context,
      title: 'Usar esta oferta no ticket?',
      body: body,
      note:
          'Você pode trocar de volta quando quiser. O app não altera automaticamente.',
    );
    if (!ok) return;

    final previousActiveOfferId = ingredient.activeOffer?.id;

    try {
      await provider.setActiveOffer(ingredient.id, offer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oferta de ${offer.supplier} agora é a ativa.'),
          backgroundColor: _colorGold,
          action: previousActiveOfferId != null
              ? SnackBarAction(
                  label: 'Desfazer',
                  textColor: Colors.white,
                  onPressed: () => provider.setActiveOffer(
                    ingredient.id,
                    previousActiveOfferId,
                  ),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível trocar a oferta.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleOffer(Ingredient ingredient, IngredientOffer offer) async {
    final newState = !offer.isActive;
    try {
      await context
          .read<IngredientProvider>()
          .toggleOfferActive(ingredient.id, offer.id, newState);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar oferta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
