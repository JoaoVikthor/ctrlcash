import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_branded_header.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: const AppBrandedHeader(title: 'Segurança e Privacidade', showBack: true),
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
          _tile(Icons.lock_outline, 'Alterar senha', _showChangePasswordDialog),
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

  void _toast(String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  /// Diálogo para alterar a senha: reautentica com a senha atual e troca.
  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool hideCurrent = true;
    bool hideNew = true;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: _colorCard,
            title: const Text('Alterar senha',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: hideCurrent,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Senha atual',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: _colorGold, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          hideCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20),
                      onPressed: () =>
                          setDialogState(() => hideCurrent = !hideCurrent),
                    ),
                    filled: true,
                    fillColor: _colorBackground,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _colorGold, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newCtrl,
                  obscureText: hideNew,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nova senha (mín. 6 caracteres)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_reset_outlined,
                        color: _colorGold, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          hideNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20),
                      onPressed: () =>
                          setDialogState(() => hideNew = !hideNew),
                    ),
                    filled: true,
                    fillColor: _colorBackground,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _colorGold, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: _colorGold)),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        final current = currentCtrl.text.trim();
                        final newPass = newCtrl.text;
                        if (current.isEmpty || newPass.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Preencha a senha atual e a nova senha.'),
                                backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (newPass.length < 6) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'A nova senha deve ter ao menos 6 caracteres.'),
                                backgroundColor: Colors.red),
                          );
                          return;
                        }
                        setDialogState(() => loading = true);
                        try {
                          await context.read<AuthService>().changePassword(
                                currentPassword: current,
                                newPassword: newPass,
                              );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          _toast('Senha alterada com sucesso!',
                              color: _colorGreenPrimary);
                        } on AuthException catch (e) {
                          if (!ctx.mounted) return;
                          setDialogState(() => loading = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(e.message),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: _colorGold, strokeWidth: 2))
                    : const Text('Salvar',
                        style: TextStyle(color: _colorGreenPrimary)),
              ),
            ],
          );
        },
      ),
    );
    currentCtrl.dispose();
    newCtrl.dispose();
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
      await _showDeletePasswordDialog();
    }
  }

  /// Diálogo único de reautenticação: pede a senha e exclui a conta.
  Future<void> _showDeletePasswordDialog() async {
    final passCtrl = TextEditingController();
    bool hidePassword = true;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: _colorCard,
            title: const Text('Confirmar exclusão',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Digite sua senha para confirmar a exclusão da conta.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: hidePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: _colorGold, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20),
                      onPressed: () => setDialogState(
                          () => hidePassword = !hidePassword),
                    ),
                    filled: true,
                    fillColor: _colorBackground,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _colorGold, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: _colorGold)),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        final pass = passCtrl.text;
                        if (pass.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Digite sua senha.'),
                                backgroundColor: Colors.red),
                          );
                          return;
                        }
                        setDialogState(() => loading = true);
                        try {
                          await context
                              .read<AuthService>()
                              .deleteAccount(password: pass);
                          // A navegação para /login acontece automaticamente
                          // pelo listener de authStateChanges no main.dart.
                          if (ctx.mounted) Navigator.pop(ctx);
                        } on AuthException catch (e) {
                          if (!ctx.mounted) return;
                          setDialogState(() => loading = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(e.message),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.red, strokeWidth: 2))
                    : const Text('Excluir conta',
                        style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
    passCtrl.dispose();
  }
}
