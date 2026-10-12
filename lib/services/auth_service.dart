import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'firestore_service.dart';

/// Servico de autenticacao do CashCtrl.
///
/// Centraliza o acesso ao FirebaseAuth e expoe o stream de estado de
/// autenticacao para ser consumido via [StreamProvider] no main.dart.
/// Mantem o isolamento por UID exigido pela RN02 nas regras do Firestore.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirestoreService? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId:
                  kIsWeb ? dotenv.env['GOOGLE_SIGN_IN_CLIENT_ID'] : null,
            ),
        _firestore = firestore ?? FirestoreService();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestore;

  /// Stream do estado de autenticacao: emite o [User] atual ou null.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario atualmente autenticado (ou null).
  User? get currentUser => _auth.currentUser;

  /// Login com e-mail e senha.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  /// Registro com e-mail e senha + persistencia do perfil no Firestore
  /// (colecao users/{uid}). Recebe o modelo [AppUser] montado pela tela
  /// de cadastro (passo 1 + passo 2) e o salva apos criar o Auth user.
  Future<User> registerWithEmail({
    required AppUser userProfile,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: userProfile.email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException('Não foi possível obter o UID do usuário.');
      }
      final withUid = AppUser(
        uid: uid,
        nome: userProfile.nome,
        email: userProfile.email,
        empresa: userProfile.empresa,
        cnpj: userProfile.cnpj,
        segmento: userProfile.segmento,
        telefone: userProfile.telefone,
        endereco: userProfile.endereco,
        photoUrl: userProfile.photoUrl,
      );
      await _firestore.saveUser(withUid);
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException('Erro ao salvar perfil: ${e.message ?? e.toString()}');
    }
  }

  /// Login com Google (fluxo nativo do google_sign_in + Firebase cred).
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // cancelado pelo usuario
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  /// Envia e-mail de recuperacao de senha para o [email] cadastrado.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  /// Altera a senha do usuario logado apos reautenticar com a senha atual.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _reauthenticate(currentPassword);
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('Nenhum usuário conectado.');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_changePasswordError(e));
    }
  }

  /// Exclui a conta do usuario logado apos reautenticar com a senha.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Nenhum usuário conectado.');
    }
    try {
      await _reauthenticate(password);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_deleteAccountError(e));
    }
  }

  /// Reautentica o usuario atual com e-mail/senha (exigido pelo Firebase
  /// antes de operacoes sensiveis como alterar ou excluir a conta).
  Future<void> _reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('Nenhum usuário conectado.');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Encerra a sessao atual (Firebase + Google).
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Mapeia codigos de erro do FirebaseAuth para mensagens amigaveis em
  /// portugues, reutilizaveis pelas telas de Login/Cadastro.
  static String friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      default:
        return e.message ?? 'Ocorreu um erro inesperado.';
    }
  }

  /// Mapeia erros do FirebaseAuth do fluxo de alteracao de senha.
  static String _changePasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Senha atual incorreta.';
      case 'weak-password':
        return 'A nova senha deve ter ao menos 6 caracteres.';
      case 'requires-recent-login':
        return 'Por segurança, faça login novamente antes de alterar a senha.';
      default:
        return friendlyAuthError(e);
    }
  }

  /// Mapeia erros do FirebaseAuth do fluxo de exclusao de conta.
  static String _deleteAccountError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'requires-recent-login':
        return 'Por segurança, faça login novamente antes de excluir a conta.';
      default:
        return friendlyAuthError(e);
    }
  }
}

/// Excecao de autenticacao com mensagem amigavel em portugues.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}