import 'package:flutter_test/flutter_test.dart';

import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/product.dart';
import 'package:ctrlcash/utils/product_calculator.dart';

Ingredient _ing(
  String id, {
  double purchasePrice = 0,
  double packageQuantity = 1,
  IngredientUnit unit = IngredientUnit.unidade,
}) =>
    Ingredient(
      id: id,
      name: 'Insumo $id',
      unit: unit,
      purchasePrice: purchasePrice,
      packageQuantity: packageQuantity,
      createdAt: DateTime(2026, 1, 1),
    );

Product _product({
  List<RecipeItem> recipe = const [],
  double laborCost = 0,
  double packagingCost = 0,
  double salePrice = 0,
}) =>
    Product(
      id: 'p1',
      name: 'Bolo de Chocolate',
      description: '',
      recipe: recipe,
      laborCost: laborCost,
      packagingCost: packagingCost,
      salePrice: salePrice,
      createdAt: DateTime(2026, 1, 1),
    );

/// Cenario canonico usado na maioria dos testes:
/// - Farinha: R$ 20,00 / 10 = R$ 2,00 por unidade; 3 unidades -> R$ 6,00
/// - Chocolate: R$ 30,00 / 5 = R$ 6,00 por unidade; 2 unidades -> R$ 12,00
/// - ingredientes: R$ 18,00 | mao de obra: R$ 4,00 | embalagem: R$ 1,00
/// - custo total: R$ 23,00
({Map<String, Ingredient> ingredients, Product product}) _scenario({
  double salePrice = 50,
}) {
  final ingredients = <String, Ingredient>{
    'farinha': _ing('farinha', purchasePrice: 20, packageQuantity: 10),
    'chocolate': _ing('chocolate', purchasePrice: 30, packageQuantity: 5),
  };
  final product = _product(
    recipe: const [
      RecipeItem(
          ingredientId: 'farinha',
          ingredientName: 'Farinha',
          quantity: 3),
      RecipeItem(
          ingredientId: 'chocolate',
          ingredientName: 'Chocolate',
          quantity: 2),
    ],
    laborCost: 4,
    packagingCost: 1,
    salePrice: salePrice,
  );
  return (ingredients: ingredients, product: product);
}

