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
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String? _uid;
  String? _myCode;
  String? _referredBy;
  int _friends = 0;
  int _pendingJoinBonuses = 0;
  List<String> _claimed = [];
  List<ReferredUser> _referredUsers = [];

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

  Future<void> load(String uid, {String? displayName}) async {
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
        final code = await _claimUniqueCode(uid);
        _myCode = code;
        _friends = 0;
        _pendingJoinBonuses = 0;
        _referredBy = null;
        await docRef.set({
          'code': code,
          'friends': 0,
          'pendingJoinBonuses': 0,
          'displayName': displayName ?? 'Miner',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final d = doc.data() ?? {};
        var code = d['code']?.toString();
        if (code == null || code.isEmpty) {
          code = await _claimUniqueCode(uid);
          await docRef.set({'code': code}, SetOptions(merge: true));
        } else {
          await _ensureCodeIndex(code, uid);
        }
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
    }

    await LocalFeatureStore.set(_cacheKeyCode, _myCode);
    await LocalFeatureStore.set(_cacheKeyFriends, _friends);
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

  Future<String> _claimUniqueCode(String uid) async {
    final rng = Random.secure();
    for (var i = 0; i < 16; i++) {
      final code = List.generate(8, (_) => _alphabet[rng.nextInt(_alphabet.length)]).join();
      final claimed = await _tryIndexCode(code, uid);
      if (claimed) return code;
    }
    final fallback = (uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() + _alphabet)
        .padRight(8, 'X')
        .substring(0, 8);
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
