import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ingredient_provider.dart';
import '../utils/format.dart';
import '../utils/price_panel_aggregator.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/panel_product_card.dart';
import '../widgets/search_field.dart';
import '../widgets/supplier_summary_card.dart';

class ComparePricesScreen extends StatefulWidget {
  const ComparePricesScreen({super.key});

  @override
  State<ComparePricesScreen> createState() => _ComparePricesScreenState();
}

class _ComparePricesScreenState extends State<ComparePricesScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);
  static const Color _colorTextSec = Color(0xFF7A8B83);

  int _tabIndex = 0;
  String _query = '';
  String _supplier = '';
  int _sortIndex = 0;

  PanelSort get _panelSort {
    switch (_sortIndex) {
      case 0:
        return PanelSort.economy;
      case 1:
        return PanelSort.lowest;
      default:
        return PanelSort.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngredientProvider>();

    return Scaffold(
      backgroundColor: _colorBackground,
      drawer: const AppDrawer(currentRoute: 'compare-prices'),
      appBar: const AppBrandedHeader(title: 'Comparar preços'),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(IngredientProvider provider) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _colorGold),
      );
    }
    if (provider.error != null) {
      return ErrorState(
        message: 'Erro ao carregar ofertas: ${provider.error}',
        onRetry: provider.reload,
      );
    }

    final entries = PricePanelAggregator.buildPanel(provider.asMap);
    final summary = PricePanelAggregator.summarize(entries);
    final filtered = PricePanelAggregator.filterPanel(
      entries,
      query: _query,
      supplier: _supplier,
    );
    final sorted = PricePanelAggregator.sortPanel(filtered, _panelSort);

    if (summary.productsWithOffers == 0) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        AppFilterChipRow(
          options: const ['Por produto', 'Por fornecedor'],
          selectedIndex: _tabIndex,
          onSelected: (index) => setState(() => _tabIndex = index),
        ),
        const SizedBox(height: 16),
        if (_tabIndex == 0) ...[
          _buildEcoLine(summary),
          AppSearchField(
            hint: 'Buscar produto ou fornecedor…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          _buildSortChips(),
          const SizedBox(height: 12),
          _buildSupplierFilter(entries),
          const SizedBox(height: 16),
          if (summary.suppliersCount == 1) _buildOneSupplierBanner(),
          if (sorted.isEmpty) ...[
            _buildNoFilterResult(),
          ] else ...[
            ...sorted.map((e) => PanelProductCard(
                  entry: e,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/ingredient-offers',
                    arguments: e.ingredient.id,
                  ),
                )),
          ],
        ] else ...[
          _buildSupplierTab(entries),
        ],
      ],
    );
  }

  Widget _buildEcoLine(PanelSummary summary) {
    if (summary.productsPayMore > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_down, color: Colors.green, size: 17),
                SizedBox(width: 8),
                Text(
                  'Economia possível',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatCurrencyAbs(summary.economySumPerUnit),
                    style: const TextStyle(
                      color: _colorGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' · combinados por unidade em ${summary.productsPayMore} insumos',
                    style: const TextStyle(
                      color: _colorTextSec,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Você já usa o melhor preço entre as ofertas cadastradas.',
        style: TextStyle(color: _colorTextSec, fontSize: 13),
      ),
    );
  }

  Widget _buildSortChips() {
    return AppFilterChipRow(
      options: const ['Maior economia', 'Menor preço', 'Nome'],
      selectedIndex: _sortIndex,
      onSelected: (index) => setState(() => _sortIndex = index),
    );
  }

  Widget _buildSupplierFilter(List<ProductPanelEntry> entries) {
    final suppliers = _supplierOptions(entries);
    if (suppliers.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suppliers.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSupplierChip(
              label: 'Todos',
              selected: _supplier.isEmpty,
              onTap: () => setState(() => _supplier = ''),
            );
          }
          final name = suppliers[index - 1];
          return _buildSupplierChip(
            label: name,
            selected: _isSameSupplier(name, _supplier),
            onTap: () => setState(() => _supplier = name),
          );
        },
      ),
    );
  }

  List<String> _supplierOptions(List<ProductPanelEntry> entries) {
    final displayNames = <String, String>{};
    for (final entry in entries) {
      for (final name in entry.supplierNames) {
        final key = name.trim().toLowerCase();
        displayNames.putIfAbsent(key, () => name.trim());
      }
    }
    final names = displayNames.values.toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  Widget _buildSupplierChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final display = label == 'Todos' ? label : _capitalize(label);
    final chip = GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF165A41) : _colorCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          display.length > 18 ? '${display.substring(0, 18)}…' : display,
          style: TextStyle(
            color: selected ? Colors.white : _colorTextSec,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    if (label != 'Todos' && label.length > 18) {
      return Tooltip(
        message: display,
        child: chip,
      );
    }
    return chip;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  bool _isSameSupplier(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  Widget _buildOneSupplierBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.38)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cadastre mais fornecedores para ver o comparativo.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 11,
              ),
            ),
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
            _supplier = '';
            _sortIndex = 0;
          }),
          child: const Text(
            'Limpar filtros',
            style: TextStyle(
              color: _colorGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierTab(List<ProductPanelEntry> entries) {
    final report = PricePanelAggregator.buildSupplierReport(entries);
    if (report.isEmpty) {
      return const EmptyState(
        icon: Icons.storefront_outlined,
        title: 'Nenhum fornecedor com ofertas',
        message:
            'Cadastre ofertas de fornecedores para ver o comparativo por fornecedor.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: report
          .map((e) => SupplierSummaryCard(
                entry: e,
                onIngredientTap: (id) => Navigator.pushNamed(
                  context,
                  '/ingredient-offers',
                  arguments: id,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.storefront_outlined,
      title: 'Nenhuma oferta cadastrada ainda',
      message:
          'Cadastre preços de fornecedores para comparar e escolher quem entra no ticket.',
      actionLabel: 'Gerenciar insumos',
      onAction: () => Navigator.pushNamed(context, '/ingredients'),
    );
  }
}
