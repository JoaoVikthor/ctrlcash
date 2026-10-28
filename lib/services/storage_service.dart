import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  static const int _cancelledCode = -13040;
  static const Duration _retryDelay = Duration(milliseconds: 600);

  final FirebaseStorage _storage;

  Future<String?> uploadBytes({
    required String uid,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Falha no upload: Arquivo de imagem vazio.');
    }
    final ref = _storage.ref().child('users/$uid/$path');
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;
    try {
      return await _putAndGetUrl(ref, bytes, metadata);
    } catch (error) {
      if (!_isCancelled(error)) {
        throw Exception('Falha no upload: $error');
      }
      await Future<void>.delayed(_retryDelay);
      try {
        return await _putAndGetUrl(ref, bytes, metadata);
      } catch (retryError) {
        throw Exception(
          'Falha no upload após nova tentativa (o sistema cancelou o envio). '
          'Detalhe: $retryError',
        );
      }
    }
  }

  Future<String?> uploadFile({
    required String uid,
    required String path,
    required dynamic file,
  }) async {
    try {
      final bytes = await file.readAsBytes() as Uint8List;
      return await uploadBytes(uid: uid, path: path, bytes: bytes);
    } catch (e) {
      throw Exception('Falha no upload: $e');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Falha ao excluir arquivo: $e');
    }
  }

  Future<String> _putAndGetUrl(
    Reference ref,
    Uint8List bytes,
    SettableMetadata? metadata,
  ) async {
    final task = ref.putData(bytes, metadata);
    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }

  bool _isCancelled(Object error) {
    if (error is! FirebaseException) return false;
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code == '$_cancelledCode' ||
        code.contains('cancel') ||
        message.contains('cancel') ||
        message.contains('$_cancelledCode');
  }
}
