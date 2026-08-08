import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorCard = Color(0xFF142A20);
  static const colorGreenPrimary = Color(0xFF165A41);
  static const colorTextSec = Color(0xFF7A8B83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'budgets'),
      appBar: const AppBrandedHeader(title: 'Orçamentos'),
      body: Consumer2<BudgetProvider, TransactionProvider>(
        builder: (context, bp, tx, _) {
          if (bp.loading) {
            return const Center(
                child: CircularProgressIndicator(color: colorGold));
          }
          if (bp.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: colorTextSec, size: 48),
                  const SizedBox(height: 8),
                  Text('Erro: ${bp.error}',
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          final spentByCat = _spentByCategory(tx);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Seus Limites Mensais',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'Acompanhe quanto já gastou de cada categoria neste mês.',
                    style: TextStyle(color: colorTextSec, fontSize: 13)),
                const SizedBox(height: 20),
                if (bp.budgets.isEmpty) _buildEmpty(context),
                for (final b in bp.budgets)
                  _buildBudgetProgress(
                      context, b, spentByCat[b.category] ?? 0),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/budget-form'),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Novo Orçamento',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorGreenPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, double> _spentByCategory(TransactionProvider tx) {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final t in tx.transactions) {
      if (t.type.isReceita) continue;
      if (t.date.month == now.month && t.date.year == now.year) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          const Icon(Icons.account_balance_outlined,
              color: colorTextSec, size: 40),
          const SizedBox(height: 12),
          const Text('Nenhum orçamento criado',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Defina limites para controlar seus gastos.',
              style: TextStyle(color: colorTextSec, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(
      BuildContext context, Budget b, double spent) {
    final percent = b.limit > 0 ? (spent / b.limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > b.limit;
    final remaining = b.limit - spent;
    final cat = findCategory(b.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(cat.icon, color: cat.color, size: 18),
                  const SizedBox(width: 8),
                  Text(b.category,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF142A20),
                icon: const Icon(Icons.more_vert,
                    color: Colors.white54, size: 18),
                onSelected: (v) async {
                  if (v == 'edit') {
                    if (!context.mounted) return;
                    Navigator.pushNamed(context, '/budget-form',
                        arguments: b);
                  } else if (v == 'delete') {
                    await context.read<BudgetProvider>().deleteBudget(b.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Orçamento excluído.'),
                          backgroundColor: colorGold),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar',
                          style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${formatCurrencyAbs(spent)} / ${formatCurrencyAbs(b.limit)}',
                  style: TextStyle(
                      color: isOver ? Colors.red : colorGold, fontSize: 13)),
              Text(isOver ? 'Ultrapassou' : 'Falta ${formatCurrencyAbs(remaining)}',
                  style: TextStyle(
                      color: isOver ? Colors.red : Colors.green, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              color: isOver ? Colors.red : cat.color,
              backgroundColor: colorBackground,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text('${(percent * 100).toStringAsFixed(0)}% usado',
              style: const TextStyle(color: colorTextSec, fontSize: 11)),
        ],
      ),
    );
  }
}