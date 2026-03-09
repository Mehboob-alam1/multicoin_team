import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';

import '../constants/app_constants.dart';

import '../services/ad_pacing_service.dart';
import '../services/auth_service.dart';
import '../services/btc_price_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/game_state_service.dart';
import '../services/referral_service.dart';
import '../theme/app_theme.dart';
import '../services/withdrawal_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFF080B12);
  static const surface  = Color(0xFF0E1420);
  static const card     = Color(0xFF121826);
  static const cardBord = Color(0xFF1E2A3A);
  static const gold     = Color(0xFFF5A623);
  static const goldDark = Color(0xFFE08800);
  static const electric = Color(0xFF00D4FF);
  static const green    = Color(0xFF00E5A0);
  static const purple   = Color(0xFFB06EFF);
  static const pink     = Color(0xFFFF6B9D);
  static const red      = Color(0xFFFF4D6A);
  static const textHi   = Color(0xFFF0F4FF);
  static const textMid  = Color(0xFF8899BB);
  static const textLow  = Color(0xFF3D4F6B);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthService>();
    final game     = context.watch<GameStateService>();
    final energy   = context.watch<EnergyCoolingService>();
    final referral = context.watch<ReferralService>();
    final withdrawal = context.watch<WithdrawalService>();
    final pacing   = context.watch<AdPacingService>();
    final btcPrice = context.watch<BtcPriceService>();
    final user     = auth.currentUser;

    withdrawal.recheckUnlock(
      totalSessionsStarted: game.totalSessionsStarted,
      rewardedAdsWatched: pacing.rewardedAdsWatchedCount,
      btcBalance: game.btcBalance,
    );

    final displayName = user?.displayName ??
        (user?.isAnonymous == true ? 'Guest Miner' : 'Miner');
    final isGuest = user?.isAnonymous == true;

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // Ambient glows
            Positioned(
              top: -80,
              left: -60,
              child: _Blob(color: _D.purple.withValues(alpha: 0.06), size: 320),
            ),
            Positioned(
              bottom: 60,
              right: -80,
              child: _Blob(color: _D.gold.withValues(alpha: 0.05), size: 280),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── App bar ──────────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: _D.bg.withValues(alpha: 0.92),
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _D.textMid, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text(
                      'PROFILE',
                      style: TextStyle(
                        color: _D.textHi,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // ── Hero avatar ──────────────────────────────
                        _AvatarHero(
                          user:        user,
                          displayName: displayName,
                          isGuest:     isGuest,
                        ),
                        const SizedBox(height: 20),

                        // ── Guest link card ──────────────────────────
                        if (isGuest) ...[
                          _GuestLinkCard(auth: auth),
                          const SizedBox(height: 14),
                        ],

                        // ── Stats section ────────────────────────────
                        _SectionLabel(label: 'MINING STATS'),
                        const SizedBox(height: 10),
                        _StatsGrid(game: game),
                        const SizedBox(height: 16),

                        // ── Premium & session ────────────────────────
                        _SectionLabel(label: 'STATUS'),
                        const SizedBox(height: 10),
                        _StatusRow(game: game),
                        const SizedBox(height: 16),

                        // ── Energy card ──────────────────────────────
                        _SectionLabel(label: 'ENERGY & COOLING'),
                        const SizedBox(height: 10),
                        _EnergyCard(energy: energy),
                        const SizedBox(height: 16),

                        // ── Withdrawal card ─────────────────────────
                        _SectionLabel(label: 'WITHDRAWAL'),
                        const SizedBox(height: 10),
                        _WithdrawalCard(
                          game: game,
                          withdrawal: withdrawal,
                          pacing: pacing,
                          btcPrice: btcPrice,
                        ),
                        const SizedBox(height: 16),

                        // ── Referral card ────────────────────────────
                        _SectionLabel(label: 'INVITE FRIENDS & EARN'),
                        const SizedBox(height: 10),
                        _ReferralCard(referral: referral, game: game, auth: auth),
                        const SizedBox(height: 24),

                        // ── Legal & support ──────────────────────────
                        _SectionLabel(label: 'LEGAL & SUPPORT'),
                        const SizedBox(height: 10),
                        _LegalSupportSection(),
                        const SizedBox(height: 24),

                        // ── Sign out ─────────────────────────────────
                        _SignOutTile(auth: auth, isGuest: isGuest),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar hero ──────────────────────────────────────────────────────────────
class _AvatarHero extends StatelessWidget {
  final dynamic user;
  final String displayName;
  final bool isGuest;
  const _AvatarHero({
    required this.user,
    required this.displayName,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    const SizedBox(height: 8),
    Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Glow ring
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                _D.gold.withValues(alpha: 0.5),
                _D.purple.withValues(alpha: 0.3),
                _D.gold.withValues(alpha: 0.5),
              ]),
              boxShadow: [
                BoxShadow(
                  color: _D.gold.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _D.card,
              image: user?.photoURL != null
                  ? DecorationImage(
                image: NetworkImage(user!.photoURL!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: user?.photoURL == null
                ? const Icon(Icons.person_rounded, size: 48, color: _D.gold)
                : null,
          ),
          // Online dot
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _D.green,
              border: Border.all(color: _D.bg, width: 2.5),
              boxShadow: [
                BoxShadow(color: _D.green.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    Text(
      displayName,
      style: const TextStyle(
        color: _D.textHi,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    ),
    const SizedBox(height: 4),
    if (user?.email != null && (user!.email as String).isNotEmpty)
      Text(
        user!.email as String,
        style: const TextStyle(color: _D.textMid, fontSize: 13),
      )
    else
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _D.textLow.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'GUEST',
          style: TextStyle(
            color: _D.textMid,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
  ]);
}

// ─── Guest link card ──────────────────────────────────────────────────────────
class _GuestLinkCard extends StatelessWidget {
  final AuthService auth;
  const _GuestLinkCard({required this.auth});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _D.gold.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(color: _D.gold.withValues(alpha: 0.06), blurRadius: 16),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _D.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.link_rounded, color: _D.gold, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Guest account',
            style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        const Text('Link Google to sync your progress.',
            style: TextStyle(color: _D.textMid, fontSize: 12)),
      ])),
      const SizedBox(width: 10),
      _GoldBtn(
        label: 'Link',
        compact: true,
        onTap: () async {
          try {
            await auth.linkWithGoogle();
            if (context.mounted) _toast(context, '✓ Account linked with Google');
          } catch (e) {
            if (context.mounted) _toast(context, 'Error: $e');
          }
        },
      ),
    ]),
  );
}

// ─── Stats grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final GameStateService game;
  const _StatsGrid({required this.game});

  @override
  Widget build(BuildContext context) {
    final items = [
      _GridItem(Icons.factory_rounded,     _D.gold,     'Farm Tier',
          game.currentFarmTier.name),
      _GridItem(Icons.memory_rounded,      _D.electric, 'Hash Power',
          '${game.totalBtcPerMin.toStringAsFixed(6)} BTC/min'),
      _GridItem(Icons.savings_rounded,     _D.green,    'Lifetime Mined',
          '${game.lifetimeMinedBtc.toStringAsFixed(6)} BTC'),
      _GridItem(Icons.view_module_rounded, _D.purple,   'Rigs',
          '${game.ownedRigIds.length} / ${game.rigCapacity}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: items.map((e) => _GridTile(item: e)).toList(),
    );
  }
}

class _GridItem {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  const _GridItem(this.icon, this.accent, this.label, this.value);
}

class _GridTile extends StatelessWidget {
  final _GridItem item;
  const _GridTile({required this.item});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _D.cardBord),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: item.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(item.icon, color: item.accent, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.label,
              style: const TextStyle(color: _D.textLow, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.accent,
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
        ],
      )),
    ]),
  );
}

