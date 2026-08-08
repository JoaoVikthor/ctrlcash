import 'package:flutter/material.dart';

import '../../widgets/app_branded_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: const AppBrandedHeader(title: 'Ajuda & Suporte', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Central de ajuda',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tire dúvidas e encontre suporte.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _tile(Icons.menu_book_outlined, 'Como usar o CashCtrl', () {
            _showInfo(context, 'O CashCtrl organiza suas finanças em transações, orçamentos e produtos. Use o menu para navegar entre as telas.');
          }),
          _tile(Icons.receipt_long_outlined, 'Registrar transações', () {
            _showInfo(context, 'Em "Transações", toque no + para registrar uma receita ou despesa. Informe valor, categoria e data.');
          }),
          _tile(Icons.account_balance_outlined, 'Criar orçamentos', () {
            _showInfo(context, 'Em "Orçamentos", defina um limite mensal por categoria. O app calcula o quanto já foi gasto.');
          }),
          _tile(Icons.inventory_2_outlined, 'Parque de insumos', () {
            _showInfo(context, 'Cadastre os materiais que você compra. O app calcula o preço por unidade automaticamente (ex.: preço por grama).');
          }),
          _tile(Icons.lunch_dining_outlined, 'Ficha técnica / Ticket', () {
            _showInfo(context, 'Crie um produto selecionando os insumos, a quantidade usada, mão de obra e embalagem. O app mostra o custo por ingrediente e se o produto dá lucro ou prejuízo.');
          }),
          _tile(Icons.support_agent_outlined, 'Falar com suporte', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Contato: suporte@ctrlcash.app'),
                  backgroundColor: _colorGreenPrimary),
            );
          }),
          _tile(Icons.bug_report_outlined, 'Reportar um problema', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Obrigado! Reporte enviado.'),
                  backgroundColor: _colorGreenPrimary),
            );
          }),
          const SizedBox(height: 24),
          const Text('Sobre o app',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _colorCard, borderRadius: BorderRadius.circular(12)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CashCtrl v1.0.0',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Controle financeiro pessoal e de negócio com cálculo de ticket e ficha técnica de produtos.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: _colorGold),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showInfo(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _colorCard,
        title: const Text('Ajuda', style: TextStyle(color: Colors.white)),
        content: Text(text, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi',
                  style: TextStyle(color: _colorGold))),
        ],
      ),
    );
  }
}