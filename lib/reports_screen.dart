import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_pie_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorCard = Color(0xFF142A20);
  static const colorTextSec = Color(0xFF7A8B83);

  static const List<String> _months = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'reports'),
      appBar: const AppBrandedHeader(title: 'Relatórios'),
      body: Consumer<TransactionProvider>(
        builder: (context, tx, _) {
          if (tx.loading) {
            return const Center(
                child: CircularProgressIndicator(color: colorGold));
          }
          if (tx.transactions.isEmpty) {
            return _buildEmpty();
          }
          final monthly = _monthlyData(tx.transactions);
          final byCategory = <String, double>{};
          double totalDespesas = 0;
          for (final t in tx.transactions) {
            if (t.type.isReceita) continue;
            byCategory[t.category] =
                (byCategory[t.category] ?? 0) + t.amount;
            totalDespesas += t.amount;
          }
          final totalReceitas = tx.totalReceitas;
          final lucro = totalReceitas - totalDespesas;
          final margem = totalReceitas > 0
              ? (lucro / totalReceitas) * 100
              : 0.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Desempenho',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Análise dos seus últimos 6 meses',
                    style: TextStyle(color: colorTextSec, fontSize: 13)),
                const SizedBox(height: 20),
                _buildKpiRow(lucro, margem, totalReceitas, totalDespesas),
                const SizedBox(height: 24),
                _buildMonthlyChart(monthly),
                const SizedBox(height: 24),
                _buildPieSection(byCategory, totalDespesas),
                const SizedBox(height: 24),
                _buildTopCategories(byCategory),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined,
                size: 56, color: colorTextSec),
            const SizedBox(height: 12),
            const Text('Sem dados para relatórios',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 4),
            const Text('Registre transações para ver análises.',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  List<_Monthly> _monthlyData(List<AppTransaction> all) {
    final now = DateTime.now();
    final list = <_Monthly>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      double r = 0, e = 0;
      for (final t in all) {
        if (t.date.year == d.year && t.date.month == d.month) {
          if (t.type.isReceita) {
            r += t.amount;
          } else {
            e += t.amount;
          }
        }
      }
      list.add(_Monthly(_months[d.month - 1], r, e));
    }
    return list;
  }

  Widget _buildKpiRow(
      double lucro, double margem, double receitas, double despesas) {
    final isLucro = lucro >= 0;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _kpiCard('Lucro Líquido', formatCurrency(lucro),
            isLucro ? Colors.green : Colors.red,
            desc: isLucro ? 'Resultado positivo' : 'Resultado negativo'),
        _kpiCard('Margem de Lucro', '${margem.toStringAsFixed(1)}%',
            margem >= 0 ? Colors.green : Colors.red,
            desc: 'Sobre as receitas'),
        _kpiCard('Total Receitas', formatCurrencyAbs(receitas), Colors.green,
            desc: 'Entradas no período'),
        _kpiCard('Total Despesas', formatCurrencyAbs(despesas), Colors.red,
            desc: 'Saídas no período'),
      ],
    );
  }

  Widget _kpiCard(String title, String value, Color color, {String? desc}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: colorTextSec, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (desc != null) ...[
            const Spacer(),
            Text(desc,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<_Monthly> data) {
    final maxV = data.fold<double>(
        0,
        (m, d) => d.receitas > m
            ? d.receitas
            : (d.despesas > m ? d.despesas : m));
    final chartMax =
        (maxV * 1.2).ceilToDouble().clamp(1.0, double.infinity).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Receitas vs Despesas (6 meses)',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(Colors.green, 'Receitas'),
              const SizedBox(width: 16),
              _legend(Colors.red, 'Despesas'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                barGroups: List.generate(data.length, (i) {
                  final d = data[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                          toY: d.receitas,
                          color: Colors.green,
                          width: 7,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3))),
                      BarChartRodData(
                          toY: d.despesas,
                          color: Colors.red,
                          width: 7,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3))),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(data[i].label,
                              style: const TextStyle(
                                  color: colorTextSec, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.white.withValues(alpha: 0.06),
                      strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildPieSection(Map<String, double> byCategory, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distribuição de Despesas',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          CategoryPieChart(values: byCategory, total: total),
        ],
      ),
    );
  }

  Widget _buildTopCategories(Map<String, double> byCategory) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final max = top.isEmpty ? 1.0 : top.first.value;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top 5 Categorias',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final e in top)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                      Text(formatCurrencyAbs(e.value),
                          style: const TextStyle(
                              color: colorGold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: e.value / max,
                      color: findCategory(e.key).color,
                      backgroundColor: colorBackground,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Monthly {
  final String label;
  final double receitas;
  final double despesas;
  const _Monthly(this.label, this.receitas, this.despesas);
}