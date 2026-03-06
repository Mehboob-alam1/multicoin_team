import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class ReferralService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  String? _myCode;
  int _friends = 0;
  List<String> _claimed = [];

  String? get myCode => _myCode;
  int get friends => _friends;
  List<String> get claimedRewards => List.unmodifiable(_claimed);

  Future<void> load(String uid) async {
    await LocalFeatureStore.init();
    final rawClaimed = LocalFeatureStore.get('referral_claimed', const <String>[]);
    if (rawClaimed is List) _claimed = rawClaimed.map((e) => e.toString()).toList();
    final doc = await _firestore.collection('referrals').doc(uid).get();
    if (!doc.exists) {
      _myCode = uid.substring(0, 6).toUpperCase();
      _friends = 0;
      await _firestore.collection('referrals').doc(uid).set({
        'code': _myCode,
        'friends': 0,
      });
    } else {
      final d = doc.data() ?? {};
      _myCode = d['code']?.toString();
      _friends = (d['friends'] as num?)?.toInt() ?? 0;
    }
    notifyListeners();
  }

  Future<void> applyReferral(String myUid, String code) async {
    final q = await _firestore.collection('referrals').where('code', isEqualTo: code).limit(1).get();
    if (q.docs.isEmpty) return;
    final refDoc = q.docs.first;
    if (refDoc.id == myUid) return;
    final cur = (refDoc.data()['friends'] as num?)?.toInt() ?? 0;
    await _firestore.collection('referrals').doc(refDoc.id).update({'friends': cur + 1});
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
    await LocalFeatureStore.set('referral_claimed', _claimed);
    notifyListeners();
  }
}

