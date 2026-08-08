import 'package:flutter/material.dart';

/// AppBar padrao do CashCtrl com a logo (camaleao nas cores do app) e o
/// botao de menu. Usar com Scaffold.extendBodyBehindAppBar=true passando
/// backgroundColor transparent.
class AppBrandedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool centerTitle;

  const AppBrandedHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            )
          : Image.asset(
              'assets/images/logo.png',
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
      centerTitle: centerTitle,
    );
  }
}