// ─── Status row ───────────────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final GameStateService game;
  const _StatusRow({required this.game});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: _StatusTile(
        icon:   Icons.workspace_premium_rounded,
        label:  'Premium',
        active: game.isPremiumActive,
        accent: _D.gold,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _StatusTile(
        icon:   Icons.timer_rounded,
        label:  'Session · ${game.totalSessionsStarted} started',
        active: game.isSessionActive,
        accent: _D.electric,
      ),
    ),
  ]);
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: active ? accent.withValues(alpha: 0.08) : _D.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: active ? accent.withValues(alpha: 0.35) : _D.cardBord,
      ),
    ),
    child: Row(children: [
      Icon(icon, color: active ? accent : _D.textLow, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _D.textMid, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: active ? accent : _D.textLow,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      )),
    ]),
  );
}

// ─── Energy card ──────────────────────────────────────────────────────────────
class _EnergyCard extends StatelessWidget {
  final EnergyCoolingService energy;
  const _EnergyCard({required this.energy});

  @override
  Widget build(BuildContext context) {
    final heat      = energy.heat.clamp(0.0, 100.0);
    final heatColor = Color.lerp(_D.green, _D.red, heat / 100)!;
    return _GlassCard(
      child: Column(children: [
        Row(children: [
          // Cooling
          _EnergyBadge(icon: Icons.ac_unit_rounded,    color: _D.electric, label: 'Cooling',  value: 'Lv ${energy.coolingLevel}'),
          const SizedBox(width: 8),
          _EnergyBadge(icon: Icons.bolt_rounded,       color: _D.gold,     label: 'Power',    value: 'Lv ${energy.powerLevel}'),
          const SizedBox(width: 8),
          _EnergyBadge(icon: Icons.wb_sunny_rounded,   color: _D.green,    label: 'Solar',    value: 'Lv ${energy.solarLevel}'),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Heat', style: TextStyle(color: _D.textMid, fontSize: 12)),
          Text(
            '${heat.toStringAsFixed(1)}%',
            style: TextStyle(
              color: heatColor,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: heat / 100,
            minHeight: 6,
            backgroundColor: _D.cardBord,
            valueColor: AlwaysStoppedAnimation(heatColor),
          ),
        ),
      ]),
    );
  }
}

class _EnergyBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _EnergyBadge({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
              color: color,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            )),
        Text(label, style: const TextStyle(color: _D.textLow, fontSize: 10)),
      ]),
    ),
  );
}

