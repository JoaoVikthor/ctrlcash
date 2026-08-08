import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../utils/format.dart';

class IngredientFormScreen extends StatefulWidget {
  final Ingredient? editing;

  const IngredientFormScreen({super.key, this.editing});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  IngredientUnit _unit = IngredientUnit.grama;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameController.text = e.name;
      _priceController.text =
          e.purchasePrice.toStringAsFixed(2).replaceAll('.', ',');
      _qtyController.text =
          e.packageQuantity.toStringAsFixed(e.packageQuantity % 1 == 0 ? 0 : 2)
              .replaceAll('.', ',');
      _unit = e.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      _toast('Informe o nome do insumo.');
      return false;
    }
    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    if (price == null || price <= 0) {
      _toast('Informe um preço de compra válido (> 0).');
      return false;
    }
    final qty =
        double.tryParse(_qtyController.text.trim().replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      _toast('Informe a quantidade da embalagem (> 0).');
      return false;
    }
    return true;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final ing = Ingredient(
        id: widget.editing?.id ?? '',
        name: _nameController.text.trim(),
        unit: _unit,
        purchasePrice:
            double.parse(_priceController.text.trim().replaceAll(',', '.')),
        packageQuantity:
            double.parse(_qtyController.text.trim().replaceAll(',', '.')),
        createdAt: widget.editing?.createdAt ?? DateTime.now(),
      );
      final prov2 = context.read<IngredientProvider>();
      if (widget.editing == null) {
        await prov2.addIngredient(ing);
      } else {
        await prov2.updateIngredient(ing);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.editing == null
                ? 'Insumo cadastrado!'
                : 'Insumo atualizado!'),
            backgroundColor: _colorGreenPrimary),
      );
    } catch (e) {
      if (!mounted) return;
      _toast('Erro ao salvar: $e');
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
          isEdit ? 'Editar Insumo' : 'Novo Insumo',
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
            const Text(
                'Cadastre um material que você compra. O app calcula o preço por unidade automaticamente.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            _field(_nameController, 'Nome do insumo', Icons.science_outlined),
            const SizedBox(height: 16),
            _field(_priceController, 'Preço de compra (R\$)',
                Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 2,
                    child: _field(_qtyController, 'Qtd. da embalagem',
                        Icons.scale_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _unitPicker(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreview(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveBottom(isEdit),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: _colorGold, size: 20),
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

  Widget _unitPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IngredientUnit>(
          value: _unit,
          dropdownColor: _colorCard,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: _colorGold),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: IngredientUnit.values
              .map((u) => DropdownMenuItem(
                  value: u,
                  child: Row(
                    children: [
                      const Icon(Icons.straighten, color: _colorGold, size: 18),
                      const SizedBox(width: 8),
                      Text(u.label),
                    ],
                  )))
              .toList(),
          onChanged: (v) => setState(() => _unit = v ?? _unit),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0;
    final qty =
        double.tryParse(_qtyController.text.trim().replaceAll(',', '.')) ?? 0;
    final perUnit = qty > 0 ? price / qty : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _colorGreenPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _colorGreenPrimary.withValues(alpha: 0.3), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lightbulb_outline, color: _colorGold, size: 18),
            SizedBox(width: 8),
            Text('Preço por unidade base',
                style: TextStyle(
                    color: _colorGold, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(
              '${formatCurrencyAbs(perUnit)} / ${_unit.label}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSaveBottom(bool isEdit) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _colorGreenPrimary,
            disabledBackgroundColor: _colorGreenPrimary.withValues(alpha: 0.5),
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
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  isEdit ? 'Salvar Alterações' : 'Cadastrar Insumo',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}