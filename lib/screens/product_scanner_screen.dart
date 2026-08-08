import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import '../widgets/app_branded_header.dart';

/// Tela de identificacao de produto por codigo de barras ou foto.
///
/// Fluxo: o usuario aponta a camera para um codigo de barras ou tira uma
/// foto. Se o codigo ja estiver cadastrado no parque de produtos, abre o
/// ticket diretamente. Caso contrario, abre o formulario de ficha tecnica
/// com o barcode/foto pre-preenchidos para cadastro. Na proxima vez que
/// o mesmo codigo for lido, o sistema ja reconhece o produto.
class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({super.key});

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final MobileScannerController _scannerController = MobileScannerController();
  bool _detected = false;
  bool _uploading = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _detected = true;
    _handleBarcode(code);
  }

  void _handleBarcode(String code) {
    final prov = context.read<ProductProvider>();
    final existing = prov.findByBarcode(code);
    if (existing != null) {
      _showRecognized(existing);
    } else {
      _showNew(code);
    }
  }

  void _showRecognized(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _colorCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Produto reconhecido!',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _detected = false);
                      }),
                ],
              ),
              const SizedBox(height: 16),
              if (product.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(product.photoUrl!,
                      height: 140, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                      color: _colorBackground,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.lunch_dining_outlined,
                      color: _colorGold, size: 48),
                ),
              const SizedBox(height: 16),
              Text(product.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Código: ${product.barcode}',
                  style: const TextStyle(color: _colorGold, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _detected = false);
                        _continueScanning();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _colorGold,
                        side: const BorderSide(color: _colorGold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Escanear outro'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(context,
                            '/product-detail',
                            arguments: product.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorGreenPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ver ticket'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNew(String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _colorCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.fiber_new, color: _colorGold, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Novo produto!',
                        style: TextStyle(
                            color: _colorGold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _detected = false);
                      }),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                  'Este código ainda não está cadastrado. Crie a ficha técnica para que o sistema passe a reconhecê-lo.',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _colorBackground,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('Código detectado:\n$code',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _detected = false);
                        _continueScanning();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _colorGold,
                        side: const BorderSide(color: _colorGold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(context,
                            '/product-form-with-barcode',
                            arguments: code);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorGreenPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cadastrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueScanning() {
    _scannerController.start();
  }

  Future<void> _pickPhoto() async {
    final userUid = context.read<UserProvider>().uid;
    final storage = context.read<StorageService>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return;
    setState(() => _uploading = true);
    try {
      if (userUid == null) throw StateError('Usuário não autenticado.');
      final url = await storage.uploadFile(
            uid: userUid,
            path: 'product_photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
            file: File(xFile.path),
          );
      if (url == null) throw Exception('Falha no upload da foto.');
      if (!mounted) return;
      _showPhotoResult(url);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoResult(String photoUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _colorCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(photoUrl,
                    height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              const Text('Foto capturada!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                  'Para reconhecimento automático, associe esta foto a um produto cadastrando o código de barras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(
                      context, '/product-form-with-photo',
                      arguments: photoUrl);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _colorGreenPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Cadastrar Ficha Técnica'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: const AppBrandedHeader(title: 'Identificar Produto', showBack: true),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          _buildOverlay(),
          _buildBottomBar(),
          if (_uploading)
            Container(
              color: Colors.black54,
              child: const Center(
                  child: CircularProgressIndicator(color: _colorGold)),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 260,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: _colorGold, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 56),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: _colorCard,
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Aponte para um código de barras ou tire uma foto',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _pickPhoto,
                      icon: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white),
                      label: const Text('Tirar foto',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _colorGreenPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _scannerController.toggleTorch(),
                    icon: const Icon(Icons.flash_on, color: _colorGold),
                    tooltip: 'Lanterna',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}