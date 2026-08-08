import 'package:flutter/material.dart';

/// Categorias sugeridas pelo app (editaveis no futuro).
class CategoryDef {
  final String name;
  final IconData icon;
  final int colorValue;

  const CategoryDef(this.name, this.icon, this.colorValue);

  Color get color => Color(colorValue);
}

const List<CategoryDef> kExpenseCategories = [
  CategoryDef('Moradia', Icons.home_outlined, 0xFF4A90D9),
  CategoryDef('Alimentação', Icons.restaurant_outlined, 0xFFE0913A),
  CategoryDef('Transporte', Icons.directions_car_outlined, 0xFF9C6BD6),
  CategoryDef('Lazer', Icons.sports_esports_outlined, 0xFFE05A5A),
  CategoryDef('Saúde', Icons.medical_services_outlined, 0xFF46C7B3),
  CategoryDef('Educação', Icons.school_outlined, 0xFF6BA3E0),
  CategoryDef('Tecnologia', Icons.computer_outlined, 0xFF7A8B83),
  CategoryDef('Insumos', Icons.inventory_2_outlined, 0xFFB89775),
  CategoryDef('Marketing', Icons.campaign_outlined, 0xFFE086B8),
  CategoryDef('Salários', Icons.badge_outlined, 0xFF5DBB63),
  CategoryDef('Impostos', Icons.receipt_long_outlined, 0xFFD64A4A),
  CategoryDef('Outros', Icons.category_outlined, 0xFF7A8B83),
];

const List<CategoryDef> kIncomeCategories = [
  CategoryDef('Salário', Icons.account_balance_wallet_outlined, 0xFF5DBB63),
  CategoryDef('Vendas', Icons.point_of_sale_outlined, 0xFF46C7B3),
  CategoryDef('Investimentos', Icons.trending_up, 0xFF4A90D9),
  CategoryDef('Freelance', Icons.work_outline, 0xFFB89775),
  CategoryDef('Reembolso', Icons.replay, 0xFF9C6BD6),
  CategoryDef('Outros', Icons.category_outlined, 0xFF7A8B83),
];

CategoryDef findCategory(String name, {bool isIncome = false}) {
  final list = isIncome ? kIncomeCategories : kExpenseCategories;
  return list.firstWhere(
    (c) => c.name == name,
    orElse: () => const CategoryDef('Outros', Icons.category_outlined, 0xFF7A8B83),
  );
}