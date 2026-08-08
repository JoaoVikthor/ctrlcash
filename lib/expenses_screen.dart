import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorCard = Color(0xFF142A20);
  static const colorTextSec = Color(0xFF7A8B83);

  TransactionType? _filterType;
  String? _filterCategory;
  String _search = '';

  List<String> get _availableCategories {
    final tx = context.read<TransactionProvider>();
    final set = tx.transactions.map((t) => t.category).toSet();
    final list = <String>[];
    for (final c in [...kExpenseCategories, ...kIncomeCategories]) {
      if (set.contains(c.name)) list.add(c.name);
    }
    for (final c in set) {
      if (!list.contains(c)) list.add(c);
    }
    return list;
  }

  List<AppTransaction> get _filtered {
    final tx = context.read<TransactionProvider>();
    var list = tx.transactions;
    if (_filterType != null) {
      list = list.where((t) => t.type == _filterType).toList();
    }
    if (_filterCategory != null) {
      list = list.where((t) => t.category == _filterCategory).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((t) =>
              t.description.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'expenses'),
      appBar: const AppBrandedHeader(title: 'Transações'),
      body: Consumer<TransactionProvider>(
        builder: (context, tx, _) {
          if (tx.loading) {
            return const Center(
                child: CircularProgressIndicator(color: colorGold));
          }
          if (tx.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: colorTextSec, size: 48),
                  const SizedBox(height: 8),
                  Text('Erro: ${tx.error}',
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return Column(
            children: [
              _buildSummary(tx),
              _buildFilters(),
              Expanded(child: _buildList(tx)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/transaction-form'),
        backgroundColor: const Color(0xFF165A41),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummary(TransactionProvider tx) {
    final list = _filtered;
    final receitas = list.where((t) => t.type.isReceita).fold<double>(
        0, (s, t) => s + t.amount);
    final despesas = list.where((t) => !t.type.isReceita).fold<double>(
        0, (s, t) => s + t.amount);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem('Receitas', formatCurrencyAbs(receitas),
                Colors.green, Icons.arrow_upward),
          ),
          Container(
              width: 1,
              height: 38,
              color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: _summaryItem('Despesas', formatCurrencyAbs(despesas),
                Colors.red, Icons.arrow_downward),
          ),
          Container(
              width: 1,
              height: 38,
              color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: _summaryItem(
                'Saldo',
                formatCurrency(receitas - despesas),
                (receitas - despesas) >= 0 ? Colors.green : Colors.red,
                Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: colorTextSec, fontSize: 11)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar transação...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.search, color: colorGold, size: 20),
              filled: true,
              fillColor: colorCard,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: colorGold, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todas', _filterType == null && _filterCategory == null, () {
                  setState(() {
                    _filterType = null;
                    _filterCategory = null;
                  });
                }),
                const SizedBox(width: 8),
                _filterChip('Receitas', _filterType == TransactionType.receita,
                    () => setState(() {
                          _filterType = TransactionType.receita;
                        })),
                const SizedBox(width: 8),
                _filterChip(
                    'Despesas', _filterType == TransactionType.despesa,
                    () => setState(() {
                          _filterType = TransactionType.despesa;
                        })),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  color: colorCard,
                  onSelected: (v) => setState(() => _filterCategory = v),
                  itemBuilder: (_) => _availableCategories
                      .map((c) => PopupMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  child: _filterChip(
                      _filterCategory ?? 'Categoria',
                      _filterCategory != null,
                      () {},
                      isMenu: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap,
      {bool isMenu = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF165A41) : colorCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            if (isMenu) ...[
              const SizedBox(width: 6),
              const Icon(Icons.filter_list,
                  color: Colors.white54, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(TransactionProvider tx) {
    final list = _filtered;
    if (list.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(40),
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 56, color: colorTextSec),
          const SizedBox(height: 12),
          const Text('Nenhuma transação encontrada',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 6),
          const Text('Use o botão + para registrar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        final cat = findCategory(t.category, isIncome: t.type.isReceita);
        final isIncome = t.type.isReceita;
        return Dismissible(
          key: ValueKey(t.id),
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
          confirmDismiss: (_) => _confirmDeleteBool(t),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: colorCard, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: colorBackground,
                    child: Icon(cat.icon, color: cat.color, size: 20)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.description,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _tag(cat.name, cat.color),
                          Text(t.paymentMethod.label,
                              style: const TextStyle(
                                  color: colorTextSec, fontSize: 11)),
                          if (t.recurring)
                            const Icon(Icons.repeat,
                                size: 12, color: colorGold),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(formatDate(t.date),
                          style: const TextStyle(
                              color: colorTextSec, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        '${isIncome ? '+' : '-'}${formatCurrencyAbs(t.amount)}',
                        style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Future<bool?> _confirmDeleteBool(AppTransaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorCard,
        title: const Text('Excluir transação?',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text('"${t.description}" será removida permanentemente.',
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
    if (ok == true && mounted) {
      await context.read<TransactionProvider>().deleteTransaction(t.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transação excluída.'),
              backgroundColor: colorGold),
        );
      }
      return true;
    }
    return false;
  }
}