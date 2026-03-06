import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  Future<User?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(cred);
      return userCred.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Collega l'account Google a un utente anonimo esistente (mantiene i dati)
  Future<User?> linkWithGoogle() async {
    final user = currentUser;
    if (user == null || !user.isAnonymous) return user;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return user;
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final linked = await user.linkWithCredential(cred);
      return linked.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
