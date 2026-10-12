import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class ReferredUser {
  final String uid;
  final String displayName;
  final DateTime? joinedAt;

  const ReferredUser({
    required this.uid,
    required this.displayName,
    this.joinedAt,
  });
}

enum ReferralApplyStatus { success, invalid, self, alreadyUsed, error }

class ReferralApplyResult {
  final ReferralApplyStatus status;
  final String message;
  bool get ok => status == ReferralApplyStatus.success;

  const ReferralApplyResult(this.status, this.message);
}

/// Unique per-user referral codes, join bonuses, and referred-user list (Firestore).
class ReferralService extends ChangeNotifier {
  ReferralService();

  final _firestore = FirebaseFirestore.instance;

  static const inviterBonusBtc = 0.00005;
  static const welcomeBonusBtc = 0.00002;

  static const _cacheKeyCode = 'referral_my_code';
  static const _cacheKeyFriends = 'referral_friends';
  static const _claimedKey = 'referral_claimed';
  static const _queuedCodeKey = 'referral_queued_join_code';
  static const _guestCodeKey = 'referral_guest_code';
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String? _uid;
  String? _myCode;
  String? _referredBy;
  int _friends = 0;
  int _pendingJoinBonuses = 0;
  List<String> _claimed = [];
  List<ReferredUser> _referredUsers = [];
  bool _loadInFlight = false;

  String? get myCode => _myCode;
  String? get referredBy => _referredBy;
  bool get hasUsedReferralCode => _referredBy != null && _referredBy!.isNotEmpty;
  int get friends => _friends;
  List<String> get claimedRewards => List.unmodifiable(_claimed);
  List<ReferredUser> get referredUsers => List.unmodifiable(_referredUsers);

  Future<void> queueJoinCode(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return;
    await LocalFeatureStore.init();
    await LocalFeatureStore.set(_queuedCodeKey, c);
  }

  Future<String?> takeQueuedJoinCode() async {
    await LocalFeatureStore.init();
    final raw = LocalFeatureStore.get(_queuedCodeKey)?.toString();
    if (raw == null || raw.isEmpty) return null;
    await LocalFeatureStore.set(_queuedCodeKey, '');
    return raw.trim().toUpperCase();
  }

  /// Shows a code in Profile even before Firebase Auth exists; persists it locally
  /// and writes to Firestore when possible.
  Future<void> ensureLoaded({
    required String? uid,
    String? displayName,
    required bool signedIn,
  }) async {
    if (uid == null || uid.isEmpty) {
      await _loadUnsignedGuest(displayName: displayName);
      return;
    }
    if (_uid == uid && _myCode != null && _myCode!.isNotEmpty && !_loadInFlight) {
      return;
    }
    await load(uid, displayName: displayName, signedIn: signedIn);
  }

