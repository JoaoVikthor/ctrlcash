import 'package:flutter/material.dart';

import '../../widgets/app_branded_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _colorBackground = Color(0xFF0D1E16);
  static const Color _colorGreenPrimary = Color(0xFF165A41);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorCard = Color(0xFF142A20);

  bool _orcamentos = true;
  bool _despesas = false;
  bool _metas = true;
  bool _produtosBaixo = true;
  TimeOfDay _horario = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBackground,
      appBar: const AppBrandedHeader(title: 'Notificações', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Preferências de alerta',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Receba lembretes para manter suas finanças em dia.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _switchTile('Alerta de orçamento estourado',
              'Avisa quando um orçamento ultrapassa o limite', _orcamentos,
              (v) => setState(() => _orcamentos = v)),
          _switchTile('Lembrete de despesas recorrentes',
              'Avisa sobre contas que vencem em breve', _despesas,
              (v) => setState(() => _despesas = v)),
          _switchTile('Acompanhamento de metas',
              'Progresso das suas metas de economia', _metas,
              (v) => setState(() => _metas = v)),
          _switchTile('Produtos com baixa margem',
              'Avisa quando um produto está perto de dar prejuízo', _produtosBaixo,
              (v) => setState(() => _produtosBaixo = v)),
          const SizedBox(height: 24),
          const Text('Horário das notificações',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _horario,
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: _colorGreenPrimary)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _horario = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _colorCard, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: _colorGold),
                  const SizedBox(width: 12),
                  const Text('Horário preferido',
                      style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Text(
                      '${_horario.hour.toString().padLeft(2, '0')}:${_horario.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: _colorGold, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Preferências salvas.'),
                    backgroundColor: _colorGreenPrimary),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _colorGreenPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Salvar Preferências',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: _colorCard, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        activeTrackColor: _colorGreenPrimary,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle:
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}