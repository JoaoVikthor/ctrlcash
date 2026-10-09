import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/transaction.dart' as tx;
import '../models/budget.dart';
import '../models/ingredient.dart';
import '../models/ingredient_offer.dart';
import '../models/price_audit_log.dart';
import '../models/product.dart';

/// Servico de acesso ao Firestore do CashCtrl.
///
/// Todos os dados do usuario ficam sob users/{uid}/... (subcolecoes),
/// garantindo o isolamento por UID exigido pelas regras (RN02).
class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _userDoc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> _budgetCol(String uid) =>
      _userDoc(uid).collection('budgets');

  CollectionReference<Map<String, dynamic>> _ingredientCol(String uid) =>
      _userDoc(uid).collection('ingredients');

  DocumentReference<Map<String, dynamic>> _ingredientDoc(
          String uid, String id) =>
      _ingredientCol(uid).doc(id);

  CollectionReference<Map<String, dynamic>> _auditLogCol(String uid) =>
      _userDoc(uid).collection('price_audit_logs');

  CollectionReference<Map<String, dynamic>> _productCol(String uid) =>
      _userDoc(uid).collection('products');

  // ---------------- PERFIL / NEGOCIO ----------------

  Future<void> saveUser(AppUser user) async {
    await _userDoc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  // ---------------- TRANSACOES ----------------

  Stream<List<tx.AppTransaction>> transactionsStream(String uid) {
    return _txCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => tx.AppTransaction.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> addTransaction(String uid, tx.AppTransaction t) async {
    final ref = await _txCol(uid).add(t.toMap());
    return ref.id;
  }

  Future<void> updateTransaction(String uid, tx.AppTransaction t) async {
    await _txCol(uid).doc(t.id).set(t.toMap());
  }

  Future<void> deleteTransaction(String uid, String id) async {
    await _txCol(uid).doc(id).delete();
  }

  // ---------------- ORCAMENTOS ----------------

  Stream<List<Budget>> budgetsStream(String uid) {
    return _budgetCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) =>
            qs.docs.map((d) => Budget.fromMap(d.id, d.data())).toList());
  }

  Future<String> addBudget(String uid, Budget b) async {
    final ref = await _budgetCol(uid).add(b.toMap());
    return ref.id;
  }

  Future<void> updateBudget(String uid, Budget b) async {
    await _budgetCol(uid).doc(b.id).set(b.toMap());
  }

  Future<void> deleteBudget(String uid, String id) async {
    await _budgetCol(uid).doc(id).delete();
  }

  // ---------------- INSUMOS ----------------

  Stream<List<Ingredient>> ingredientsStream(String uid) {
    return _ingredientCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) =>
            qs.docs.map((d) => Ingredient.fromMap(d.id, d.data())).toList());
  }

  Future<String> addIngredient(String uid, Ingredient ing) async {
    final batch = _db.batch();
    final docRef = _ingredientCol(uid).doc();
    batch.set(docRef, ing.toMap());
    final log = PriceAuditLog(
      action: 'ingredient.create',
      entityType: 'ingredient',
      entityId: docRef.id,
      summary: 'Insumo ${ing.name} criado',
      newPrice: ing.purchasePrice,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
    return docRef.id;
  }

  Future<void> updateIngredient(String uid, Ingredient ing) async {
    final batch = _db.batch();
    final docRef = _ingredientDoc(uid, ing.id);
    final data = Map<String, dynamic>.from(ing.toMap());
    data.remove('offers');
    data.remove('activeOfferId');
    batch.set(docRef, data, SetOptions(merge: true));
    final log = PriceAuditLog(
      action: 'ingredient.update',
      entityType: 'ingredient',
      entityId: ing.id,
      summary: 'Insumo ${ing.name} atualizado',
      newPrice: ing.purchasePrice,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> deleteIngredient(String uid, String id) async {
    final batch = _db.batch();
    final docRef = _ingredientDoc(uid, id);
    batch.delete(docRef);
    final log = PriceAuditLog(
      action: 'ingredient.delete',
      entityType: 'ingredient',
      entityId: id,
      summary: 'Insumo removido',
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<String> upsertOffer(
      String uid, String ingredientId, IngredientOffer offer) async {
    if (offer.packagePrice <= 0 || offer.packageQuantity <= 0) {
      throw StateError(
          'O preço e a quantidade da embalagem devem ser maiores que zero (RN01).');
    }

    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    final now = DateTime.now();
    final List<IngredientOffer> current;
    String? currentActiveId;
    if (snap.exists) {
      final data = snap.data()!;
      final rawOffers = data['offers'];
      current = rawOffers is List
          ? rawOffers
              .map((e) => IngredientOffer.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : [];
      currentActiveId = data['activeOfferId'] as String?;
    } else {
      current = [];
      currentActiveId = null;
    }

    final normalizedSupplier = offer.supplier.trim().toLowerCase();
    final existingIndex = current.indexWhere(
        (o) => o.supplier.trim().toLowerCase() == normalizedSupplier);

    final batch = _db.batch();
    final String offerId;
    final PriceAuditLog log;

    if (existingIndex >= 0) {
      final existing = current[existingIndex];
      final updated = IngredientOffer(
        id: existing.id,
        supplier: offer.supplier,
        packagePrice: offer.packagePrice,
        packageQuantity: offer.packageQuantity,
        isActive: offer.isActive,
        source: offer.source,
        notes: offer.notes,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
      current[existingIndex] = updated;
      offerId = existing.id;
      log = PriceAuditLog(
        action: 'offer.update',
        entityType: 'offer',
        entityId: offerId,
        summary: 'Oferta de ${updated.supplier} atualizada',
        supplier: updated.supplier,
        previousPrice: existing.packagePrice,
        newPrice: updated.packagePrice,
        pricePerUnit: updated.pricePerUnit,
        source: updated.source,
      );
    } else {
      if (current.length >= 15) {
        throw StateError('Limite de 15 ofertas por insumo atingido.');
      }
      final isFirst = current.isEmpty;
      offerId = offer.id.isNotEmpty ? offer.id : _ingredientCol(uid).doc().id;
      final created = IngredientOffer(
        id: offerId,
        supplier: offer.supplier,
        packagePrice: offer.packagePrice,
        packageQuantity: offer.packageQuantity,
        isActive: isFirst || offer.isActive,
        source: offer.source,
        notes: offer.notes,
        createdAt: now,
        updatedAt: now,
      );
      current.add(created);
      if (isFirst) {
        currentActiveId = offerId;
      }
      log = PriceAuditLog(
        action: 'offer.create',
        entityType: 'offer',
        entityId: offerId,
        summary: 'Oferta de ${created.supplier} criada',
        supplier: created.supplier,
        newPrice: created.packagePrice,
        pricePerUnit: created.pricePerUnit,
        source: created.source,
      );
    }

    batch.set(docRef, {
      'offers': current.map((o) => o.toMap()).toList(),
      'activeOfferId': currentActiveId,
    }, SetOptions(merge: true));
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(now.add(const Duration(days: 180))));
    await batch.commit();
    return offerId;
  }

  Future<void> setActiveOffer(
      String uid, String ingredientId, String offerId) async {
    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final rawOffers = data['offers'];
    if (rawOffers is! List) return;
    final offers = rawOffers
        .map((e) =>
            IngredientOffer.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (offers.isEmpty && offerId == 'legacy') return;
    final chosen = offers.firstWhere(
      (o) => o.id == offerId,
      orElse: () => offers.first,
    );
    final updated = offers
        .map((o) => o.copyWith(isActive: o.id == chosen.id))
        .toList();
    final summary =
        'Oferta de ${chosen.supplier} definida como ativa — ${chosen.pricePerUnit.toStringAsFixed(2)}/un';

    final batch = _db.batch();
    batch.set(docRef, {
      'offers': updated.map((o) => o.toMap()).toList(),
      'activeOfferId': chosen.id,
    }, SetOptions(merge: true));
    final log = PriceAuditLog(
      action: 'offer.setActive',
      entityType: 'offer',
      entityId: chosen.id,
      summary: summary,
      supplier: chosen.supplier,
      newPrice: chosen.packagePrice,
      pricePerUnit: chosen.pricePerUnit,
      source: chosen.source,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> toggleOfferActive(String uid, String ingredientId,
      String offerId, bool isActive) async {
    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final rawOffers = data['offers'];
    if (rawOffers is! List) return;
    final offers = rawOffers
        .map((e) =>
            IngredientOffer.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final index = offers.indexWhere((o) => o.id == offerId);
    if (index < 0) return;
    final target = offers[index];
    offers[index] = target.copyWith(isActive: isActive);
    String? newActiveId = data['activeOfferId'] as String?;
    String summary =
        'Oferta de ${target.supplier} ${isActive ? 'ativada' : 'desativada'}';
    if (!isActive && newActiveId == offerId) {
      newActiveId = null;
      summary =
          'Oferta de ${target.supplier} desativada; ticket volta ao preço base';
    }

    final batch = _db.batch();
    batch.set(docRef, {
      'offers': offers.map((o) => o.toMap()).toList(),
      'activeOfferId': newActiveId,
    }, SetOptions(merge: true));
    final log = PriceAuditLog(
      action: 'offer.toggleActive',
      entityType: 'offer',
      entityId: offerId,
      summary: summary,
      supplier: target.supplier,
      previousPrice: target.packagePrice,
      newPrice: isActive ? target.packagePrice : null,
      pricePerUnit: target.pricePerUnit,
      source: target.source,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> deleteOffer(
      String uid, String ingredientId, String offerId) async {
    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final rawOffers = data['offers'];
    if (rawOffers is! List) return;
    final offers = rawOffers
        .map((e) =>
            IngredientOffer.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final index = offers.indexWhere((o) => o.id == offerId);
    if (index < 0) return;
    final target = offers[index];
    offers.removeAt(index);
    String? newActiveId = data['activeOfferId'] as String?;
    if (newActiveId == offerId) newActiveId = null;

    final batch = _db.batch();
    batch.set(docRef, {
      'offers': offers.map((o) => o.toMap()).toList(),
      'activeOfferId': newActiveId,
    }, SetOptions(merge: true));
    final log = PriceAuditLog(
      action: 'offer.delete',
      entityType: 'offer',
      entityId: offerId,
      summary: 'Oferta de ${target.supplier} removida',
      supplier: target.supplier,
      previousPrice: target.packagePrice,
      pricePerUnit: target.pricePerUnit,
      source: target.source,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Stream<List<PriceAuditLog>> priceAuditLogsStream(String uid,
      {int limit = 100}) {
    return _auditLogCol(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => PriceAuditLog.fromMap(d.data()))
            .toList());
  }

  // ---------------- PRODUTOS / FICHA TECNICA ----------------

  Stream<List<Product>> productsStream(String uid) {
    return _productCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) =>
            qs.docs.map((d) => Product.fromMap(d.id, d.data())).toList());
  }

  Future<String> addProduct(String uid, Product p) async {
    final ref = await _productCol(uid).add(p.toMap());
    return ref.id;
  }

  Future<void> updateProduct(String uid, Product p) async {
    await _productCol(uid).doc(p.id).set(p.toMap());
  }

  Future<void> deleteProduct(String uid, String id) async {
    await _productCol(uid).doc(id).delete();
  }
}
