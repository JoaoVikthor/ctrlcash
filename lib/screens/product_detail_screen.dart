import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/product_provider.dart';
import '../utils/format.dart';
import '../utils/product_calculator.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);
  static const Color _colorTextSec = Color(0xFF7A8B83);

  @override
  Widget build(BuildContext context) {
    final productId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ticket do Produto',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (productId != null)
            PopupMenuButton<String>(
              color: _colorCard,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) async {
                if (v == 'edit') {
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/product-form',
                      arguments: productId);
                } else if (v == 'delete') {
                  final ok = await _confirmDelete(context);
                  if (ok == true && context.mounted) {
                    await context.read<ProductProvider>().deleteProduct(productId);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Produto excluído.'),
                          backgroundColor: _colorGold),
                    );
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar',
                        style: TextStyle(color: Colors.white))),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Excluir',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      body: productId == null
          ? const Center(
              child: Text('Produto não encontrado.',
                  style: TextStyle(color: Colors.white54)))
          : Consumer2<ProductProvider, IngredientProvider>(
              builder: (context, pp, ip, _) {
                final product = pp.list
                    .where((p) => p.id == productId)
                    .firstOrNull;
                if (product == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            color: _colorTextSec, size: 40),
                        const SizedBox(height: 8),
                        const Text('Produto não encontrado.',
                            style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _colorGreenPrimary),
                          child: const Text('Voltar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
                final ticket =
                    ProductCalculator.calculate(product, ip.asMap);
                return _buildTicket(context, ticket);
              },
            ),
    );
  }

  Widget _buildTicket(BuildContext context, TicketResult t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.product.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          if (t.product.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(t.product.description,
                style: const TextStyle(color: _colorTextSec, fontSize: 14)),
          ],
          const SizedBox(height: 24),
          _buildVerdictCard(t),
          const SizedBox(height: 24),
          _buildSectionTitle('Receita por ingrediente', Icons.restaurant_menu),
          const SizedBox(height: 12),
          if (t.hasMissingIngredients)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4))),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Um ou mais insumos foram removidos. O custo pode estar incompleto.',
                        style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
                ],
              ),
            ),
          for (final line in t.lines) _buildIngredientLine(line),
          const SizedBox(height: 8),
          _costSummaryRow('Subtotal ingredientes',
              formatCurrencyAbs(t.ingredientsTotal)),
          _costSummaryRow('Mão de obra', formatCurrencyAbs(t.laborCost)),
          _costSummaryRow('Embalagem', formatCurrencyAbs(t.packagingCost)),
          const Divider(color: Colors.white24, height: 24),
          _costSummaryRow('Custo total', formatCurrencyAbs(t.totalCost),
              bold: true),
          _costSummaryRow('Preço de venda', formatCurrencyAbs(t.salePrice),
              bold: true),
          const Divider(color: Colors.white24, height: 24),
          const SizedBox(height: 8),
          _buildFinalVerdict(t),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _colorGold, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerdictCard(TicketResult t) {
    final isLucro = t.isLucro;
    final color = isLucro ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5)),
      child: Column(
        children: [
          Icon(isLucro ? Icons.check_circle : Icons.cancel,
              color: color, size: 40),
          const SizedBox(height: 8),
          Text(
              isLucro ? 'ESTE PRODUTO DÁ LUCRO' : 'ESTE PRODUTO DÁ PREJUÍZO',
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              '${isLucro ? '+' : ''}${formatCurrency(t.profit)}',
              style: TextStyle(
                  color: color, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
              'Margem de ${t.marginPercent.toStringAsFixed(1)}%  •  Markup ${t.markup.toStringAsFixed(2)}x',
              style: const TextStyle(color: _colorTextSec, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildIngredientLine(LineCost line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: _colorGold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.ingredientName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (line.missing)
                  const Text('Insumo removido do parque',
                      style: TextStyle(color: Colors.red, fontSize: 11))
                else
                  Text(
                      '${line.item.quantity.toStringAsFixed(line.item.quantity % 1 == 0 ? 0 : 2)} ${line.ingredient?.unit.label ?? ''} × ${formatCurrencyAbs(line.unitPrice)}/${line.ingredient?.unit.label ?? ''}',
                      style:
                          const TextStyle(color: _colorTextSec, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('custo',
                    style: TextStyle(color: _colorTextSec, fontSize: 10)),
                Text(line.missing ? '—' : formatCurrencyAbs(line.lineCost),
                    style: const TextStyle(
                        color: _colorGold, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _costSummaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? Colors.white : Colors.white70,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: bold ? Colors.white : _colorGold,
                  fontWeight: FontWeight.bold,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildFinalVerdict(TicketResult t) {
    final isLucro = t.isLucro;
    final color = isLucro ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Veredito',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(isLucro ? Icons.trending_up : Icons.trending_down,
                  color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                  isLucro ? 'LUCRO' : 'PREJUÍZO',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _colorCard,
        title: const Text('Excluir produto?',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
            'A ficha técnica e o ticket serão removidos permanentemente.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancelar', style: TextStyle(color: _colorGold))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}