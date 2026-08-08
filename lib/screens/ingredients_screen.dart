import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';

class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorCard = Color(0xFF142A20);
  static const colorTextSec = Color(0xFF7A8B83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'ingredients'),
      appBar: const AppBrandedHeader(title: 'Insumos'),
      body: Consumer<IngredientProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return const Center(
                child: CircularProgressIndicator(color: colorGold));
          }
          if (prov.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro: ${prov.error}',
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (prov.list.isEmpty) {
            return _buildEmpty(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            itemCount: prov.list.length,
            itemBuilder: (context, i) =>
                _buildIngredientCard(context, prov.list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/ingredient-form'),
        backgroundColor: const Color(0xFF165A41),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 56, color: colorTextSec),
            const SizedBox(height: 12),
            const Text('Nenhum insumo cadastrado',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Cadastre os materiais que você compra para fabricar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorTextSec, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/ingredient-form'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Cadastrar Insumo',
                  style: TextStyle(color: Colors.white)),
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

  Widget _buildIngredientCard(BuildContext context, Ingredient ing) {
    return Dismissible(
      key: ValueKey(ing.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) => _confirmDelete(context, ing),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colorCard, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorBackground,
              child: const Icon(Icons.science_outlined,
                  color: colorGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ing.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                      '${formatCurrencyAbs(ing.purchasePrice)} / ${ing.packageQuantity.toStringAsFixed(ing.packageQuantity % 1 == 0 ? 0 : 2)} ${ing.unit.label}',
                      style: const TextStyle(color: colorTextSec, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Preço por unidade',
                    style: TextStyle(color: colorTextSec, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                    '${formatCurrencyAbs(ing.pricePerUnit)}/${ing.unit.label}',
                    style: const TextStyle(
                        color: colorGold, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Ingredient ing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorCard,
        title: const Text('Excluir insumo?',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text('"${ing.name}" será removido. Produtos que o usam podem ficar sem custo calculado.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: colorGold))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<IngredientProvider>().deleteIngredient(ing.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Insumo excluído.'),
              backgroundColor: colorGold),
        );
      }
      return true;
    }
    return false;
  }
}