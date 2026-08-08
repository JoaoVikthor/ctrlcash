import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';
import '../utils/format.dart';

class TransactionFormScreen extends StatefulWidget {
  final AppTransaction? editing;
  final bool preselectIncome;

  const TransactionFormScreen({
    super.key,
    this.editing,
    this.preselectIncome = false,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  late TransactionType _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late DateTime _date;
  PaymentMethod _paymentMethod = PaymentMethod.dinheiro;
  late String _category;
  bool _recurring = false;
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.editing;
    _type = t?.type ??
        (widget.preselectIncome
            ? TransactionType.receita
            : TransactionType.despesa);
    _date = t?.date ?? DateTime.now();
    _paymentMethod = t?.paymentMethod ?? PaymentMethod.dinheiro;
    _category = t?.category ??
        (_type.isReceita
            ? kIncomeCategories.first.name
            : kExpenseCategories.first.name);
    _recurring = t?.recurring ?? false;
    if (t != null) {
      _amountController.text = t.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = t.description;
      _notesController.text = t.notes ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<CategoryDef> get _categories => _type.isReceita
      ? kIncomeCategories
      : kExpenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _colorGreenPrimary,
            onPrimary: Colors.white,
            surface: _colorCard,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool _validate() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor válido maior que zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma descrição.'),
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
      final raw = _amountController.text.trim().replaceAll(',', '.');
      final value = double.parse(raw);
      final t = AppTransaction.create(
        id: widget.editing?.id ?? '',
        type: _type,
        category: _category,
        description: _descriptionController.text.trim(),
        amount: value,
        date: _date,
        paymentMethod: _paymentMethod,
        recurring: _recurring,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      final prov = context.read<TransactionProvider>();
      if (widget.editing == null) {
        await prov.addTransaction(t);
      } else {
        await prov.updateTransaction(t);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editing == null
              ? 'Transação registrada!'
              : 'Transação atualizada!'),
          backgroundColor: _colorGreenPrimary,
        ),
      );
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.toString()),
          backgroundColor: Colors.red,
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
          isEdit ? 'Editar Transação' : 'Nova Transação',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 20),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildField(
              controller: _descriptionController,
              label: 'Descrição',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
            const SizedBox(height: 16),
            _buildPaymentPicker(),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildField(
              controller: _notesController,
              label: 'Observações (opcional)',
              icon: Icons.notes,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
              activeTrackColor: _colorGreenPrimary,
              contentPadding: EdgeInsets.zero,
              title: const Text('Repetir mensalmente',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Lançamento recorrente',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 8),
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
                    isEdit ? 'Salvar Alterações' : 'Registrar Transação',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(child: _toggleButton(TransactionType.despesa, 'Despesa',
              Icons.arrow_downward, Colors.red)),
          const SizedBox(width: 6),
          Expanded(child: _toggleButton(TransactionType.receita, 'Receita',
              Icons.arrow_upward, Colors.green)),
        ],
      ),
    );
  }

  Widget _toggleButton(
      TransactionType t, String label, IconData icon, Color color) {
    final selected = _type == t;
    return GestureDetector(
      onTap: () => setState(() {
        _type = t;
        _category = (t.isReceita ? kIncomeCategories : kExpenseCategories)
            .first
            .name;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _colorGreenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _type.isReceita
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.red.withValues(alpha: 0.4),
            width: 1.2),
      ),
      child: Column(
        children: [
          const Text('Valor',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('R\$',
                  style: TextStyle(
                      color: _colorGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0,00',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
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
          items: _categories
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

  Widget _buildPaymentPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentMethod>(
          value: _paymentMethod,
          dropdownColor: _colorCard,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: _colorGold),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: PaymentMethod.values
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Icon(_paymentIcon(m), color: _colorGold, size: 20),
                        const SizedBox(width: 12),
                        Text(m.label),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
        ),
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod m) => switch (m) {
        PaymentMethod.dinheiro => Icons.payments_outlined,
        PaymentMethod.credito => Icons.credit_card,
        PaymentMethod.debito => Icons.credit_card_outlined,
        PaymentMethod.pix => Icons.bolt,
        PaymentMethod.transferencia => Icons.account_balance_outlined,
        PaymentMethod.outro => Icons.more_horiz,
      };

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _colorCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: _colorGold, size: 20),
            const SizedBox(width: 12),
            const Text('Data',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const Spacer(),
            Text(formatDate(_date),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: _colorGold, size: 20),
        filled: true,
        fillColor: _colorCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _colorGold, width: 1.5),
        ),
      ),
    );
  }
}