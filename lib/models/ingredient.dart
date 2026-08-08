import 'package:cloud_firestore/cloud_firestore.dart';

/// Unidades de medida suportadas para os insumos.
enum IngredientUnit { grama, kilo, litro, mililitro, unidade, pacote }

extension IngredientUnitExt on IngredientUnit {
  String get label => switch (this) {
        IngredientUnit.grama => 'g',
        IngredientUnit.kilo => 'kg',
        IngredientUnit.litro => 'L',
        IngredientUnit.mililitro => 'ml',
        IngredientUnit.unidade => 'un',
        IngredientUnit.pacote => 'pct',
      };

  String get firestoreValue => switch (this) {
        IngredientUnit.grama => 'g',
        IngredientUnit.kilo => 'kg',
        IngredientUnit.litro => 'L',
        IngredientUnit.mililitro => 'ml',
        IngredientUnit.unidade => 'un',
        IngredientUnit.pacote => 'pct',
      };

  static IngredientUnit fromFirestore(String v) => switch (v) {
        'g' => IngredientUnit.grama,
        'kg' => IngredientUnit.kilo,
        'L' => IngredientUnit.litro,
        'ml' => IngredientUnit.mililitro,
        'un' => IngredientUnit.unidade,
        _ => IngredientUnit.pacote,
      };
}

/// Insumo comprado para fabricar produtos.
///
/// O usuario informa o [purchasePrice] (preco pago) e a [packageQuantity]
/// (quantidade da embalagem). O preco por unidade base e calculado em
/// [pricePerUnit] e usado pelas fichas tecnicas para o ticket do produto.
class Ingredient {
  final String id;
  final String name;
  final IngredientUnit unit;
  final double purchasePrice;
  final double packageQuantity;
  final DateTime createdAt;

  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.purchasePrice,
    required this.packageQuantity,
    required this.createdAt,
  });

  /// Preco por unidade base (ex.: preco por grama, por ml, por unidade).
  /// Usado para calcular o custo de cada ingrediente na ficha tecnica.
  double get pricePerUnit =>
      packageQuantity > 0 ? purchasePrice / packageQuantity : 0;

  factory Ingredient.fromMap(String id, Map<String, dynamic> m) {
    final rawDate = m['createdAt'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    return Ingredient(
      id: id,
      name: (m['name'] ?? '') as String,
      unit: IngredientUnitExt.fromFirestore((m['unit'] ?? 'un') as String),
      purchasePrice: ((m['purchasePrice'] ?? 0) as num).toDouble(),
      packageQuantity: ((m['packageQuantity'] ?? 0) as num).toDouble(),
      createdAt: date,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'unit': unit.firestoreValue,
        'purchasePrice': purchasePrice,
        'packageQuantity': packageQuantity,
        'createdAt': createdAt.toIso8601String(),
      };
}