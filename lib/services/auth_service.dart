import 'package:firebase_auth/firebase_auth.dart';

/// Servico de autenticacao do CashCtrl.
///
/// Centraliza o acesso ao FirebaseAuth e expoe o stream de estado de
/// autenticacao para ser consumido via [StreamProvider] no main.dart.
/// Mantem o isolamento por UID exigido pela RN02 nas regras do Firestore.
class AuthService {
  AuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Stream do estado de autenticacao: emite o [User] atual ou null.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario atualmente autenticado (ou null).
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}