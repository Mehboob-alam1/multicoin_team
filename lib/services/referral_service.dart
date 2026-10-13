import 'dart:math';

import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';
import 'supabase_bootstrap.dart';

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

/// Referral codes live locally first. Signed-in users sync to Supabase at most every 24h.
class ReferralService extends ChangeNotifier {
  ReferralService();

  static const inviterBonusBtc = 0.00005;
  static const welcomeBonusBtc = 0.00002;

  static const _cacheKeyCode = 'referral_my_code';
  static const _cacheKeyFriends = 'referral_friends';
  static const _claimedKey = 'referral_claimed';
  static const _queuedCodeKey = 'referral_queued_join_code';
  static const _guestCodeKey = 'referral_guest_code';
  static const _lastCloudKey = 'referral_last_cloud_ms';
  static const _indexedKey = 'referral_code_indexed';
  static const _invitesCacheKey = 'referral_invites_cache';
  static const _bonusCheckKey = 'referral_bonus_check_ms';
  static const _cloudMaxAge = Duration(hours: 24);
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String? _uid;
  String? _myCode;
  String? _referredBy;
  int _friends = 0;
  int _pendingJoinBonuses = 0; // set from cloud; consumed via RPC
  List<String> _claimed = [];
  List<ReferredUser> _referredUsers = [];
  bool _loadInFlight = false;

  String? get myCode => _myCode;
  String? get referredBy => _referredBy;
  bool get hasUsedReferralCode => _referredBy != null && _referredBy!.isNotEmpty;
  int get friends => _friends;
  int get pendingJoinBonuses => _pendingJoinBonuses;
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
    _restoreInvitesCache();
    if ((_myCode == null || _myCode!.isEmpty) && signedIn) {
      final fromUid = codeCandidatesFromUid(uid);
      if (fromUid.isNotEmpty) _myCode = fromUid.first;
    }
    notifyListeners();

    if (!signedIn) {
      if (_myCode == null || _myCode!.isEmpty) {
        _myCode = LocalFeatureStore.get(_guestCodeKey)?.toString() ?? _randomSix();
      }
      await LocalFeatureStore.set(_cacheKeyCode, _myCode);
      await LocalFeatureStore.set(_guestCodeKey, _myCode);
      _loadInFlight = false;
      notifyListeners();
      return;
    }

    final lastCloud = LocalFeatureStore.get(_lastCloudKey);
    final cloudFresh = lastCloud is int &&
        DateTime.now().millisecondsSinceEpoch - lastCloud < _cloudMaxAge.inMilliseconds;
    if (_myCode != null && _myCode!.isNotEmpty && cloudFresh) {
      _loadInFlight = false;
      return;
    }

