import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  static const Color _colorDrawerBg = Color(0xFF142A20);
  static const Color _colorGold = Color(0xFFB89775);
  static const Color _colorGreenPrimary = Color(0xFF165A41);

  static const List<_DrawerEntry> _items = [
    _DrawerEntry(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
    _DrawerEntry(icon: Icons.lunch_dining_outlined, label: 'Produtos', route: '/products'),
    _DrawerEntry(icon: Icons.inventory_2_outlined, label: 'Insumos', route: '/ingredients'),
    _DrawerEntry(icon: Icons.account_balance_outlined, label: 'Orçamentos', route: '/budgets'),
    _DrawerEntry(icon: Icons.receipt_long_outlined, label: 'Transações', route: '/expenses'),
    _DrawerEntry(icon: Icons.bar_chart_outlined, label: 'Relatórios', route: '/reports'),
    _DrawerEntry(icon: Icons.settings_outlined, label: 'Configurações', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final String normalizedRoute =
        currentRoute.startsWith('/') ? currentRoute : '/$currentRoute';
    return Drawer(
      backgroundColor: _colorDrawerBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(color: Color(0xFF1F3A2C), thickness: 1, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: _items
                    .map((item) => _drawerTile(context, item, normalizedRoute))
                    .toList(growable: false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text(
                'CashCtrl v1.0.0',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 20),
child: Row(
          children: [
            Image.asset(
              'assets/images/logo_drawer.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.ac_unit, color: _colorGold, size: 28),
            ),
            const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CashCtrl',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Adaptar. Resolver. Desenvolver.',
                  style: TextStyle(color: _colorGold, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, _DrawerEntry entry, String current) {
    final bool isSelected = current == entry.route;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? _colorGreenPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          entry.icon,
          color: isSelected ? Colors.white : _colorGold,
        ),
        title: Text(
          entry.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, entry.route);
          }
        },
      ),
    );
  }
}

class _DrawerEntry {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerEntry({
    required this.icon,
    required this.label,
    required this.route,
  });
}