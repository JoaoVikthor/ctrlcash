import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  bool _isLoadingFacebook = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _anyLoading =>
      _isLoading || _isLoadingGoogle || _isLoadingFacebook;

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _mostrarErro('Preencha e-mail e senha.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().signInWithEmail(
            email: email,
            password: password,
          );
      _navegarParaDashboard();
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mapFirebaseError(e));
    } catch (_) {
      _mostrarErro('Ocorreu um erro ao entrar.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginComGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      final user = await context.read<AuthService>().signInWithGoogle();
      if (user == null) {
        return; // cancelado pelo usuario
      }
      _navegarParaDashboard();
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mapFirebaseError(e));
    } catch (_) {
      _mostrarErro('Ocorreu um erro ao entrar com o Google.');
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  Future<void> _loginComFacebook() async {
    setState(() => _isLoadingFacebook = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.token);
        await FirebaseAuth.instance.signInWithCredential(credential);
        _navegarParaDashboard();
      } else {
        _mostrarErro('Login cancelado ou mal sucedido.');
      }
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mapFirebaseError(e));
    } catch (_) {
      _mostrarErro('Ocorreu um erro ao entrar com o Facebook.');
    } finally {
      if (mounted) setState(() => _isLoadingFacebook = false);
    }
  }

  void _esqueceuSenha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperação de senha em breve.'),
        backgroundColor: _colorGreenPrimary,
      ),
    );
  }

  void _navegarParaDashboard() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _irParaCadastro() {
    Navigator.pushNamed(context, '/cadastro');
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
    );
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return e.message ?? 'Erro ao entrar.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Image.asset(
                'assets/images/logo_dourado.png',
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'CashCtrl',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bem-vindo de volta!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 36),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Senha',
                obscure: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _anyLoading ? null : _esqueceuSenha,
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(color: _colorGold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildPrimaryButton(
                onPressed: _anyLoading ? null : _login,
                isLoading: _isLoading,
                label: 'Entrar',
              ),
              const SizedBox(height: 28),
              _buildDivider(),
              const SizedBox(height: 22),
              const Text(
                'Ou conecte usando',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(
                    icon: FontAwesomeIcons.google,
                    color: const Color(0xFFDB4437),
                    isLoading: _isLoadingGoogle,
                    onTap: _anyLoading ? () {} : _loginComGoogle,
                    tooltip: 'Entrar com Google',
                  ),
                  const SizedBox(width: 24),
                  _socialButton(
                    icon: FontAwesomeIcons.facebookF,
                    color: const Color(0xFF1877F2),
                    isLoading: _isLoadingFacebook,
                    onTap: _anyLoading ? () {} : _loginComFacebook,
                    tooltip: 'Entrar com Facebook',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'É seu Primeiro Acesso? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _irParaCadastro,
                    child: const Text(
                      'Registre-se',
                      style: TextStyle(
                        color: _colorGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _colorGold, size: 20)
            : null,
        suffixIcon: suffix,
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

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _colorGreenPrimary,
        disabledBackgroundColor: _colorGreenPrimary.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child:
                Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
            child:
                Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _colorCard,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ),
                )
              : FaIcon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}