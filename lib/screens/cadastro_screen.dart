import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _aceitouTermos = false;
  bool _obscureSenha = true;
  bool _obscureConfirma = true;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmaController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _segmentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();

  static const int _totalSteps = 2;

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaController.dispose();
    _empresaController.dispose();
    _cnpjController.dispose();
    _segmentoController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  bool _validarEtapa1() {
    final String nome = _nomeController.text.trim();
    final String email = _emailController.text.trim();
    final String senha = _senhaController.text;
    final String confirma = _confirmaController.text;

    if (nome.isEmpty) {
      _mostrarErro('Informe o nome completo.');
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      _mostrarErro('Informe um e-mail válido.');
      return false;
    }
    if (senha.length < 6) {
      _mostrarErro('A senha deve ter ao menos 6 caracteres.');
      return false;
    }
    if (senha != confirma) {
      _mostrarErro('As senhas não coincidem.');
      return false;
    }
    if (!_aceitouTermos) {
      _mostrarErro('É preciso aceitar os Termos de Uso.');
      return false;
    }
    return true;
  }

  void _avancar() {
    if (_currentStep == 0) {
      if (!_validarEtapa1()) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 1) {
      _finalizarCadastro();
    }
  }

  void _voltar() {
    if (_currentStep == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finalizarCadastro() async {
    if (_empresaController.text.trim().isEmpty) {
      _mostrarErro('Informe o nome da empresa.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appUser = AppUser(
        uid: '',
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        empresa: _empresaController.text.trim().isEmpty
            ? null
            : _empresaController.text.trim(),
        cnpj: _cnpjController.text.trim().isEmpty
            ? null
            : _cnpjController.text.trim(),
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
      final user = await context.read<AuthService>().registerWithEmail(
            userProfile: appUser,
            password: _senhaController.text,
          );
      if (!mounted) return;
      await context.read<UserProvider>().loadProfile(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: _colorGreenPrimary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mapFirebaseError(e));
    } catch (_) {
      _mostrarErro('Ocorreu um erro ao finalizar o cadastro.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
    );
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca.';
      default:
        return e.message ?? 'Erro ao cadastrar.';
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
          onPressed: _isLoading ? null : _voltar,
        ),
        title: const Text(
          'Criar Conta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildStepIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildEtapaDadosPessoais(),
                  _buildEtapaNegocio(),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final bool active = index == _currentStep;
          final bool done = index < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                  right: index == _totalSteps - 1 ? 0 : 8),
              height: 6,
              decoration: BoxDecoration(
                color: done
                    ? _colorGreenPrimary
                    : active
                        ? _colorGold
                        : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEtapaDadosPessoais() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Dados Pessoais', 'Conte-nos quem é você.'),
          const SizedBox(height: 20),
          _buildField(
              controller: _nomeController,
              label: 'Nome completo',
              icon: Icons.person_outline),
          const SizedBox(height: 14),
          _buildField(
              controller: _emailController,
              label: 'E-mail',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildField(
            controller: _senhaController,
            label: 'Senha',
            icon: Icons.lock_outline,
            obscure: _obscureSenha,
            toggleObscure: () =>
                setState(() => _obscureSenha = !_obscureSenha),
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _confirmaController,
            label: 'Confirmação de senha',
            icon: Icons.lock_outline,
            obscure: _obscureConfirma,
            toggleObscure: () =>
                setState(() => _obscureConfirma = !_obscureConfirma),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _aceitouTermos,
                onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
                activeColor: _colorGreenPrimary,
                checkColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                      () => _aceitouTermos = !_aceitouTermos),
                  child: const Text(
                    'Aceito os Termos de Uso',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaNegocio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Sobre o Negócio', 'Informações da sua empresa.'),
          const SizedBox(height: 20),
          _buildField(
              controller: _empresaController,
              label: 'Nome da Empresa',
              icon: Icons.store_outlined),
          const SizedBox(height: 14),
          _buildField(
              controller: _cnpjController,
              label: 'CNPJ (Opcional)',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          _buildField(
              controller: _segmentoController,
              label: 'Segmento',
              icon: Icons.category_outlined),
          const SizedBox(height: 14),
          _buildField(
              controller: _telefoneController,
              label: 'Telefone Comercial',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _buildField(
              controller: _enderecoController,
              label: 'Endereço',
              icon: Icons.location_on_outlined,
              maxLines: 2),
          const SizedBox(height: 18),
          _buildAddPhoto(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAddPhoto() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isLoading
          ? null
          : () => _mostrarErro('Upload de foto em breve.'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: _colorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: _colorGold),
            SizedBox(width: 12),
            Text(
              'Adicionar foto da empresa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: _colorGold, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
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

  Widget _buildBottomActions() {
    final bool isLast = _currentStep == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          TextButton(
            onPressed: _isLoading ? null : _voltar,
            child: Text(
              _currentStep == 0 ? 'Cancelar' : 'Voltar',
              style: const TextStyle(color: _colorGold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _avancar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorGreenPrimary,
                disabledBackgroundColor:
                    _colorGreenPrimary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLast ? 'Finalizar Cadastro' : 'Próximo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}