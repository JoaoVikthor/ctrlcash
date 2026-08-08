import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Servico de upload de imagens para o Firebase Storage.
///
/// Cada upload fica em um "namespace" por UID (RN02) e retorna a URL
/// publica para persistir no Firestore. Usado para fotos de perfil e
/// fotos de produto.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String?> uploadFile({
    required String uid,
    required String path,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child('users/$uid/$path');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Storage upload error: $e');
      return null;
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}