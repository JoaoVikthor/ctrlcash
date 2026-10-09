import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../utils/format.dart';
import '../widgets/section_header.dart';
import '../widgets/active_offer_marker.dart';
import '../widgets/best_price_chip.dart';

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
  static const Color _colorTextSec = Color(0xFF7A8B83);

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
      final name = _nameController.text.trim();
      final purchasePrice =
          double.parse(_priceController.text.trim().replaceAll(',', '.'));
      final packageQuantity =
          double.parse(_qtyController.text.trim().replaceAll(',', '.'));
      final ing = widget.editing?.copyWith(
            name: name,
            unit: _unit,
            purchasePrice: purchasePrice,
            packageQuantity: packageQuantity,
          ) ??
          Ingredient(
            id: '',
            name: name,
            unit: _unit,
            purchasePrice: purchasePrice,
            packageQuantity: packageQuantity,
            createdAt: DateTime.now(),
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
            const SizedBox(height: 24),
            _buildDefaultSupplierSection(context),
            const SizedBox(height: 24),
            _buildOffersSection(context),
            const SizedBox(height: 16),
            const Text(
              'Você escolhe qual oferta entra no ticket. O app não troca sozinho.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
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
    final active = widget.editing?.activeOffer;
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
          if (active != null) ...[
            const SizedBox(height: 8),
            Text(
              'Com oferta ativa, o ticket usa ${formatCurrencyAbs(active.pricePerUnit)}/${_unit.label} (${active.supplier}).',
              style: const TextStyle(color: _colorGold, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultSupplierSection(BuildContext context) {
    final ing = widget.editing;
    final active = ing?.activeOffer;
    final bool isNew = ing == null;

    if (active != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              icon: Icons.storefront_outlined, title: 'Fornecedor padrão'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _colorCard,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ativa agora',
                    style: TextStyle(color: _colorGold, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(active.supplier,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    const ActiveOfferMarker(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatCurrencyAbs(active.packagePrice)} · ${active.packageQuantity.toStringAsFixed(active.packageQuantity % 1 == 0 ? 0 : 2)} ${ing!.unit.label} · ${formatCurrencyAbs(active.pricePerUnit)}/${ing.unit.label}',
                  style: const TextStyle(
                      color: _colorGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/offer-form',
                        arguments: {
                          'ingredientId': ing.id,
                          'offer': active,
                        },
                      ),
                      style: TextButton.styleFrom(
                          foregroundColor: _colorGold,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Editar oferta'),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/ingredient-offers',
                        arguments: ing.id,
                      ),
                      style: TextButton.styleFrom(
                          foregroundColor: _colorGold,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Ver todas (${ing.offersCount})'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (ing != null && ing.offers.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              icon: Icons.storefront_outlined, title: 'Fornecedor padrão'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.4), width: 1)),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nenhuma oferta ativa. O ticket usa o preço base deste insumo.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            icon: Icons.storefront_outlined, title: 'Fornecedor padrão'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: _colorCard,
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              const Icon(Icons.storefront_outlined,
                  color: _colorTextSec, size: 28),
              const SizedBox(height: 8),
              Text(
                isNew
                    ? 'Salve o insumo antes de adicionar ofertas.'
                    : 'Nenhuma oferta cadastrada.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _colorTextSec, fontSize: 12),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isNew
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/offer-form',
                          arguments: {'ingredientId': ing.id},
                        ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _colorGreenPrimary,
                  side: const BorderSide(color: _colorGreenPrimary),
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Adicionar primeira oferta'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    final ing = widget.editing;
    if (ing == null) return const SizedBox.shrink();
    final active = ing.activeOffer;
    final best = ing.bestActiveOffer;
    final previewOffers = ing.offers.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.storefront_outlined,
          title: 'Ofertas',
          trailing: Text(
            '${ing.offersCount}/15',
            style: const TextStyle(color: _colorTextSec, fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        if (previewOffers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _colorCard,
                borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'Nenhuma oferta ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _colorTextSec, fontSize: 12),
            ),
          )
        else
          Column(
            children: previewOffers.map((o) {
              final isActive = active?.id == o.id;
              final isBest = best?.id == o.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _colorCard,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.supplier,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            '${formatCurrencyAbs(o.pricePerUnit)}/${ing.unit.label}',
                            style: const TextStyle(
                                color: _colorGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (isActive) ...[
                      const ActiveOfferMarker(),
                      const SizedBox(width: 6),
                    ],
                    if (isBest && active?.id != best?.id) ...[
                      const BestPriceChip(),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        if (ing.offersCount > 3) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/ingredient-offers',
                arguments: ing.id),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver todas as ${ing.offersCount} ofertas',
                  style: const TextStyle(
                      color: _colorGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_forward,
                    color: _colorGold, size: 14),
              ],
            ),
          ),
        ],
      ],
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