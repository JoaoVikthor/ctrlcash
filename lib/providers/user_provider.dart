import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/firestore_service.dart';

/// Provider global de estado do usuario (ChangeNotifier).
///
/// Mantem o UID (do stream de autenticacao do Firebase) e o perfil completo
/// (nome, empresa, cnpj, segmento...) lido do Firestore.
class UserProvider extends ChangeNotifier {
  UserProvider({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  String? _uid;
  bool _isReady = false;
  AppUser? _user;
  bool _loadingProfile = false;
  String? _profileError;

  String? get uid => _uid;
  bool get isReady => _isReady;
  AppUser? get user => _user;
  bool get loadingProfile => _loadingProfile;
  String? get profileError => _profileError;

  void setUsuario(String? uid) {
    _uid = uid;
    _isReady = true;
    notifyListeners();
    if (uid != null) {
      loadProfile(uid);
    } else {
      _user = null;
    }
  }

  Future<void> loadProfile(String uid) async {
    _loadingProfile = true;
    _profileError = null;
    notifyListeners();
    try {
      _user = await _firestore.getUser(uid);
    } catch (e) {
      _profileError = e.toString();
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> saveUser(AppUser user) async {
    await _firestore.saveUser(user);
    _user = user;
    notifyListeners();
  }

  void limpar() {
    _uid = null;
    _isReady = false;
    _user = null;
    _profileError = null;
    notifyListeners();
  }

  Future<void> reloadProfile() async {
    if (_uid != null) await loadProfile(_uid!);
  }
}