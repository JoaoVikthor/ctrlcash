import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrlcash/models/budget.dart';
import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/product.dart';
import 'package:ctrlcash/models/transaction.dart';

void main() {
  group('AppTransaction', () {
    AppTransaction buildTransaction({
      String id = 'tx1',
      TransactionType type = TransactionType.receita,
      String category = 'Vendas',
      String description = 'Bolo vendido',
      double amount = 150.5,
      DateTime? date,
      PaymentMethod paymentMethod = PaymentMethod.pix,
      bool recurring = false,
      String? notes,
      String? receiptUrl,
      String? budgetId,
    }) =>
        AppTransaction(
          id: id,
          type: type,
          category: category,
          description: description,
          amount: amount,
          date: date ?? DateTime(2026, 3, 5, 14, 30),
          paymentMethod: paymentMethod,
          recurring: recurring,
          notes: notes,
          receiptUrl: receiptUrl,
          budgetId: budgetId,
        );

    test('roundtrip fromMap(toMap(x)) preserva todos os campos', () {
      final original = buildTransaction(
        type: TransactionType.despesa,
        category: 'Ingredientes',
        description: 'Compra de farinha',
        amount: 89.9,
        paymentMethod: PaymentMethod.debito,
        recurring: true,
        notes: 'nota fiscal anexada',
        receiptUrl: 'https://storage/foto.jpg',
        budgetId: 'budget-1',
      );

      final restored =
          AppTransaction.fromMap(original.id, original.toMap());

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.category, original.category);
      expect(restored.description, original.description);
      expect(restored.amount, original.amount);
      expect(restored.date, original.date);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.recurring, original.recurring);
      expect(restored.notes, original.notes);
      expect(restored.receiptUrl, original.receiptUrl);
      expect(restored.budgetId, original.budgetId);
    });

    test('roundtrip preserva campos opcionais nulos', () {
      final original = buildTransaction();

      final restored =
          AppTransaction.fromMap(original.id, original.toMap());

      expect(restored.notes, isNull);
      expect(restored.receiptUrl, isNull);
      expect(restored.budgetId, isNull);
      expect(restored.recurring, isFalse);
    });

    test('toMap serializa date como ISO8601 e enums como strings', () {
      final t = buildTransaction(
        type: TransactionType.receita,
        paymentMethod: PaymentMethod.credito,
        date: DateTime(2026, 3, 5, 14, 30),
      );
      final m = t.toMap();

      expect(m['date'], '2026-03-05T14:30:00.000');
      expect(m['type'], 'receita');
      expect(m['paymentMethod'], 'credito');
      expect(m['amount'], 150.5);
      // id e gerenciado fora do documento (parametro de fromMap).
      expect(m.containsKey('id'), isFalse);
    });

    test('fromMap aceita date como Timestamp do Firestore', () {
      final restored = AppTransaction.fromMap('tx1', {
        'type': 'despesa',
        'category': 'Insumos',
        'description': 'x',
        'amount': 10,
        'date': Timestamp.fromDate(DateTime(2026, 3, 5, 14, 30)),
        'paymentMethod': 'pix',
      });

      // Timestamp.toDate() devolve um DateTime em UTC, entao comparamos o
      // instante (isAtSameMomentAs) e nao == (que exige o mesmo isUtc).
      expect(
        restored.date.isAtSameMomentAs(DateTime(2026, 3, 5, 14, 30)),
        isTrue,
      );
    });

    test('fromMap e resiliente: map vazio usa defaults', () {
      final t = AppTransaction.fromMap('tx1', {});

      expect(t.type, TransactionType.despesa);
      expect(t.category, 'Outros');
      expect(t.description, '');
      expect(t.amount, 0.0);
      expect(t.paymentMethod, PaymentMethod.outro);
      expect(t.recurring, isFalse);
      expect(t.notes, isNull);
      expect(t.date, isNotNull);
    });

    test('fromMap aceita amount int (num -> double)', () {
      final t = AppTransaction.fromMap('tx1', {'amount': 25});
      expect(t.amount, 25.0);
    });

    test('RN01: create proibe amount == 0', () {
      expect(
        () => AppTransaction.create(
          id: 'tx1',
          type: TransactionType.receita,
          category: 'Vendas',
          description: 'x',
          amount: 0,
          date: DateTime(2026),
          paymentMethod: PaymentMethod.pix,
        ),
        throwsArgumentError,
      );
    });

    test('RN01: create proibe amount negativo', () {
      expect(
        () => AppTransaction.create(
          id: 'tx1',
          type: TransactionType.despesa,
          category: 'Vendas',
          description: 'x',
          amount: -0.01,
          date: DateTime(2026),
          paymentMethod: PaymentMethod.pix,
        ),
        throwsArgumentError,
      );
    });

    test('RN01: create aceita amount positivo', () {
      final t = AppTransaction.create(
        id: 'tx1',
        type: TransactionType.receita,
        category: 'Vendas',
        description: 'x',
        amount: 0.01,
        date: DateTime(2026),
        paymentMethod: PaymentMethod.pix,
      );
      expect(t.amount, 0.01);
    });

    test('copyWith altera apenas os campos informados', () {
      final t = buildTransaction();
      final copy = t.copyWith(amount: 200, category: 'Bebidas');

      expect(copy.amount, 200);
      expect(copy.category, 'Bebidas');
      expect(copy.id, t.id);
      expect(copy.type, t.type);
      expect(copy.date, t.date);
    });

    test('TransactionType: firestore roundtrip e labels', () {
      for (final type in TransactionType.values) {
        expect(
          TransactionTypeExt.fromFirestore(type.firestoreValue),
          type,
        );
      }
      expect(TransactionType.receita.isReceita, isTrue);
      expect(TransactionType.despesa.isReceita, isFalse);
      expect(TransactionType.receita.label, 'Receita');
      expect(TransactionType.despesa.label, 'Despesa');
    });

    test('TransactionType.fromFirestore: valor desconhecido vira despesa',
        () {
      expect(
        TransactionTypeExt.fromFirestore('qualquer'),
        TransactionType.despesa,
      );
    });

    test('PaymentMethod: firestore roundtrip, labels e fallback', () {
      for (final method in PaymentMethod.values) {
        expect(
          PaymentMethodExt.fromFirestore(method.firestoreValue),
          method,
        );
      }
      expect(PaymentMethod.pix.label, 'Pix');
      expect(PaymentMethod.credito.label, 'Cartão de Crédito');
      expect(
        PaymentMethodExt.fromFirestore('desconhecido'),
        PaymentMethod.outro,
      );
    });
  });

  group('Ingredient', () {
    Ingredient buildIngredient({
      String id = 'ing1',
      String name = 'Farinha',
      IngredientUnit unit = IngredientUnit.kilo,
      double purchasePrice = 20,
      double packageQuantity = 10,
    }) =>
        Ingredient(
          id: id,
          name: name,
          unit: unit,
          purchasePrice: purchasePrice,
          packageQuantity: packageQuantity,
          createdAt: DateTime(2026, 1, 1),
        );

    test('roundtrip fromMap(toMap(x)) preserva os campos', () {
      final original = buildIngredient();
      final restored =
          Ingredient.fromMap(original.id, original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.unit, original.unit);
      expect(restored.purchasePrice, original.purchasePrice);
      expect(restored.packageQuantity, original.packageQuantity);
      expect(restored.createdAt, original.createdAt);
    });

    test('pricePerUnit = purchasePrice / packageQuantity (RN03)', () {
      expect(buildIngredient().pricePerUnit, closeTo(2.0, 1e-9));

      final gramas = buildIngredient(
        unit: IngredientUnit.grama,
        purchasePrice: 15.9,
        packageQuantity: 1000,
      );
      expect(gramas.pricePerUnit, closeTo(0.0159, 1e-9));
    });

    test('RN03: pricePerUnit e 0 quando packageQuantity <= 0', () {
      expect(buildIngredient(packageQuantity: 0).pricePerUnit, 0.0);
    });

    test('fromMap e resiliente: map vazio usa defaults', () {
      final i = Ingredient.fromMap('ing1', {});

      expect(i.name, '');
      expect(i.unit, IngredientUnit.unidade);
      expect(i.purchasePrice, 0.0);
      expect(i.packageQuantity, 0.0);
      expect(i.pricePerUnit, 0.0);
      expect(i.createdAt, isNotNull);
    });

    test('IngredientUnit: firestore roundtrip e fallback para pacote', () {
      for (final unit in IngredientUnit.values) {
        expect(IngredientUnitExt.fromFirestore(unit.firestoreValue), unit);
      }
      expect(IngredientUnitExt.fromFirestore('desconhecido'),
          IngredientUnit.pacote);
      expect(IngredientUnit.kilo.label, 'kg');
      expect(IngredientUnit.pacote.label, 'pct');
    });
  });

  group('RecipeItem', () {
    test('roundtrip fromMap(toMap(x)) preserva os campos', () {
      const original = RecipeItem(
        ingredientId: 'ing1',
        ingredientName: 'Farinha',
        quantity: 2.5,
      );

      final restored = RecipeItem.fromMap(original.toMap());

      expect(restored.ingredientId, original.ingredientId);
      expect(restored.ingredientName, original.ingredientName);
      expect(restored.quantity, original.quantity);
    });

    test('fromMap e resiliente: map vazio usa defaults', () {
      final item = RecipeItem.fromMap({});

      expect(item.ingredientId, '');
      expect(item.ingredientName, '');
      expect(item.quantity, 0.0);
    });

    test('copyWith altera apenas os campos informados', () {
      const item = RecipeItem(
        ingredientId: 'ing1',
        ingredientName: 'Farinha',
        quantity: 2,
      );

      final copy = item.copyWith(quantity: 3);
      expect(copy.quantity, 3);
      expect(copy.ingredientId, 'ing1');
      expect(copy.ingredientName, 'Farinha');
    });
  });

  group('Product', () {
    Product buildProduct({List<RecipeItem> recipe = const []}) => Product(
          id: 'p1',
          name: 'Bolo',
          description: 'De chocolate',
          recipe: recipe,
          laborCost: 4,
          packagingCost: 1,
          salePrice: 30,
          photoUrl: 'https://storage/foto.png',
          barcode: '7891234567890',
          createdAt: DateTime(2026, 2, 1),
        );

    test('roundtrip fromMap(toMap(x)) preserva campos e receita', () {
      final original = buildProduct(recipe: const [
        RecipeItem(
            ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 2),
        RecipeItem(
            ingredientId: 'ing2', ingredientName: 'Ovo', quantity: 3),
      ]);

      final restored = Product.fromMap(original.id, original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.laborCost, original.laborCost);
      expect(restored.packagingCost, original.packagingCost);
      expect(restored.salePrice, original.salePrice);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.barcode, original.barcode);
      expect(restored.createdAt, original.createdAt);

      expect(restored.recipe, hasLength(2));
      expect(restored.recipe[0].ingredientId, 'ing1');
      expect(restored.recipe[0].quantity, 2.0);
      expect(restored.recipe[1].ingredientId, 'ing2');
      expect(restored.recipe[1].ingredientName, 'Ovo');
      expect(restored.recipe[1].quantity, 3.0);
    });

    test('fromMap e resiliente: map vazio vira produto sem receita', () {
      final p = Product.fromMap('p1', {});

      expect(p.name, '');
      expect(p.description, '');
      expect(p.recipe, isEmpty);
      expect(p.laborCost, 0.0);
      expect(p.packagingCost, 0.0);
      expect(p.salePrice, 0.0);
      expect(p.photoUrl, isNull);
      expect(p.barcode, isNull);
      expect(p.createdAt, isNotNull);
    });

    test('fixedCost soma mao de obra e embalagem', () {
      expect(buildProduct().fixedCost, closeTo(5.0, 1e-9));
    });

    test('fixedMarginPercent calcula margem sobre custo fixo', () {
      // (30 - 5) / 30 * 100 = 83.333...%
      expect(buildProduct().fixedMarginPercent, closeTo(83.3333, 1e-3));
    });

    test('fixedMarginPercent e 0 quando salePrice <= 0', () {
      final p = Product(
        id: 'p1',
        name: 'Bolo',
        description: '',
        recipe: const [],
        laborCost: 4,
        packagingCost: 1,
        salePrice: 0,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p.fixedMarginPercent, 0.0);
    });
  });

  group('Budget', () {
    test('roundtrip fromMap(toMap(x)) preserva os campos', () {
      final original = Budget(
        id: 'b1',
        category: 'Ingredientes',
        limit: 500,
        monthly: false,
        createdAt: DateTime(2026, 1, 10),
      );

      final restored = Budget.fromMap(original.id, original.toMap());

      expect(restored.id, original.id);
      expect(restored.category, original.category);
      expect(restored.limit, original.limit);
      expect(restored.monthly, original.monthly);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromMap e resiliente: map vazio usa defaults', () {
      final b = Budget.fromMap('b1', {});

      expect(b.category, 'Outros');
      expect(b.limit, 0.0);
      expect(b.monthly, isTrue);
      expect(b.createdAt, isNotNull);
    });

    test('fromMap aceita limit int (num -> double)', () {
      final b = Budget.fromMap('b1', {'limit': 300});
      expect(b.limit, 300.0);
    });
  });
}
