import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/categories.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_pie_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorGreenPrimary = Color(0xFF165A41);
  static const colorCard = Color(0xFF142A20);
  static const colorTextSec = Color(0xFF7A8B83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'dashboard'),
      appBar: const AppBrandedHeader(),
      body: Consumer2<TransactionProvider, UserProvider>(
        builder: (context, tx, user, _) {
          if (tx.loading) {
            return const Center(
              child: CircularProgressIndicator(color: colorGold),
            );
          }
          if (tx.error != null) {
            return _buildError(context, tx.error!);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${user.user?.nome.split(' ').first ?? ''}!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildDashboardGrid(tx),
                const SizedBox(height: 30),
                _buildChartSection(tx),
                const SizedBox(height: 30),
                _buildRecentTransactions(context, tx),
                const SizedBox(height: 16),
                _buildNewTransactionButton(context),
                const SizedBox(height: 15),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: colorTextSec),
            const SizedBox(height: 12),
            Text('Não foi possível carregar os dados.',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<TransactionProvider>().reload(),
              child: const Text('Tentar novamente',
                  style: TextStyle(color: colorGold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(TransactionProvider tx) {
    final economia = tx.totalReceitas - tx.totalDespesas;
    final hasData = tx.transactions.isNotEmpty;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Saldo Total', formatCurrency(tx.saldo),
            Icons.account_balance_wallet, colorGold,
            trend: hasData ? 'atual' : null),
        _buildStatCard('Receitas', formatCurrencyAbs(tx.totalReceitas),
            Icons.trending_up, Colors.green,
            trend: hasData ? '+${tx.transactions.where((t) => t.type.isReceita).length}' : null),
        _buildStatCard('Despesas', formatCurrencyAbs(tx.totalDespesas),
            Icons.trending_down, Colors.red,
            trend: hasData ? '${tx.transactions.where((t) => !t.type.isReceita).length} lançamentos' : null),
        _buildStatCard(
            economia >= 0 ? 'Economia' : 'Déficit',
            formatCurrency(economia),
            Icons.savings_outlined,
            economia >= 0 ? Colors.blue : Colors.red,
            trend: hasData
                ? economia >= 0
                    ? 'positivo'
                    : 'negativo'
                : null),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color badgeColor, {String? trend}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(color: colorTextSec, fontSize: 12)),
              Icon(icon, color: badgeColor.withValues(alpha: 0.5), size: 18),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          if (trend != null)
            Text(trend,
                style: TextStyle(color: badgeColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildChartSection(TransactionProvider tx) {
    final byCategory = <String, double>{};
    double totalDespesas = 0;
    for (final t in tx.transactions) {
      if (t.type.isReceita) continue;
      byCategory[t.category] =
          (byCategory[t.category] ?? 0) + t.amount;
      totalDespesas += t.amount;
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Despesas por Categoria',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(formatCurrencyAbs(totalDespesas),
                  style: const TextStyle(color: colorGold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          CategoryPieChart(
              values: byCategory,
              total: totalDespesas),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, TransactionProvider tx) {
    final recent = tx.transactions.take(5).toList();
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: colorCard, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                color: colorTextSec, size: 36),
            const SizedBox(height: 12),
            const Text('Nenhuma transação ainda',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Registre sua primeira movimentação',
                style: TextStyle(color: colorTextSec, fontSize: 12)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transações Recentes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/expenses'),
              child: const Text('Ver todas',
                  style: TextStyle(color: colorGold)),
            ),
          ],
        ),
        for (final t in recent) _buildTransactionItem(t),
      ],
    );
  }

  Widget _buildTransactionItem(AppTransaction t) {
    final cat = findCategory(t.category, isIncome: t.type.isReceita);
    final isIncome = t.type.isReceita;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: colorBackground,
              child: Icon(cat.icon, color: cat.color, size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${t.category} • ${formatDateShort(t.date)}',
                    style: const TextStyle(color: colorTextSec, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${formatCurrencyAbs(t.amount)}',
            style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTransactionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/transaction-form'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova Transação',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorGreenPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}