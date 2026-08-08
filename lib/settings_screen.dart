import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const colorBackground = Color(0xFF0D1E16);
  static const colorGold = Color(0xFFB89775);
  static const colorCard = Color(0xFF142A20);
  static const colorGreenPrimary = Color(0xFF165A41);
  static const colorTextSec = Color(0xFF7A8B83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: const AppBrandedHeader(title: 'Configurações'),
      body: Consumer<UserProvider>(
        builder: (context, prov, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileHeader(prov),
              const SizedBox(height: 24),
              const Text('Ajustes do Sistema',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildSettingsTile(
                  context, Icons.person_outline, 'Editar Perfil', '/settings/profile'),
              _buildSettingsTile(context, Icons.notifications_none,
                  'Notificações', '/settings/notifications'),
              _buildSettingsTile(context, Icons.lock_outline,
                  'Segurança e Privacidade', '/settings/security'),
              _buildSettingsTile(context, Icons.help_outline,
                  'Ajuda & Suporte', '/settings/help'),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair da Conta',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final nav = Navigator.of(context);
                  await context.read<AuthService>().signOut();
                  nav.pushNamedAndRemoveUntil('/login', (route) => false);
                },
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider prov) {
    final user = prov.user;
    final nome = user?.nome ?? 'Usuário';
    final email = user?.email ?? '';
    final initials = nome.split(' ').take(2).map((n) {
      if (n.isEmpty) return '?';
      return n[0].toUpperCase();
    }).join();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorGreenPrimary,
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(color: colorTextSec, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (user?.empresa != null && user!.empresa!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.empresa!,
                      style: const TextStyle(color: colorGold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: colorGold),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white54, size: 16),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}