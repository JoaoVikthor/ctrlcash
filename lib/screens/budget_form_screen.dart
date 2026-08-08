import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../utils/categories.dart';
import '../utils/format.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? editing;

  const BudgetFormScreen({super.key, this.editing});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final TextEditingController _limitController = TextEditingController();
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.editing?.category ?? kExpenseCategories.first.name;
    if (widget.editing != null) {
      _limitController.text =
          widget.editing!.limit.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool _validate() {
    final raw = _limitController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um limite válido maior que zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final raw = _limitController.text.trim().replaceAll(',', '.');
      final value = double.parse(raw);
      final b = Budget(
        id: widget.editing?.id ?? '',
        category: _category,
        limit: value,
        monthly: true,
        createdAt: widget.editing?.createdAt ?? DateTime.now(),
      );
      final prov = context.read<BudgetProvider>();
      if (widget.editing == null) {
        await prov.addBudget(b);
      } else {
        await prov.updateBudget(b);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editing == null
              ? 'Orçamento criado!'
              : 'Orçamento atualizado!'),
          backgroundColor: _colorGreenPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Editar Orçamento' : 'Novo Orçamento',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Defina uma categoria e o limite mensal de gastos.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            _buildCategoryPicker(),
            const SizedBox(height: 16),
            _buildLimitField(),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorGreenPrimary,
              disabledBackgroundColor:
                  _colorGreenPrimary.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    isEdit ? 'Salvar Alterações' : 'Criar Orçamento',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          dropdownColor: _colorCard,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: _colorGold),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: kExpenseCategories
              .map((c) => DropdownMenuItem(
                    value: c.name,
                    child: Row(
                      children: [
                        Icon(c.icon, color: c.color, size: 20),
                        const SizedBox(width: 12),
                        Text(c.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
      ),
    );
  }

  Widget _buildLimitField() {
    return TextField(
      controller: _limitController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Limite mensal (R\$)',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.attach_money, color: _colorGold, size: 20),
        prefixText: 'R\$ ',
        prefixStyle: const TextStyle(color: _colorGold),
        filled: true,
        fillColor: _colorCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _colorGold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final raw = _limitController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw) ?? 0;
    final diaria = value > 0 ? value / 30 : 0.0;
    final semanal = value > 0 ? value / 4.33 : 0.0;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorGreenPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _colorGreenPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: _colorGold, size: 18),
              SizedBox(width: 8),
              Text('Referência',
                  style: TextStyle(
                      color: _colorGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          _refRow('Por dia', formatCurrencyAbs(diaria)),
          _refRow('Por semana', formatCurrencyAbs(semanal)),
        ],
      ),
    );
  }

  Widget _refRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}