  Future<void> _loadUnsignedGuest({String? displayName}) async {
    await LocalFeatureStore.init();
    var code = LocalFeatureStore.get(_guestCodeKey)?.toString();
    if (code == null || code.isEmpty) {
      code = _randomSix();
      await LocalFeatureStore.set(_guestCodeKey, code);
    }
    code = code.toUpperCase();
    _uid = null;
    _myCode = code;
    await LocalFeatureStore.set(_cacheKeyCode, code);
    notifyListeners();
    try {
      final docId = 'guest_$code';
      await _firestore.collection('referrals').doc(docId).set({
        'code': code,
        'uid': docId,
        'friends': 0,
        'isGuest': true,
        'displayName': displayName ?? 'Guest Miner',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _ensureCodeIndex(code, docId);
    } catch (e) {
      debugPrint('ReferralService._loadUnsignedGuest: $e');
    }
  }

  Future<void> load(String uid, {String? displayName, bool signedIn = true}) async {
    if (_loadInFlight && _uid == uid) return;
    _loadInFlight = true;
    _uid = uid;
    await LocalFeatureStore.init();
    final rawClaimed = LocalFeatureStore.get(_claimedKey, const <String>[]);
    if (rawClaimed is List) {
      _claimed = rawClaimed.map((e) => e.toString()).toList();
    }
    _myCode = LocalFeatureStore.get(_cacheKeyCode)?.toString();
    final cachedFriends = LocalFeatureStore.get(_cacheKeyFriends);
    if (cachedFriends is num) _friends = cachedFriends.toInt();
    notifyListeners();

    try {
      final docRef = _firestore.collection('referrals').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final code = await _assignCode(uid, signedIn: signedIn);
        _myCode = code;
        _friends = 0;
        _pendingJoinBonuses = 0;
        _referredBy = null;
        await docRef.set({
          'code': code,
          'uid': uid,
          'friends': 0,
          'pendingJoinBonuses': 0,
          'isGuest': !signedIn,
          'displayName': displayName ?? 'Miner',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final d = doc.data() ?? {};
        var code = d['code']?.toString();
        final previous = (code != null && code.isNotEmpty) ? code.toUpperCase() : null;
        final assigned = await _assignCode(uid, signedIn: signedIn, existing: previous);
        if (previous != null && previous != assigned) {
          await _ensureCodeIndex(previous, uid);
        }
        code = assigned;
        await docRef.set({
          'code': code,
          'uid': uid,
          'isGuest': !signedIn,
          if (previous != null && previous != code) 'previousCode': previous,
        }, SetOptions(merge: true));
        _myCode = code;
        _friends = (d['friends'] as num?)?.toInt() ?? 0;
        _pendingJoinBonuses = (d['pendingJoinBonuses'] as num?)?.toInt() ?? 0;
        _referredBy = d['referredBy']?.toString();
        if (displayName != null && displayName.isNotEmpty) {
          await docRef.set({'displayName': displayName}, SetOptions(merge: true));
        }
      }

      QuerySnapshot<Map<String, dynamic>> invites;
      try {
        invites = await docRef
            .collection('invites')
            .orderBy('joinedAt', descending: true)
            .limit(50)
            .get();
      } catch (_) {
        invites = await docRef.collection('invites').limit(50).get();
      }
      _referredUsers = invites.docs.map((e) {
        final d = e.data();
        final ts = d['joinedAt'];
        return ReferredUser(
          uid: e.id,
          displayName: (d['displayName'] as String?)?.trim().isNotEmpty == true
              ? d['displayName'] as String
              : 'Miner',
          joinedAt: ts is Timestamp ? ts.toDate() : null,
        );
      }).toList();
      if (_referredUsers.length > _friends) {
        _friends = _referredUsers.length;
      }
    } catch (e) {
      debugPrint('ReferralService.load: $e');
      if (_myCode == null || _myCode!.isEmpty) {
        final fromUid = codeCandidatesFromUid(uid);
        _myCode = signedIn
            ? (fromUid.isNotEmpty ? fromUid.first : _randomSix())
            : (LocalFeatureStore.get(_guestCodeKey)?.toString() ?? _randomSix());
      }
    } finally {
      _loadInFlight = false;
    }

    await LocalFeatureStore.set(_cacheKeyCode, _myCode);
    await LocalFeatureStore.set(_cacheKeyFriends, _friends);
    if (!signedIn && _myCode != null) {
      await LocalFeatureStore.set(_guestCodeKey, _myCode);
    }
    notifyListeners();
  }

  /// Pay out unclaimed per-join bonuses. Caller should grant BTC × [inviterBonusBtc].
  Future<int> consumePendingJoinBonuses() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final ref = _firestore.collection('referrals').doc(uid);
      final paid = await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final n = (snap.data()?['pendingJoinBonuses'] as num?)?.toInt() ?? 0;
        if (n <= 0) return 0;
        tx.set(ref, {'pendingJoinBonuses': 0}, SetOptions(merge: true));
        return n;
      });
      _pendingJoinBonuses = 0;
      return paid;
    } catch (e) {
      debugPrint('ReferralService.consumePendingJoinBonuses: $e');
      return 0;
    }
  }

  Future<ReferralApplyResult> applyReferral(
    String myUid,
    String code, {
    String? displayName,
  }) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) {
      return const ReferralApplyResult(ReferralApplyStatus.invalid, 'Enter a referral code.');
    }
    try {
      final codeSnap = await _firestore.collection('referralCodes').doc(clean).get();
      String? inviterUid = codeSnap.data()?['uid']?.toString();
      if (inviterUid == null || inviterUid.isEmpty) {
        final q = await _firestore
            .collection('referrals')
            .where('code', isEqualTo: clean)
            .limit(1)
            .get();
        if (q.docs.isEmpty) {
          return const ReferralApplyResult(ReferralApplyStatus.invalid, 'That code was not found.');
        }
        inviterUid = q.docs.first.id;
        await _ensureCodeIndex(clean, inviterUid);
      }
      if (inviterUid == myUid) {
        return const ReferralApplyResult(ReferralApplyStatus.self, 'You cannot use your own code.');
      }

      final inviteeRef = _firestore.collection('referrals').doc(myUid);
      final inviterRef = _firestore.collection('referrals').doc(inviterUid);
      final inviteRef = inviterRef.collection('invites').doc(myUid);
      final name = (displayName == null || displayName.trim().isEmpty) ? 'Miner' : displayName.trim();

      final status = await _firestore.runTransaction((tx) async {
        final me = await tx.get(inviteeRef);
        final already = me.data()?['referredBy']?.toString();
        if (already != null && already.isNotEmpty) {
          return ReferralApplyStatus.alreadyUsed;
        }
        final inviter = await tx.get(inviterRef);
        final friends = (inviter.data()?['friends'] as num?)?.toInt() ?? 0;
        final pending = (inviter.data()?['pendingJoinBonuses'] as num?)?.toInt() ?? 0;
        tx.set(
          inviteeRef,
          {
            'referredBy': inviterUid,
            'referredByCode': clean,
            'referredAt': FieldValue.serverTimestamp(),
            if (!me.exists) 'friends': 0,
          },
          SetOptions(merge: true),
        );
        if (inviter.exists) {
          tx.update(inviterRef, {
            'friends': friends + 1,
            'pendingJoinBonuses': pending + 1,
          });
        } else {
          tx.set(inviterRef, {
            'friends': 1,
            'pendingJoinBonuses': 1,
            'code': clean,
          }, SetOptions(merge: true));
        }
        tx.set(inviteRef, {
          'uid': myUid,
          'displayName': name,
          'joinedAt': FieldValue.serverTimestamp(),
          'codeUsed': clean,
        });
        return ReferralApplyStatus.success;
      });

      if (status == ReferralApplyStatus.alreadyUsed) {
        _referredBy = 'used';
        notifyListeners();
        return const ReferralApplyResult(
          ReferralApplyStatus.alreadyUsed,
          'You already used a referral code.',
        );
      }
      _referredBy = inviterUid;
      notifyListeners();
      return const ReferralApplyResult(
        ReferralApplyStatus.success,
        'Referral applied. Welcome bonus added!',
      );
    } catch (e) {
      debugPrint('ReferralService.applyReferral: $e');
      return const ReferralApplyResult(
        ReferralApplyStatus.error,
        'Could not apply that code. Try again.',
      );
    }
  }

  bool canClaimReward(String id) {
    if (_claimed.contains(id)) return false;
    switch (id) {
      case 'friends_1':
        return _friends >= 1;
      case 'friends_5':
        return _friends >= 5;
      case 'friends_10':
        return _friends >= 10;
      default:
        return false;
    }
  }

  Future<void> markClaimed(String id) async {
    if (_claimed.contains(id)) return;
    _claimed = [..._claimed, id];
    await LocalFeatureStore.set(_claimedKey, _claimed);
    notifyListeners();
  }

  /// Signed-in: last 6 digits of Firebase uid, else first 6 digits, else last/first 6 chars.
  /// Guest / not signed in: stable random 6-character code.
  static List<String> codeCandidatesFromUid(String uid) {
    final digits = uid.replaceAll(RegExp(r'[^0-9]'), '');
    final alnum = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final out = <String>[];
    void add(String value) {
      if (value.length == 6 && !out.contains(value)) out.add(value);
    }

    if (digits.length >= 6) {
      add(digits.substring(digits.length - 6));
      add(digits.substring(0, 6));
    }
    if (alnum.length >= 6) {
      add(alnum.substring(alnum.length - 6));
      add(alnum.substring(0, 6));
    }
    return out;
  }

  String _randomSix() {
    final rng = Random.secure();
    return List.generate(6, (_) => _alphabet[rng.nextInt(_alphabet.length)]).join();
  }

  Future<String> _assignCode(
    String uid, {
    required bool signedIn,
    String? existing,
  }) async {
    final candidates = <String>[];
    if (signedIn) {
      candidates.addAll(codeCandidatesFromUid(uid));
    } else {
      if (existing != null && existing.isNotEmpty) {
        candidates.add(existing.toUpperCase());
      }
      final cached = LocalFeatureStore.get(_guestCodeKey)?.toString();
      if (cached != null && cached.isNotEmpty) {
        candidates.add(cached.toUpperCase());
      }
    }
    if (existing != null && existing.isNotEmpty && signedIn) {
      // Prefer uid-based codes, but keep a working existing code if all uid slices are taken.
      candidates.add(existing.toUpperCase());
    }

    for (final c in candidates) {
      if (c.length < 4) continue;
      final claimed = await _tryIndexCode(c, uid);
      if (claimed) return c;
    }
    for (var i = 0; i < 16; i++) {
      final code = _randomSix();
      final claimed = await _tryIndexCode(code, uid);
      if (claimed) return code;
    }
    final fallback = (uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() + _alphabet)
        .padRight(6, 'X')
        .substring(0, 6);
    await _tryIndexCode(fallback, uid);
    return fallback;
  }

  Future<void> _ensureCodeIndex(String code, String uid) async {
    try {
      final ref = _firestore.collection('referralCodes').doc(code);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('ReferralService._ensureCodeIndex: $e');
    }
  }

  Future<bool> _tryIndexCode(String code, String uid) async {
    try {
      final ref = _firestore.collection('referralCodes').doc(code);
      return await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          return snap.data()?['uid'] == uid;
        }
        tx.set(ref, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
        return true;
      });
    } catch (_) {
      return false;
    }
  }
}