// ─── Withdrawal card ──────────────────────────────────────────────────────────
class _WithdrawalCard extends StatelessWidget {
  final GameStateService game;
  final WithdrawalService withdrawal;
  final AdPacingService pacing;
  final BtcPriceService btcPrice;

  const _WithdrawalCard({
    required this.game,
    required this.withdrawal,
    required this.pacing,
    required this.btcPrice,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = withdrawal.withdrawalUnlocked;
    final worth = btcPrice.balanceWorthUsd(game.btcBalance);
    final minBtc = btcPrice.priceUsd != null
        ? withdrawal.minBtcForWithdrawal(btcPrice.priceUsd!)
        : 0.0;
    final canWithdraw = unlocked && worth != null && worth >= WithdrawalService.minWithdrawalUsd;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked ? Icons.account_balance_wallet_rounded : Icons.lock_rounded,
                color: unlocked ? _D.green : _D.textLow,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                unlocked ? 'Withdrawal unlocked' : 'Unlock withdrawal',
                style: TextStyle(
                  color: unlocked ? _D.green : _D.textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!unlocked) ...[
            _WithdrawalTask(
              done: withdrawal.meetsSessions(game.totalSessionsStarted),
              label: 'Complete ${WithdrawalService.sessionsRequired} mining sessions',
              value: '${game.totalSessionsStarted}/${WithdrawalService.sessionsRequired}',
            ),
            const SizedBox(height: 6),
            _WithdrawalTask(
              done: withdrawal.meetsRewardedAds(pacing.rewardedAdsWatchedCount),
              label: 'Watch ${WithdrawalService.rewardedAdsRequired} rewarded ads',
              value: '${pacing.rewardedAdsWatchedCount}/${WithdrawalService.rewardedAdsRequired}',
            ),
            const SizedBox(height: 6),
            _WithdrawalTask(
              done: withdrawal.meetsMinBtc(game.btcBalance),
              label: 'Reach ${WithdrawalService.minBtcToUnlock} BTC balance',
              value: game.btcBalance.toStringAsFixed(4),
            ),
          ] else ...[
            Text(
              'Minimum withdrawal: \$${WithdrawalService.minWithdrawalUsd.toStringAsFixed(0)} worth of BTC.',
              style: const TextStyle(color: _D.textMid, fontSize: 12),
            ),
            if (btcPrice.priceUsd != null)
              Text(
                'You need ${minBtc.toStringAsFixed(6)} BTC (you have ${game.btcBalance.toStringAsFixed(6)}).',
                style: const TextStyle(color: _D.textLow, fontSize: 11),
              ),
            const SizedBox(height: 10),
            if (canWithdraw)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _toast(context, 'Withdrawal request will be processed. Contact support with your user ID.');
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Request withdrawal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _D.green,
                    side: const BorderSide(color: _D.green),
                  ),
                ),
              )
            else
              Text(
                'Keep mining to reach \$${WithdrawalService.minWithdrawalUsd} in BTC.',
                style: const TextStyle(color: _D.textMid, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }
}

class _WithdrawalTask extends StatelessWidget {
  final bool done;
  final String label;
  final String value;

  const _WithdrawalTask({
    required this.done,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: done ? _D.green : _D.textLow,
        size: 18,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label, style: const TextStyle(color: _D.textMid, fontSize: 12)),
      ),
      Text(
        value,
        style: TextStyle(
          color: done ? _D.green : _D.textLow,
          fontFamily: AppTheme.fontFamily,
          fontSize: 11,
        ),
      ),
    ],
  );
}