void main() {
  group('ProductCalculator.calculate - custo total', () {
    test('soma ingredientes + mao de obra + embalagem', () {
      final s = _scenario();
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.ingredientsTotal, closeTo(18.0, 1e-9));
      expect(r.laborCost, 4.0);
      expect(r.packagingCost, 1.0);
      expect(r.totalCost, closeTo(23.0, 1e-9));
      expect(r.salePrice, 50.0);
    });

    test('detalha cada linha com unitPrice e lineCost (pricePerUnit * qtd)',
        () {
      final s = _scenario();
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.lines, hasLength(2));

      final farinha = r.lines[0];
      expect(farinha.item.ingredientId, 'farinha');
      expect(farinha.ingredient, isNotNull);
      expect(farinha.unitPrice, closeTo(2.0, 1e-9)); // 20 / 10
      expect(farinha.lineCost, closeTo(6.0, 1e-9)); // 2.0 * 3
      expect(farinha.missing, isFalse);

      final chocolate = r.lines[1];
      expect(chocolate.item.ingredientId, 'chocolate');
      expect(chocolate.unitPrice, closeTo(6.0, 1e-9)); // 30 / 5
      expect(chocolate.lineCost, closeTo(12.0, 1e-9)); // 6.0 * 2
      expect(chocolate.missing, isFalse);
    });

    test('recebe o produto original no resultado', () {
      final s = _scenario();
      final r = ProductCalculator.calculate(s.product, s.ingredients);
      expect(r.product, same(s.product));
    });
  });

  group('veredito lucro x prejuizo (isLucro / isPrejuizo)', () {
    // A UI exibe "ESTE PRODUTO DÁ LUCRO"/"ESTE PRODUTO DÁ PREJUÍZO" a partir
    // de TicketResult.isLucro — aqui testamos a logica pura do veredito.
    test('preco de venda > custo total -> DÁ LUCRO', () {
      final s = _scenario(salePrice: 30); // custo 23 -> lucro 7
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.profit, closeTo(7.0, 1e-9));
      expect(r.isLucro, isTrue);
      expect(r.isPrejuizo, isFalse);
    });

    test('preco de venda < custo total -> DÁ PREJUÍZO', () {
      final s = _scenario(salePrice: 20); // custo 23 -> prejuizo -3
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.profit, closeTo(-3.0, 1e-9));
      expect(r.isPrejuizo, isTrue);
      expect(r.isLucro, isFalse);
    });

    test('preco de venda == custo total -> lucro zero (sem prejuizo)', () {
      final s = _scenario(salePrice: 23);
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.profit, 0.0);
      expect(r.isLucro, isTrue); // profit >= 0
      expect(r.isPrejuizo, isFalse);
      expect(r.marginPercent, closeTo(0.0, 1e-9));
    });
  });

  group('margem (%)', () {
    test('margem = lucro / preco de venda * 100', () {
      final s = _scenario(salePrice: 50); // lucro 27 / 50 = 54%
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.marginPercent, closeTo(54.0, 1e-9));
    });

    test('margem negativa quando ha prejuizo', () {
      final s = _scenario(salePrice: 20); // lucro -3 / 20 = -15%
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.marginPercent, closeTo(-15.0, 1e-9));
    });

    test('margem e 0 quando preco de venda e zero (guarda da classe)', () {
      final s = _scenario(salePrice: 0);
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.marginPercent, 0.0);
      expect(r.profit, closeTo(-23.0, 1e-9));
      expect(r.isPrejuizo, isTrue);
    });
  });

  group('markup', () {
    test('markup = preco de venda / custo total', () {
      final s = _scenario(salePrice: 46); // 46 / 23 = 2.0x
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.markup, closeTo(2.0, 1e-9));
    });

    test('markup < 1 quando ha prejuizo', () {
      final s = _scenario(salePrice: 11.5); // 11.5 / 23 = 0.5x
      final r = ProductCalculator.calculate(s.product, s.ingredients);

      expect(r.markup, closeTo(0.5, 1e-9));
      expect(r.isPrejuizo, isTrue);
    });

    test('markup e 0 quando custo total e zero (guarda da classe)', () {
      final product = _product(salePrice: 10);
      final r = ProductCalculator.calculate(product, const {});

      expect(r.totalCost, 0.0);
      expect(r.markup, 0.0);
    });
  });

  group('custo zero / sem ingredientes', () {
    test('receita vazia e custos fixos zerados -> custo total 0, lucro cheio',
        () {
      final product = _product(salePrice: 10);
      final r = ProductCalculator.calculate(product, const {});

      expect(r.lines, isEmpty);
      expect(r.ingredientsTotal, 0.0);
      expect(r.laborCost, 0.0);
      expect(r.packagingCost, 0.0);
      expect(r.totalCost, 0.0);
      expect(r.profit, closeTo(10.0, 1e-9));
      expect(r.marginPercent, closeTo(100.0, 1e-9));
      expect(r.hasMissingIngredients, isFalse);
      expect(r.isLucro, isTrue);
    });

    test('apenas custos fixos (sem ingredientes) compoem o custo total', () {
      final product =
          _product(laborCost: 5, packagingCost: 2, salePrice: 20);
      final r = ProductCalculator.calculate(product, const {});

      expect(r.ingredientsTotal, 0.0);
      expect(r.totalCost, closeTo(7.0, 1e-9));
      expect(r.profit, closeTo(13.0, 1e-9));
    });
  });

  group('ingredientes faltantes', () {
    test('marca linha como missing e zera o custo da linha', () {
      final ingredients = <String, Ingredient>{
        'farinha': _ing('farinha', purchasePrice: 20, packageQuantity: 10),
      };
      final product = _product(
        recipe: const [
          RecipeItem(
              ingredientId: 'farinha',
              ingredientName: 'Farinha',
              quantity: 3),
          RecipeItem(
              ingredientId: 'cacau',
              ingredientName: 'Cacau (apagado)',
              quantity: 2),
        ],
        laborCost: 4,
        packagingCost: 1,
        salePrice: 30,
      );

      final r = ProductCalculator.calculate(product, ingredients);

      expect(r.hasMissingIngredients, isTrue);
      expect(r.lines, hasLength(2));

      final missingLine = r.lines[1];
      expect(missingLine.missing, isTrue);
      expect(missingLine.ingredient, isNull);
      expect(missingLine.unitPrice, 0.0);
      expect(missingLine.lineCost, 0.0);

      // Custo total desconsidera a linha faltante: 6 (farinha) + 4 + 1 = 11.
      expect(r.ingredientsTotal, closeTo(6.0, 1e-9));
      expect(r.totalCost, closeTo(11.0, 1e-9));
      expect(r.profit, closeTo(19.0, 1e-9));
      expect(r.isLucro, isTrue);
    });

    test('receita com todos os ingredientes ausentes -> custo so de fixos',
        () {
      final product = _product(
        recipe: const [
          RecipeItem(ingredientId: 'a', ingredientName: 'A', quantity: 1),
          RecipeItem(ingredientId: 'b', ingredientName: 'B', quantity: 1),
        ],
        laborCost: 3,
        packagingCost: 2,
        salePrice: 10,
      );
      // Mapa de insumos vazio: nenhuma linha consegue ser resolvida.
      final r = ProductCalculator.calculate(product, const {});

      expect(r.hasMissingIngredients, isTrue);
      expect(r.lines, hasLength(2));
      expect(r.lines.every((l) => l.missing), isTrue);
      expect(r.ingredientsTotal, 0.0);
      expect(r.totalCost, closeTo(5.0, 1e-9));
      expect(r.profit, closeTo(5.0, 1e-9));
    });
  });
}
