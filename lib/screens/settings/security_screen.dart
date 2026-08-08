import 'package:flutter/material.dart';

import '../../widgets/app_branded_header.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: const AppBrandedHeader(title: 'Segurança e Privacidade'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Conta e acesso',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Gerencie como você protege sua conta.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _tile(Icons.lock_outline, 'Alterar senha', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Recuperação de senha em breve.'),
                  backgroundColor: _colorGold),
            );
          }),
          _tile(Icons.email_outlined, 'E-mail de recuperação', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Configuração de e-mail em breve.'),
                  backgroundColor: _colorGold),
            );
          }),
          _tile(Icons.devices_outlined, 'Dispositivos conectados', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Nenhum outro dispositivo conectado.'),
                  backgroundColor: _colorGreenPrimary),
            );
          }),
          const SizedBox(height: 24),
          const Text('Privacidade',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _tile(Icons.privacy_tip_outlined, 'Política de Privacidade', () {}),
          _tile(Icons.description_outlined, 'Termos de Uso', () {}),
          _tile(Icons.delete_forever_outlined, 'Excluir minha conta', () {
            _confirmDeleteAccount(context);
          }, isDanger: true),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap,
      {bool isDanger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isDanger ? Colors.red : _colorGold),
        title: Text(title,
            style: TextStyle(
                color: isDanger ? Colors.red : Colors.white,
                fontWeight: isDanger ? FontWeight.bold : FontWeight.normal)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _colorCard,
        title: const Text('Excluir conta?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Esta ação é irreversível. Todos os seus dados serão apagados.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: _colorGold))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Exclusão de conta em breve.'),
            backgroundColor: _colorGold),
      );
    }
  }
}