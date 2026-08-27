import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registers a new user with email, password, and nickname.
  /// Creates the auth account AND a matching user document in Firestore
  /// (collection: users) so the nickname/profile info is queryable and
  /// visible to other users for chatting.
  Future<ChatUser> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(nickname.trim());

    final chatUser = ChatUser(
      uid: uid,
      email: email.trim(),
      nickname: nickname.trim(),
      photoUrl: '',
    );

    await _db.collection('users').doc(uid).set(chatUser.toMap());

    return chatUser;
  }

  /// Logs in using only email and password, as requested.
  Future<ChatUser> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'user-data-missing',
        message: 'Data profil pengguna tidak ditemukan di database.',
      );
    }
    await _setOnlineStatus(cred.user!.uid, true);
    return ChatUser.fromMap(doc.data()!, cred.user!.uid);
  }

  Future<void> _setOnlineStatus(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _setOnlineStatus(uid, false);
    }
    await _auth.signOut();
  }

  Future<ChatUser?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return ChatUser.fromMap(doc.data()!, uid);
  }

  Stream<ChatUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatUser.fromMap(doc.data()!, uid);
    });
  }

  /// Human-friendly error messages in Indonesian for common auth failures.
  String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan login.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'weak-password':
          return 'Password terlalu lemah (minimal 6 karakter).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau password salah.';
        case 'user-data-missing':
          return e.message ?? 'Data pengguna tidak ditemukan.';
        default:
          return e.message ?? 'Terjadi kesalahan. Coba lagi.';
      }
    }
    return e.toString();
  }
}
