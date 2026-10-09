import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/ingredient_offer.dart';
import '../providers/ingredient_provider.dart';
import '../utils/format.dart';
import '../widgets/delta_price_text.dart';
import '../widgets/error_state.dart';
import '../widgets/offer_limit_banner.dart';

class OfferFormScreen extends StatefulWidget {
  final String ingredientId;
  final IngredientOffer? offer;

  const OfferFormScreen({
    super.key,
    required this.ingredientId,
    this.offer,
  });

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final _supplierController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();

  bool _saving = false;
  String? _supplierError;
  String? _priceError;
  String? _qtyError;

  @override
  void initState() {
    super.initState();
    final offer = widget.offer;
    if (offer != null) {
      _supplierController.text = offer.supplier;
      _priceController.text = _formatNumber(offer.packagePrice);
      _qtyController.text = _formatNumber(offer.packageQuantity);
      _notesController.text = offer.notes;
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2)
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngredientProvider>();
    final ingredient = provider.asMap[widget.ingredientId];
    final isEdit = widget.offer != null;

    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Voltar',
        ),
        title: Text(
          isEdit ? 'Editar oferta' : 'Nova oferta',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ingredient == null && !provider.loading
          ? const ErrorState(message: 'Insumo não encontrado.')
          : _buildBody(ingredient, isEdit),
      bottomNavigationBar: ingredient == null
          ? null
          : _buildSaveBottom(ingredient, isEdit),
    );
  }

  Widget _buildBody(Ingredient? ingredient, bool isEdit) {
    if (ingredient == null) {
      return const Center(
        child: CircularProgressIndicator(color: _colorGold),
      );
    }

    final price = _parse(_priceController.text);
    final qty = _parse(_qtyController.text);
    final perUnit = qty > 0 ? price / qty : 0.0;
    final notesLength = _notesController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o que você paga e quanto vem na embalagem. O app calcula o preço por unidade.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _field(
            controller: _supplierController,
            label: 'Nome do fornecedor',
            icon: Icons.storefront_outlined,
            errorText: _supplierError,
            helper: 'Ex.: Distribuidora Central, Atacado do Zé',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _field(
                  controller: _priceController,
                  label: 'Preço da embalagem (R\$)',
                  icon: Icons.attach_money,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  errorText: _priceError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _field(
                  controller: _qtyController,
                  label: 'Qtd. da embalagem',
                  icon: Icons.scale_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  errorText: _qtyError,
                ),
              ),
              const SizedBox(width: 12),
              _unitChip(ingredient.unit.label),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreview(ingredient, perUnit, qty),
          const SizedBox(height: 16),
          _field(
            controller: _notesController,
            label: 'Notas (opcional)',
            icon: Icons.notes_outlined,
            maxLines: 4,
            minLines: 2,
            counter: notesLength > 160 ? '$notesLength/200' : null,
          ),
          if (isEdit && ingredient.activeOffer != null &&
              widget.offer?.id != ingredient.activeOffer!.id) ...[
            const SizedBox(height: 16),
            _buildCompareCard(ingredient.activeOffer!),
          ],
          if (!isEdit && ingredient.offersCount >= 15) ...[
            const SizedBox(height: 16),
            OfferLimitBanner(current: ingredient.offersCount),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    String? helper,
    String? counter,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines,
    int? minLines,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      minLines: minLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        helperText: helper,
        helperStyle: const TextStyle(color: Color(0xFF7A8B83), fontSize: 11),
        errorText: errorText,
        counterText: counter,
        counterStyle: const TextStyle(color: Color(0xFF7A8B83), fontSize: 11),
        prefixIcon: Icon(icon, color: _colorGold, size: 20),
        filled: true,
        fillColor: _colorCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _colorGold, width: 1.5),
        ),
      ),
    );
  }

  Widget _unitChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'unidade: $label',
        style: const TextStyle(
          color: _colorGold,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPreview(Ingredient ingredient, double perUnit, double qty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorGreenPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorGreenPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: _colorGold, size: 18),
              SizedBox(width: 8),
              Text(
                'Preço por unidade',
                style: TextStyle(
                  color: _colorGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (qty <= 0)
            const Text(
              'Informe a quantidade',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '${formatCurrencyAbs(perUnit)} / ${ingredient.unit.label}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompareCard(IngredientOffer active) {
    final offer = widget.offer;
    if (offer == null) return const SizedBox.shrink();
    final delta = offer.pricePerUnit - active.pricePerUnit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparado com a oferta ativa',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          DeltaPriceText(delta: delta, fontSize: 18),
          const SizedBox(height: 4),
          Text(
            'Ativa: ${active.supplier} · ${formatCurrencyAbs(active.pricePerUnit)}/un',
            style: const TextStyle(color: Color(0xFF7A8B83), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBottom(Ingredient ingredient, bool isEdit) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: ElevatedButton(
          onPressed: _saving ? null : () => _save(ingredient, isEdit),
          style: ElevatedButton.styleFrom(
            backgroundColor: _colorGreenPrimary,
            disabledBackgroundColor:
                _colorGreenPrimary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isEdit ? 'Salvar alterações' : 'Salvar oferta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _save(Ingredient ingredient, bool isEdit) async {
    setState(() {
      _supplierError = null;
      _priceError = null;
      _qtyError = null;
    });

    final supplier = _supplierController.text.trim();
    if (supplier.isEmpty) {
      setState(() => _supplierError = 'Informe o nome do fornecedor.');
      _toast('Fornecedor não pode ficar vazio.');
      return;
    }

    final price = _parse(_priceController.text);
    if (price <= 0) {
      setState(() => _priceError = 'Informe um preço maior que zero.');
      _toast('Preço da embalagem deve ser maior que zero.');
      return;
    }

    final qty = _parse(_qtyController.text);
    if (qty <= 0) {
      setState(() => _qtyError = 'Informe uma quantidade maior que zero.');
      _toast('Quantidade da embalagem deve ser maior que zero.');
      return;
    }

    if (!isEdit && ingredient.offersCount >= 15) {
      _toast('Limite de 15 ofertas por insumo.');
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final offer = IngredientOffer(
        id: isEdit ? widget.offer!.id : '',
        supplier: supplier,
        packagePrice: price,
        packageQuantity: qty,
        isActive: isEdit ? widget.offer!.isActive : true,
        source: isEdit ? widget.offer!.source : 'manual',
        notes: _notesController.text.trim(),
        createdAt: isEdit ? widget.offer!.createdAt : now,
        updatedAt: now,
      );

      await context
          .read<IngredientProvider>()
          .upsertOffer(ingredient.id, offer);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Oferta atualizada.' : 'Oferta salva.'),
          backgroundColor: _colorGold,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast('Erro ao salvar oferta: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _parse(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
