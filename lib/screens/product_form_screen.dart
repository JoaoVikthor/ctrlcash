import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/product.dart';
import '../providers/ingredient_provider.dart';
import '../providers/product_provider.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import '../utils/format.dart';
import '../utils/product_calculator.dart';
import 'dart:io';

class ProductFormScreen extends StatefulWidget {
  final Product? editing;
  final String? initialBarcode;
  final String? initialPhotoUrl;

  const ProductFormScreen({
    super.key,
    this.editing,
    this.initialBarcode,
    this.initialPhotoUrl,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _saleController = TextEditingController();
  final TextEditingController _laborController = TextEditingController();
  final TextEditingController _packController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final List<RecipeItem> _recipe = [];
  final List<TextEditingController> _qtyControllers = [];
  bool _saving = false;
  String? _photoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameController.text = e.name;
      _descController.text = e.description;
      _saleController.text =
          e.salePrice.toStringAsFixed(2).replaceAll('.', ',');
      _laborController.text =
          e.laborCost.toStringAsFixed(2).replaceAll('.', ',');
      _packController.text =
          e.packagingCost.toStringAsFixed(2).replaceAll('.', ',');
      _barcodeController.text = e.barcode ?? '';
      _photoUrl = e.photoUrl;
      for (final r in e.recipe) {
        _recipe.add(r);
        _qtyControllers.add(TextEditingController(
            text: r.quantity.toStringAsFixed(r.quantity % 1 == 0 ? 0 : 2)
                .replaceAll('.', ',')));
      }
    } else {
      _laborController.text = '0,00';
      _packController.text = '0,00';
      _barcodeController.text = widget.initialBarcode ?? '';
      _photoUrl = widget.initialPhotoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _saleController.dispose();
    _laborController.dispose();
    _packController.dispose();
    _barcodeController.dispose();
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  void _toast(String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _addIngredient(Ingredient ing) {
    if (_recipe.any((r) => r.ingredientId == ing.id)) {
      _toast('Este insumo já foi adicionado.');
      return;
    }
    setState(() {
      _recipe.add(RecipeItem(
          ingredientId: ing.id,
          ingredientName: ing.name,
          quantity: 0));
      _qtyControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removeAt(int index) {
    setState(() {
      _qtyControllers[index].dispose();
      _qtyControllers.removeAt(index);
      _recipe.removeAt(index);
    });
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      _toast('Informe o nome do produto.');
      return false;
    }
    final sale = _parse(_saleController);
    if (sale <= 0) {
      _toast('Informe o preço de venda (> 0).');
      return false;
    }
    if (_recipe.isEmpty) {
      _toast('Adicione ao menos um ingrediente à receita.');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final recipe = <RecipeItem>[];
      for (var i = 0; i < _recipe.length; i++) {
        final qty = _parse(_qtyControllers[i]);
        if (qty <= 0) {
          _toast('A quantidade de "${_recipe[i].ingredientName}" deve ser > 0.');
          setState(() => _saving = false);
          return;
        }
        recipe.add(_recipe[i].copyWith(quantity: qty));
      }
      final p = Product(
        id: widget.editing?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        recipe: recipe,
        laborCost: _parse(_laborController),
        packagingCost: _parse(_packController),
        salePrice: _parse(_saleController),
        photoUrl: _photoUrl,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        createdAt: widget.editing?.createdAt ?? DateTime.now(),
      );
      final prov = context.read<ProductProvider>();
      if (widget.editing == null) {
        await prov.addProduct(p);
      } else {
        await prov.updateProduct(p);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.editing == null
                ? 'Ficha técnica criada!'
                : 'Ficha técnica atualizada!'),
            backgroundColor: _colorGreenPrimary),
      );
    } catch (e) {
      if (!mounted) return;
      _toast('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TicketResult _livePreview(Map<String, Ingredient> ingredients) {
    final recipe = <RecipeItem>[];
    for (var i = 0; i < _recipe.length; i++) {
      recipe.add(_recipe[i].copyWith(quantity: _parse(_qtyControllers[i])));
    }
    final preview = Product(
      id: widget.editing?.id ?? '__preview__',
      name: _nameController.text.trim().isEmpty
          ? 'Produto'
          : _nameController.text.trim(),
      description: _descController.text.trim(),
      recipe: recipe,
      laborCost: _parse(_laborController),
      packagingCost: _parse(_packController),
      salePrice: _parse(_saleController),
      createdAt: DateTime.now(),
    );
    return ProductCalculator.calculate(preview, ingredients);
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
          isEdit ? 'Editar Ficha Técnica' : 'Nova Ficha Técnica',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<IngredientProvider>(
        builder: (context, ip, _) {
          if (ip.loading) {
            return const Center(
                child: CircularProgressIndicator(color: _colorGold));
          }
          if (ip.list.isEmpty) {
            return _buildNoIngredients();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(_nameController, 'Nome do produto',
                    Icons.lunch_dining_outlined),
                const SizedBox(height: 14),
                _field(_descController, 'Descrição (opcional)',
                    Icons.description_outlined,
                    maxLines: 2),
                const SizedBox(height: 14),
                _field(_saleController, 'Preço de venda (R\$)',
                    Icons.point_of_sale_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                _buildPhotoAndBarcode(),
                const SizedBox(height: 8),
                _buildSectionTitle('Ingredientes', Icons.restaurant_menu),
                const SizedBox(height: 10),
                _buildAddIngredientButton(ip.list),
                const SizedBox(height: 12),
                for (var i = 0; i < _recipe.length; i++)
                  _buildRecipeRow(i, ip.asMap),
                if (_recipe.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                        'Nenhum ingrediente adicionado. Toque em "Adicionar ingrediente".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                const SizedBox(height: 20),
                _buildSectionTitle('Custos extras', Icons.add_circle_outline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _field(_laborController, 'Mão de obra',
                            Icons.engineering_outlined,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_packController, 'Embalagem',
                            Icons.inventory_outlined,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLivePreview(ip.asMap),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildSaveBottom(isEdit),
    );
  }

  Widget _buildNoIngredients() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            const Text('Cadastre insumos primeiro',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Você precisa de insumos para montar a ficha técnica.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _colorGreenPrimary),
              child: const Text('Ir para Insumos',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _colorGold, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPhotoAndBarcode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        _buildSectionTitle('Foto e identificação', Icons.qr_code),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _uploadingPhoto ? null : _pickProductPhoto,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _colorCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: _uploadingPhoto
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: _colorGold, strokeWidth: 2))
                    : _photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_photoUrl!,
                                fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: _colorGold, size: 28),
                              SizedBox(height: 4),
                              Text('Adicionar foto',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10)),
                            ],
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_barcodeController, 'Código de barras (opcional)',
                  Icons.qr_code_2,
                  keyboardType: TextInputType.number),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickProductPhoto() async {
    final userUid = context.read<UserProvider>().uid;
    final storage = context.read<StorageService>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      if (userUid == null) throw StateError('Usuário não autenticado.');
      final url = await storage.uploadFile(
            uid: userUid,
            path:
                'product_photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
            file: File(xFile.path),
          );
      if (url == null) throw Exception('Falha no upload da foto.');
      setState(() => _photoUrl = url);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Widget _buildAddIngredientButton(List<Ingredient> available) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showIngredientPicker(available),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: _colorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _colorGreenPrimary.withValues(alpha: 0.4), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: _colorGold),
            SizedBox(width: 8),
            Text('Adicionar ingrediente',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showIngredientPicker(List<Ingredient> available) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _colorCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Selecione um insumo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (ctx, i) {
                  final ing = available[i];
                  return ListTile(
                    leading:
                        const Icon(Icons.science_outlined, color: _colorGold),
                    title: Text(ing.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                        '${formatCurrencyAbs(ing.pricePerUnit)}/${ing.unit.label}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _addIngredient(ing);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeRow(int index, Map<String, Ingredient> ingredients) {
    final item = _recipe[index];
    final ing = ingredients[item.ingredientId];
    final qty = _parse(_qtyControllers[index]);
    final lineCost =
        ing != null ? ing.pricePerUnit * qty : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.ingredientName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (ing != null)
                  Text(
                      '${formatCurrencyAbs(ing.pricePerUnit)}/${ing.unit.label}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11))
                else
                  const Text('Insumo removido',
                      style: TextStyle(color: Colors.red, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _qtyControllers[index],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: _colorBackground,
                suffixText: ing?.unit.label ?? '',
                suffixStyle: const TextStyle(color: _colorGold, fontSize: 11),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _colorGold, width: 1.2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('custo',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text(formatCurrencyAbs(lineCost),
                    style: const TextStyle(
                        color: _colorGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _removeAt(index),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview(Map<String, Ingredient> ingredients) {
    final t = _livePreview(ingredients);
    final isLucro = t.isLucro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isLucro ? Colors.green : Colors.red).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (isLucro ? Colors.green : Colors.red)
                .withValues(alpha: 0.3),
            width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isLucro ? Icons.trending_up : Icons.trending_down,
                  color: isLucro ? Colors.green : Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(isLucro ? 'Projeta LUCRO' : 'Projeta PREJUÍZO',
                  style: TextStyle(
                      color: isLucro ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _previewRow('Ingredientes', formatCurrencyAbs(t.ingredientsTotal)),
          _previewRow('Mão de obra', formatCurrencyAbs(t.laborCost)),
          _previewRow('Embalagem', formatCurrencyAbs(t.packagingCost)),
          const Divider(color: Colors.white24, height: 16),
          _previewRow('Custo total', formatCurrencyAbs(t.totalCost),
              bold: true),
          _previewRow('Preço de venda', formatCurrencyAbs(t.salePrice),
              bold: true),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isLucro ? 'Lucro' : 'Prejuízo',
                  style: TextStyle(
                      color: isLucro ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold)),
              Text(
                  '${isLucro ? '+' : ''}${formatCurrency(t.profit)}  •  Margem ${t.marginPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: isLucro ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
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
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _colorGold, width: 1.5),
        ),
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
                  isEdit ? 'Salvar Alterações' : 'Criar Ficha Técnica',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}