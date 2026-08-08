import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'widgets/app_branded_header.dart';
import 'widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorCard = Color(0xFF142A20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: const AppBrandedHeader(title: 'Configurações'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Ajustes do Sistema', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSettingsTile(Icons.person_outline, 'Editar Perfil'),
          _buildSettingsTile(Icons.notifications_none, 'Notificações'),
          _buildSettingsTile(Icons.lock_outline, 'Segurança e Privacidade'),
          _buildSettingsTile(Icons.help_outline, 'Ajuda & Suporte'),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair da Conta', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              final nav = Navigator.of(context);
              await context.read<AuthService>().signOut();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
          )
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: colorCard, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: colorGold),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () {},
      ),
    );
  }
}