class _ShareButton extends StatelessWidget {
  final ReferralService referral;

  const _ShareButton({required this.referral});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final code = referral.myCode ?? '';
        final text = 'Join me on Bitcoin Mining! Use my code $code to get started. '
            'Download the app and enter the code in Profile → Invite friends. '
            '${AppConstants.playStoreUrl}';
        Share.share(text);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _D.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _D.green.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.share_rounded, color: _D.green, size: 16),
      ),
    );
  }
}

class _EnterReferralCode extends StatefulWidget {
  final AuthService auth;
  final ReferralService referral;

  const _EnterReferralCode({
    required this.auth,
    required this.referral,
  });

  @override
  State<_EnterReferralCode> createState() => _EnterReferralCodeState();
}

class _EnterReferralCodeState extends State<_EnterReferralCode> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Friend\'s code',
              hintStyle: const TextStyle(color: _D.textLow, fontSize: 12),
              filled: true,
              fillColor: _D.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _D.cardBord),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(color: _D.textHi, fontSize: 13),
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _loading ? null : () async {
              final code = _controller.text.trim().toUpperCase();
              if (code.isEmpty) {
                _toast(context, 'Enter a code');
                return;
              }
              final uid = widget.auth.currentUser?.uid;
              if (uid == null) {
                _toast(context, 'Sign in to use a code');
                return;
              }
              setState(() => _loading = true);
              await widget.referral.applyReferral(uid, code);
              await widget.referral.load(uid);
              if (mounted) {
                setState(() => _loading = false);
                _toast(context, 'Referral code applied!');
                _controller.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _D.pink,
              foregroundColor: Colors.white,
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Apply'),
          ),
        ),
      ],
    );
  }
}

// ─── Referral card ────────────────────────────────────────────────────────────
class _ReferralCard extends StatelessWidget {
  final ReferralService referral;
  final GameStateService game;
  final AuthService auth;

  const _ReferralCard({
    required this.referral,
    required this.game,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'Earn BTC and rewards by inviting friends! Share the app and use your code.',
        style: TextStyle(color: _D.textMid, fontSize: 11),
      ),
      const SizedBox(height: 10),
      // Code row
      Row(children: [
        const Icon(Icons.person_add_rounded, color: _D.pink, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your referral code',
              style: TextStyle(color: _D.textMid, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            referral.myCode ?? '—',
            style: const TextStyle(
              color: _D.pink,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ])),
        GestureDetector(
          onTap: () {
            if (referral.myCode != null) {
              Clipboard.setData(ClipboardData(text: referral.myCode!));
              _toast(context, 'Code copied!');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _D.pink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _D.pink.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.copy_rounded, color: _D.pink, size: 16),
          ),
        ),
        const SizedBox(width: 8),
        _ShareButton(referral: referral),
      ]),

      const SizedBox(height: 14),
      Row(children: [
        const Icon(Icons.group_rounded, color: _D.textMid, size: 14),
        const SizedBox(width: 6),
        Text(
          '${referral.friends} friend${referral.friends == 1 ? '' : 's'} referred',
          style: const TextStyle(color: _D.textMid, fontSize: 12),
        ),
      ]),
      const SizedBox(height: 14),
      _EnterReferralCode(auth: auth, referral: referral),
      const SizedBox(height: 14),

      // Reward buttons
      Row(children: [
        Expanded(child: _RewardBtn(
          label:     '1 Friend',
          sublabel:  '+0.00005 BTC',
          friends:   1,
          count:     referral.friends,
          claimed:   !referral.canClaimReward('friends_1'),
          accent:    _D.green,
          onClaim: () async {
            await game.grantDirectBtc(0.00005);
            await referral.markClaimed('friends_1');
          },
        )),
        const SizedBox(width: 8),
        Expanded(child: _RewardBtn(
          label:     '5 Friends',
          sublabel:  'GPU Rig',
          friends:   5,
          count:     referral.friends,
          claimed:   !referral.canClaimReward('friends_5'),
          accent:    _D.electric,
          onClaim: () async {
            await game.grantRig('gpu_rig');
            await referral.markClaimed('friends_5');
          },
        )),
        const SizedBox(width: 8),
        Expanded(child: _RewardBtn(
          label:     '10 Friends',
          sublabel:  '24h Boost',
          friends:   10,
          count:     referral.friends,
          claimed:   !referral.canClaimReward('friends_10'),
          accent:    _D.gold,
          onClaim: () async {
            await game.activateBoost(duration: const Duration(hours: 24));
            await referral.markClaimed('friends_10');
          },
        )),
      ]),
    ]),
  );
}

