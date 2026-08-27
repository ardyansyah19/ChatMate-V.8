import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child('profile_photos/$uid.$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadChatImage(String chatId, File file) async {
    final ext = file.path.split('.').last;
    final id = _uuid.v4();
    final ref = _storage.ref().child('chat_media/$chatId/images/$id.$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadChatFile(String chatId, File file, String fileName) async {
    final id = _uuid.v4();
    final ref = _storage.ref().child('chat_media/$chatId/files/${id}_$fileName');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }
}
