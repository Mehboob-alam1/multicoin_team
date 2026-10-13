import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  AuthService() {
    _auth.userChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );
  String? _googlePhotoUrl;

  static const _guestAdjectives = [
    'Sol', 'Hash', 'Neon', 'Pixel', 'Quantum', 'Nova', 'Cyber', 'Lucky',
    'Rapid', 'Silent', 'Turbo', 'Amber',
  ];
  static const _guestNouns = [
    'Fox', 'Wolf', 'Miner', 'Rig', 'Node', 'Forge', 'Spark', 'Drift',
    'Hawk', 'Lynx', 'Core', 'Wave',
  ];

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  String displayNameOf(User? user) {
    if (user == null) return 'Miner';
    final n = user.displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (user.isAnonymous) return 'Guest Miner';
    final email = user.email?.trim();
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Miner';
  }

  String? photoUrlOf(User? user) {
    if (user == null || user.isAnonymous) return null;
    final url = user.photoURL?.trim();
    if (url != null && url.isNotEmpty) return url;
    final cached = _googlePhotoUrl?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  Future<User?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;
      if (user != null && (user.displayName == null || user.displayName!.trim().isEmpty)) {
        await user.updateDisplayName(_randomGuestName());
        await user.reload();
        notifyListeners();
      }
      return _auth.currentUser ?? user;
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
      final user = userCred.user;
      if (user != null) {
        await _applyGoogleProfile(user, googleUser);
      }
      return _auth.currentUser ?? user;
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
      final linkedUser = linked.user;
      if (linkedUser != null) {
        await _applyGoogleProfile(linkedUser, googleUser);
      }
      return _auth.currentUser ?? linkedUser;
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

  Future<void> _applyGoogleProfile(User user, GoogleSignInAccount googleUser) async {
    final name = googleUser.displayName?.trim();
    final photo = googleUser.photoUrl?.trim();
    if (photo != null && photo.isNotEmpty) _googlePhotoUrl = photo;
    if (name != null && name.isNotEmpty && user.displayName != name) {
      await user.updateDisplayName(name);
    }
    if (photo != null && photo.isNotEmpty && user.photoURL != photo) {
      await user.updatePhotoURL(photo);
    }
    await user.reload();
    notifyListeners();
  }

  String _randomGuestName() {
    final rng = Random();
    final adj = _guestAdjectives[rng.nextInt(_guestAdjectives.length)];
    final noun = _guestNouns[rng.nextInt(_guestNouns.length)];
    final n = rng.nextInt(90) + 10;
    return '$adj$noun$n';
  }
}