class _RewardBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final int friends;
  final int count;
  final bool claimed;
  final Color accent;
  final VoidCallback onClaim;
  const _RewardBtn({
    required this.label,
    required this.sublabel,
    required this.friends,
    required this.count,
    required this.claimed,
    required this.accent,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = count >= friends;
    final canClaim = unlocked && !claimed;
    return GestureDetector(
      onTap: canClaim ? onClaim : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: claimed
              ? _D.cardBord.withValues(alpha: 0.5)
              : canClaim
              ? accent.withValues(alpha: 0.15)
              : _D.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: claimed
                ? Colors.transparent
                : canClaim
                ? accent.withValues(alpha: 0.45)
                : _D.cardBord,
          ),
        ),
        child: Column(children: [
          Icon(
            claimed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
            color: claimed ? _D.textLow : canClaim ? accent : _D.textLow,
            size: 18,
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                color: claimed ? _D.textLow : canClaim ? accent : _D.textMid,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
          Text(sublabel,
              style: const TextStyle(color: _D.textLow, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ─── Legal & support (Privacy, Terms, Share, Rate) ────────────────────────────
class _LegalSupportSection extends StatelessWidget {
  const _LegalSupportSection();

  static const _privacyUrl = 'https://example.com/privacy';
  static const _termsUrl = 'https://example.com/terms';

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          _LegalTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => _openUrl(context, _privacyUrl),
          ),
          const Divider(height: 1, color: _D.cardBord),
          _LegalTile(
            icon: Icons.description_outlined,
            label: 'Terms & Conditions',
            onTap: () => _openUrl(context, _termsUrl),
          ),
          const Divider(height: 1, color: _D.cardBord),
          _LegalTile(
            icon: Icons.share_rounded,
            label: 'Share App',
            onTap: () {
              Share.share(
                'Check out Bitcoin Mining – mine BTC, build your farm, and climb the leaderboard! '
                '${AppConstants.playStoreUrl}',
              );
            },
          ),
          const Divider(height: 1, color: _D.cardBord),
          _LegalTile(
            icon: Icons.star_rounded,
            label: 'Rate App',
            onTap: () async {
              try {
                final review = InAppReview.instance;
                if (await review.isAvailable()) {
                  await review.requestReview();
                } else {
                  await _openUrl(context, AppConstants.playStoreUrl);
                }
              } catch (_) {
                if (context.mounted) {
                  await _openUrl(context, AppConstants.playStoreUrl);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) _toast(context, 'Could not open link');
    }
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LegalTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: _D.textMid, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: _D.textHi,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: _D.textLow, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Sign out ─────────────────────────────────────────────────────────────────
class _SignOutTile extends StatelessWidget {
  final AuthService auth;
  final bool isGuest;
  const _SignOutTile({required this.auth, required this.isGuest});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _D.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _D.red.withValues(alpha: 0.3)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _D.red.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.logout_rounded, color: _D.red, size: 26),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sign out?',
                      style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    isGuest
                        ? 'As a guest your progress stays on this device only.'
                        : 'You can always sign back in to restore your progress.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _D.textMid, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _OutlineBtn(label: 'Cancel', onTap: () => Navigator.pop(ctx, false))),
                    const SizedBox(width: 12),
                    Expanded(child: _DangerBtn(label: 'Sign out', onTap: () => Navigator.pop(ctx, true))),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      );
      if (ok == true && context.mounted) {
        await auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
        }
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _D.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.red.withValues(alpha: 0.25)),
      ),
      child: const Row(children: [
        Icon(Icons.logout_rounded, color: _D.red, size: 20),
        SizedBox(width: 12),
        Text('Sign out',
            style: TextStyle(color: _D.red, fontWeight: FontWeight.w700, fontSize: 14)),
        Spacer(),
        Icon(Icons.chevron_right_rounded, color: _D.red, size: 20),
      ]),
    ),
  );
}

// ─── Shared components ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _D.textMid,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _D.cardBord),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: child,
  );
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final bool compact;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, this.compact = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: _D.gold.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12)),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(color: _D.cardBord, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: const Text('Cancel', style: TextStyle(color: _D.textMid, fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}

class _DangerBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: _D.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _D.red.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: const Text('Sign out',
          style: TextStyle(color: _D.red, fontWeight: FontWeight.w700, fontSize: 13)),
    ),
  );
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: const SizedBox.shrink(),
    ),
  );
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _D.textHi)),
    backgroundColor: _D.card,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: _D.cardBord),
    ),
  ));
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: AppTheme.fontFamily,
  textTheme: AppTheme.darkTextTheme,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);