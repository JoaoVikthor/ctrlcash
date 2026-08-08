import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/transaction.dart' as tx;
import '../models/budget.dart';
import '../models/ingredient.dart';
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
    final ref = await _ingredientCol(uid).add(ing.toMap());
    return ref.id;
  }

  Future<void> updateIngredient(String uid, Ingredient ing) async {
    await _ingredientCol(uid).doc(ing.id).set(ing.toMap());
  }

  Future<void> deleteIngredient(String uid, String id) async {
    await _ingredientCol(uid).doc(id).delete();
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