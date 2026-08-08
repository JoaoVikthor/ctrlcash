import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ingredient_provider.dart';
import '../providers/product_provider.dart';
import '../utils/format.dart';
import '../utils/product_calculator.dart';
import '../widgets/app_drawer.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorCard = Color(0xFF142A20);
  static const colorTextSec = Color(0xFF7A8B83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'products'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Produtos',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: colorGold),
            tooltip: 'Identificar produto',
            onPressed: () =>
                Navigator.pushNamed(context, '/product-scanner'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<ProductProvider, IngredientProvider>(
        builder: (context, pp, ip, _) {
          if (pp.loading) {
            return const Center(
                child: CircularProgressIndicator(color: colorGold));
          }
          if (pp.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro: ${pp.error}',
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (pp.list.isEmpty) {
            return _buildEmpty(context, ip.list.isEmpty);
          }
          final ingredients = ip.asMap;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            itemCount: pp.list.length,
            itemBuilder: (context, i) {
              final product = pp.list[i];
              final ticket =
                  ProductCalculator.calculate(product, ingredients);
              return _buildProductCard(context, product, ticket);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final hasIngredients =
              context.read<IngredientProvider>().list.isNotEmpty;
          Navigator.pushNamed(context,
              hasIngredients ? '/product-form' : '/ingredient-form');
        },
        backgroundColor: const Color(0xFF165A41),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool noIngredients) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lunch_dining_outlined,
                size: 56, color: colorTextSec),
            const SizedBox(height: 12),
            const Text('Nenhum produto cadastrado',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
                noIngredients
                    ? 'Cadastre insumos primeiro, depois crie sua ficha técnica.'
                    : 'Crie uma ficha técnica para saber se seu produto dá lucro ou prejuízo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: colorTextSec, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context,
                  noIngredients ? '/ingredient-form' : '/product-form'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(noIngredients ? 'Cadastrar Insumo' : 'Criar Ficha Técnica',
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF165A41),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, product, TicketResult ticket) {
    final isLucro = ticket.isLucro;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, '/product-detail',
          arguments: ticket.product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colorCard, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorBackground,
                  child: Icon(
                      ticket.product.recipe.isEmpty
                          ? Icons.inventory_outlined
                          : Icons.lunch_dining_outlined,
                      color: colorGold,
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.product.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                          '${ticket.product.recipe.length} ingrediente(s) • Venda: ${formatCurrencyAbs(ticket.product.salePrice)}',
                          style: const TextStyle(
                              color: colorTextSec, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isLucro ? Colors.green : Colors.red)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Custo total',
                          style:
                              TextStyle(color: colorTextSec, fontSize: 11)),
                      Text(formatCurrencyAbs(ticket.totalCost),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(isLucro ? 'Lucro' : 'Prejuízo',
                          style: TextStyle(
                              color: isLucro ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${isLucro ? '+' : ''}${formatCurrency(ticket.profit)}',
                          style: TextStyle(
                              color: isLucro ? Colors.green : Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}