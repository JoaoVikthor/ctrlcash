import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _segmentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;

  @override
  void dispose() {
    _nomeController.dispose();
    _empresaController.dispose();
    _cnpjController.dispose();
    _segmentoController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  void _loadFromUser(AppUser? user) {
    if (_loaded) return;
    _loaded = true;
    _nomeController.text = user?.nome ?? '';
    _empresaController.text = user?.empresa ?? '';
    _cnpjController.text = user?.cnpj ?? '';
    _segmentoController.text = user?.segmento ?? '';
    _telefoneController.text = user?.telefone ?? '';
    _enderecoController.text = user?.endereco ?? '';
    _photoUrl ??= user?.photoUrl;
  }

  Future<void> _pickProfilePhoto() async {
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
            path: 'profile.jpg',
            file: File(xFile.path),
          );
      if (url == null) throw Exception('Falha no upload.');
      setState(() => _photoUrl = url);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = context.read<UserProvider>().user;
      if (user == null) throw StateError('Perfil não carregado.');
      final updated = user.copyWith(
        nome: _nomeController.text.trim().isEmpty
            ? null
            : _nomeController.text.trim(),
        empresa:
            _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim(),
        cnpj: _cnpjController.text.trim().isEmpty ? null : _cnpjController.text.trim(),
        segmento: _segmentoController.text.trim().isEmpty
            ? null
            : _segmentoController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim().isEmpty
            ? null
            : _enderecoController.text.trim(),
      );
      final withPhoto = updated.copyWith(photoUrl: _photoUrl);
      await context.read<UserProvider>().saveUser(withPhoto);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perfil atualizado!'),
            backgroundColor: _colorGreenPrimary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar Perfil',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () => Navigator.pop(context),
            child: const Text('Voltar',
                style: TextStyle(color: _colorGold)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, prov, _) {
          if (prov.loadingProfile) {
            return const Center(
                child: CircularProgressIndicator(color: _colorGold));
          }
          _loadFromUser(prov.user);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatar(prov.user?.nome),
                const SizedBox(height: 20),
                _field(_nomeController, 'Nome completo', Icons.person_outline),
                const SizedBox(height: 14),
                _field(
                    _empresaController, 'Nome da Empresa', Icons.store_outlined),
                const SizedBox(height: 14),
                _field(_cnpjController, 'CNPJ (opcional)', Icons.badge_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                _field(_segmentoController, 'Segmento', Icons.category_outlined),
                const SizedBox(height: 14),
                _field(_telefoneController, 'Telefone Comercial',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _field(_enderecoController, 'Endereço', Icons.location_on_outlined,
                    maxLines: 2),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
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
                : const Text('Salvar Alterações',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? nome) {
    final initials = (nome?.isNotEmpty ?? false)
        ? nome!.split(' ').take(2).map((n) => n[0].toUpperCase()).join()
        : '?';
    return Center(
      child: GestureDetector(
        onTap: _uploadingPhoto ? null : _pickProfilePhoto,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: _colorGreenPrimary,
              backgroundImage:
                  _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl != null
                  ? null
                  : Text(initials,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _colorGold,
                  shape: BoxShape.circle,
                  border:
                        Border.all(color: _colorBackground, width: 2),
                ),
                child: _uploadingPhoto
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
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
}