    final client = SupabaseBootstrap.client;
    try {
      if (client != null) {
        final row = await client.from('referrals').select().eq('uid', uid).maybeSingle();
        if (row == null) {
          final fromUid = codeCandidatesFromUid(uid);
          final code = (_myCode != null && _myCode!.isNotEmpty)
              ? _myCode!.toUpperCase()
              : (fromUid.isNotEmpty ? fromUid.first : _randomSix());
          _myCode = code;
          _friends = 0;
          _pendingJoinBonuses = 0;
          _referredBy = null;
          await client.from('referrals').upsert({
            'uid': uid,
            'code': code,
            'friends': 0,
            'pending_join_bonuses': 0,
            'is_guest': !signedIn,
            'display_name': displayName ?? 'Miner',
          });
          await _ensureCodeIndex(code, uid);
          await LocalFeatureStore.set(_indexedKey, true);
        } else {
          var code = row['code']?.toString();
          if (code == null || code.isEmpty) {
            code = await _assignCode(uid, signedIn: signedIn);
            await client.from('referrals').update({'code': code}).eq('uid', uid);
          }
          _myCode = code.toUpperCase();
          _friends = (row['friends'] as num?)?.toInt() ?? 0;
          _pendingJoinBonuses = (row['pending_join_bonuses'] as num?)?.toInt() ?? 0;
          _referredBy = row['referred_by']?.toString();
          if (LocalFeatureStore.get(_indexedKey) != true) {
            await _ensureCodeIndex(_myCode!, uid);
            await LocalFeatureStore.set(_indexedKey, true);
          }
        }
        if (!cloudFresh) await _refreshInvites(uid);
        await LocalFeatureStore.set(
          _lastCloudKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } else if (_myCode == null || _myCode!.isEmpty) {
        final fromUid = codeCandidatesFromUid(uid);
        _myCode = fromUid.isNotEmpty ? fromUid.first : _randomSix();
      }
    } catch (e) {
      debugPrint('ReferralService.load: $e');
      if (_myCode == null || _myCode!.isEmpty) {
        final fromUid = codeCandidatesFromUid(uid);
        _myCode = fromUid.isNotEmpty ? fromUid.first : _randomSix();
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

  void _restoreInvitesCache() {
    final raw = LocalFeatureStore.get(_invitesCacheKey);
    if (raw is! List) return;
    _referredUsers = raw.map((e) {
      if (e is! Map) {
        return const ReferredUser(uid: '', displayName: 'Miner');
      }
      final m = Map<String, dynamic>.from(e);
      final joinedMs = m['joinedAtMs'];
      return ReferredUser(
        uid: m['uid']?.toString() ?? '',
        displayName: (m['displayName'] as String?)?.trim().isNotEmpty == true
            ? m['displayName'] as String
            : 'Miner',
        joinedAt: joinedMs is num
            ? DateTime.fromMillisecondsSinceEpoch(joinedMs.toInt())
            : null,
      );
    }).where((e) => e.uid.isNotEmpty).toList();
    if (_referredUsers.length > _friends) {
      _friends = _referredUsers.length;
    }
  }

  Future<void> _refreshInvites(String uid) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      final rows = await client
          .from('referral_invites')
          .select()
          .eq('inviter_uid', uid)
          .order('joined_at', ascending: false)
          .limit(50);
      _referredUsers = (rows as List).map((e) {
        final d = Map<String, dynamic>.from(e as Map);
        final joined = d['joined_at']?.toString();
        return ReferredUser(
          uid: d['invitee_uid']?.toString() ?? '',
          displayName: (d['display_name'] as String?)?.trim().isNotEmpty == true
              ? d['display_name'] as String
              : 'Miner',
          joinedAt: joined != null ? DateTime.tryParse(joined) : null,
        );
      }).where((e) => e.uid.isNotEmpty).toList();
      if (_referredUsers.length > _friends) {
        _friends = _referredUsers.length;
      }
      await LocalFeatureStore.set(
        _invitesCacheKey,
        _referredUsers
            .map((e) => {
                  'uid': e.uid,
                  'displayName': e.displayName,
                  'joinedAtMs': e.joinedAt?.millisecondsSinceEpoch,
                })
            .toList(),
      );
    } catch (e) {
      debugPrint('ReferralService._refreshInvites: $e');
    }
  }

  Future<int> consumePendingJoinBonuses() async {
    final uid = _uid;
    if (uid == null) return 0;
    final last = LocalFeatureStore.get(_bonusCheckKey);
    if (last is int &&
        DateTime.now().millisecondsSinceEpoch - last < _cloudMaxAge.inMilliseconds) {
      return 0;
    }
    await LocalFeatureStore.set(
      _bonusCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    final client = SupabaseBootstrap.client;
    if (client == null) return 0;
    try {
      final paid = await client.rpc('consume_referral_bonuses');
      final n = paid is num ? paid.toInt() : int.tryParse('$paid') ?? 0;
      if (n > 0) _pendingJoinBonuses = 0;
      return n;
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
    if (clean == (_myCode ?? '').toUpperCase()) {
      return const ReferralApplyResult(ReferralApplyStatus.self, 'You cannot use your own code.');
    }
    final client = SupabaseBootstrap.client;
    if (client == null) {
      return const ReferralApplyResult(
        ReferralApplyStatus.error,
        'Cloud is not configured yet.',
      );
    }
    try {
      final raw = await client.rpc('apply_referral', params: {
        'p_code': clean,
        'p_display_name': (displayName == null || displayName.trim().isEmpty)
            ? 'Miner'
            : displayName.trim(),
      });
      final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final status = map['status']?.toString() ?? 'error';
      switch (status) {
        case 'invalid':
          return const ReferralApplyResult(ReferralApplyStatus.invalid, 'That code was not found.');
        case 'self':
          return const ReferralApplyResult(ReferralApplyStatus.self, 'You cannot use your own code.');
        case 'already_used':
          _referredBy = 'used';
          notifyListeners();
          return const ReferralApplyResult(
            ReferralApplyStatus.alreadyUsed,
            'You already used a referral code.',
          );
        case 'success':
          _referredBy = map['inviter_uid']?.toString() ?? 'ok';
          notifyListeners();
          return const ReferralApplyResult(
            ReferralApplyStatus.success,
            'Referral applied. Welcome bonus added!',
          );
        default:
          return const ReferralApplyResult(
            ReferralApplyStatus.error,
            'Could not apply that code. Try again.',
          );
      }
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
    } else if (existing != null && existing.isNotEmpty) {
      candidates.add(existing.toUpperCase());
    }
    if (existing != null && existing.isNotEmpty && signedIn) {
      candidates.add(existing.toUpperCase());
    }
    for (final c in candidates) {
      if (c.length < 4) continue;
      if (await _tryIndexCode(c, uid)) return c;
    }
    for (var i = 0; i < 16; i++) {
      final code = _randomSix();
      if (await _tryIndexCode(code, uid)) return code;
    }
    final fallback = (uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() + _alphabet)
        .padRight(6, 'X')
        .substring(0, 6);
    await _tryIndexCode(fallback, uid);
    return fallback;
  }

  Future<void> _ensureCodeIndex(String code, String uid) async {
    await _tryIndexCode(code, uid);
  }

  Future<bool> _tryIndexCode(String code, String uid) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return true;
    try {
      final existing =
          await client.from('referral_codes').select('uid').eq('code', code).maybeSingle();
      if (existing != null) {
        return existing['uid']?.toString() == uid;
      }
      await client.from('referral_codes').insert({'code': code, 'uid': uid});
      return true;
    } catch (_) {
      return false;
    }
  }
}
