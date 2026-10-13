import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/mining_economy.dart';
import '../constants/app_constants.dart';
import '../services/ad_pacing_service.dart';
import '../services/auth_service.dart';
import '../services/btc_price_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../services/referral_service.dart';
import '../services/smart_ad_manager.dart';
import '../services/withdrawal_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rate_app_dialog.dart';
import '../widgets/screen_ad_slot.dart';
import '../widgets/user_circle_avatar.dart';
import 'legal_document_screen.dart';

class _D {
  static const bg = Color(0xFF08080A);
  static const surface = Color(0xFF18181C);
  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBg = Color(0xFF1A1228);
  static const goldBdr = Color(0x669945FF);
  static const green = Color(0xFF14F195);
  static const greenText = Color(0xFFBBF7D0);
  static const greenBg = Color(0xFF0A2E22);
  static const greenBdr = Color(0x6614F195);
  static const electric = Color(0xFF38BDF8);
  static const electricBg = Color(0xFF0C1A24);
  static const electricBdr = Color(0xFF164E63);
  static const violet = Color(0xFFA78BFA);
  static const pink = Color(0xFFEC4899);
  static const pinkBg = Color(0xFF3F1219);
  static const red = Color(0xFFEF4444);
  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
  static const textLow = Color(0xFF71717A);
  static const line = Color(0x1FFFFFFF);
}

TextStyle _sg({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _D.textHi,
  double? spacing,
  double? height,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w600,
  Color color = _D.textHi,
}) =>
    GoogleFonts.spaceMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.15,
    );

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final game = context.watch<GameStateService>();
    final energy = context.watch<EnergyCoolingService>();
    final referral = context.watch<ReferralService>();
    final withdrawal = context.watch<WithdrawalService>();
    final pacing = context.watch<AdPacingService>();
    final btcPrice = context.watch<BtcPriceService>();
    final user = auth.currentUser;
    final isGuest = user?.isAnonymous == true;
    final displayName = auth.displayNameOf(user);

    if (referral.myCode == null || referral.myCode!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<ReferralService>().ensureLoaded(
          uid: user?.uid,
          displayName: displayName,
          signedIn: user != null && !isGuest,
        );
      });
    }

    withdrawal.recheckUnlock(
      purchasedUnlock: game.hasPurchasedOneTime(WithdrawalService.unlockProductId),
      worthUsd: btcPrice.balanceWorthUsd(game.btcBalance),
    );

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: AppTheme.pageScroll,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: const Color(0xCC08080A),
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _D.textMid, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: const ColoredBox(color: Color(0xF208080A)),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                          ).createShader(r),
                          child: Text('Profile', style: _sg(size: 16, weight: FontWeight.w700, spacing: -0.3, color: Colors.white)),
                        ),
                        Text('ACCOUNT', style: _sg(size: 9, weight: FontWeight.w700, color: _D.gold, spacing: 1.6)),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, AppTheme.pageBottomPadding(context)),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _AvatarHero(
                          user: user,
                          displayName: displayName,
                          photoUrl: auth.photoUrlOf(user),
                          isGuest: isGuest,
                          isPremium: game.isPremiumActive,
                        ),
                        const SizedBox(height: 20),
                        if (isGuest) ...[
                          _GuestLinkCard(auth: auth),
                          const SizedBox(height: 22),
                        ],
                        const _SectionLabel('Mining stats'),
                        const SizedBox(height: 12),
                        _StatsGrid(game: game),
                        const SizedBox(height: 22),
                        const _SectionLabel('Status'),
                        const SizedBox(height: 12),
                        _StatusRow(game: game),
                        const SizedBox(height: 22),
                        const _SectionLabel('Energy & cooling'),
                        const SizedBox(height: 12),
                        _EnergyCard(energy: energy),
                        const SizedBox(height: 22),
                        const _SectionLabel('Withdrawal'),
                        const SizedBox(height: 12),
                        _WithdrawalCard(game: game, withdrawal: withdrawal, pacing: pacing, btcPrice: btcPrice),
                        const SizedBox(height: 22),
                        const _SectionLabel('Invite friends'),
                        const SizedBox(height: 12),
                        _ReferralCard(referral: referral, game: game, auth: auth),
                        const SizedBox(height: 22),
                        const ScreenAdSlot(title: 'Profile offer'),
                        const SizedBox(height: 22),
                        const _SectionLabel('Legal & support'),
                        const SizedBox(height: 12),
                        const _LegalSupportSection(),
                        const SizedBox(height: 18),
                        _SignOutTile(auth: auth, isGuest: isGuest),
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

class _AvatarHero extends StatelessWidget {
  final dynamic user;
  final String displayName;
  final String? photoUrl;
  final bool isGuest;
  final bool isPremium;

  const _AvatarHero({
    required this.user,
    required this.displayName,
    required this.photoUrl,
    required this.isGuest,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final email = user?.email as String?;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195), Color(0xFF9945FF)]),
                boxShadow: [BoxShadow(color: _D.gold.withValues(alpha: 0.22), blurRadius: 28)],
              ),
            ),
            UserCircleAvatar(
              name: displayName,
              photoUrl: photoUrl,
              size: 102,
            ),
            const Positioned(
              right: 8,
              bottom: 8,
              child: _OnlineDot(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(displayName, textAlign: TextAlign.center, style: _sg(size: 24, weight: FontWeight.w700, spacing: -0.5)),
        const SizedBox(height: 8),
        if (email != null && email.isNotEmpty)
          Text(email, style: _sg(size: 13, color: _D.textMid))
        else
          _Pill(label: isGuest ? 'GUEST' : 'MINER', color: _D.textMid),
        if (isPremium) ...[
          const SizedBox(height: 8),
          const _Pill(label: 'PREMIUM', color: _D.goldText, tint: _D.goldBg, border: _D.goldBdr),
        ],
      ],
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _D.green,
        border: Border.all(color: _D.bg, width: 3),
        boxShadow: [BoxShadow(color: _D.green.withValues(alpha: 0.5), blurRadius: 8)],
      ),
    );
  }
}

class _GuestLinkCard extends StatelessWidget {
  final AuthService auth;
  const _GuestLinkCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      tint: const Color(0xC01A1228),
      border: _D.goldBdr,
      child: Row(
        children: [
          const _MiniIcon(icon: Icons.link_rounded, color: _D.gold, tint: _D.goldBg, border: _D.goldBdr),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest account', style: _sg(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Link Google to keep this farm synced.', style: _sg(size: 12, color: _D.textMid, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _GradientButton(
            label: 'Link',
            compact: true,
            onTap: () async {
              try {
                await auth.linkWithGoogle();
                if (context.mounted) _toast(context, 'Account linked with Google');
              } catch (e) {
                if (context.mounted) _toast(context, 'Error: $e');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final GameStateService game;
  const _StatsGrid({required this.game});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.factory_rounded, 'Farm tier', game.currentFarmTier.name, _D.gold, _D.goldBg, _D.goldBdr),
      (Icons.speed_rounded, 'Hash power', '${game.totalBtcPerMin.toStringAsFixed(6)}', _D.electric, _D.electricBg, _D.electricBdr),
      (Icons.savings_rounded, 'Lifetime', '${game.lifetimeMinedBtc.toStringAsFixed(6)}', _D.green, _D.greenBg, _D.greenBdr),
      (Icons.memory_rounded, 'Rigs', '${game.ownedRigIds.length} / ${game.rigCapacity}', _D.violet, const Color(0xFF1A1228), const Color(0xFF4C1D95)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.58,
      children: [
        for (final item in items)
          _Glass(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniIcon(icon: item.$1, color: item.$4, tint: item.$5, border: item.$6, size: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: _sg(size: 11, color: _D.textMid)),
                    const SizedBox(height: 2),
                    Text(item.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: _sg(size: 14, weight: FontWeight.w700, spacing: -0.2)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final GameStateService game;
  const _StatusRow({required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusTile(
            icon: Icons.workspace_premium_rounded,
            label: 'Premium',
            value: game.isPremiumActive ? 'Active' : 'Free',
            active: game.isPremiumActive,
            color: _D.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusTile(
            icon: Icons.timer_rounded,
            label: '${game.totalSessionsStarted} sessions',
            value: game.isSessionActive ? 'Running' : 'Idle',
            active: game.isSessionActive,
            color: _D.electric,
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool active;
  final Color color;

  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      tint: active ? color.withValues(alpha: 0.10) : const Color(0xB318181C),
      border: active ? color.withValues(alpha: 0.38) : _D.line,
      child: Row(
        children: [
          Icon(icon, color: active ? color : _D.textLow, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _sg(size: 11, color: _D.textMid)),
                Text(value, style: _sg(size: 13, weight: FontWeight.w700, color: active ? color : _D.textHi)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  final EnergyCoolingService energy;
  const _EnergyCard({required this.energy});

  @override
  Widget build(BuildContext context) {
    final heat = energy.heat.clamp(0.0, 100.0);
    final heatColor = Color.lerp(_D.green, _D.red, heat / 100)!;
    return _Glass(
      child: Column(
        children: [
          Row(
            children: [
              _EnergyBadge(icon: Icons.ac_unit_rounded, color: _D.electric, label: 'Cooling', value: 'Lv ${energy.coolingLevel}'),
              const SizedBox(width: 8),
              _EnergyBadge(icon: Icons.bolt_rounded, color: _D.gold, label: 'Power', value: 'Lv ${energy.powerLevel}'),
              const SizedBox(width: 8),
              _EnergyBadge(icon: Icons.wb_sunny_rounded, color: _D.green, label: 'Solar', value: 'Lv ${energy.solarLevel}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Heat', style: _sg(size: 12, color: _D.textMid)),
              const Spacer(),
              Text('${heat.toStringAsFixed(1)}%', style: _mono(size: 12, color: heatColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: heat / 100,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: heatColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _EnergyBadge({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value, style: _mono(size: 12, color: color)),
            Text(label, style: _sg(size: 10, color: _D.textLow)),
          ],
        ),
      ),
    );
  }
}

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
    final purchased = game.hasPurchasedOneTime(WithdrawalService.unlockProductId);
    final worth = btcPrice.balanceWorthUsd(game.btcBalance);
    final minBtc = btcPrice.priceUsd == null
        ? 0.0
        : withdrawal.minBtcForWithdrawal(btcPrice.priceUsd!);
    final step = withdrawal.currentStep(purchasedUnlock: purchased, worthUsd: worth);
    final ads = context.watch<SmartAdManager>();
    final iap = context.watch<IapService>();
    final adsWatched = withdrawal.unlockAdsWatched.clamp(0, WithdrawalService.rewardedAdsRequired);
    final adsFrac = adsWatched / WithdrawalService.rewardedAdsRequired;
    final minReached = withdrawal.minBalanceReached(worth);
    final ready = step >= 4;

    return _Glass(
      border: ready ? _D.greenBdr : _D.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ready ? Icons.account_balance_wallet_rounded : Icons.lock_rounded,
                color: ready ? _D.green : _D.textLow,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  ready ? 'Ready to withdraw' : 'Unlock withdrawal',
                  style: _sg(size: 15, weight: FontWeight.w700),
                ),
              ),
              Text('Step ${step.clamp(1, 3)}/3', style: _mono(size: 11, color: _D.goldText)),
            ],
          ),
          const SizedBox(height: 16),

          if (step == 1) ...[
            Text(
              'Watch ${WithdrawalService.rewardedAdsRequired} rewarded ads',
              style: _sg(size: 13.5, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Finish this step to unlock the next ones.',
              style: _sg(size: 12.5, color: _D.textMid, height: 1.35),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: adsFrac,
                minHeight: 10,
                backgroundColor: const Color(0xFF27272A),
                color: _D.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$adsWatched / ${WithdrawalService.rewardedAdsRequired}',
              style: _mono(size: 12, color: _D.goldText),
            ),
            const SizedBox(height: 14),
            _GradientButton(
              label: ads.loadingRewarded ? 'Loading ad…' : 'Watch rewarded ad',
              icon: Icons.play_circle_outline_rounded,
              onTap: ads.loadingRewarded
                  ? null
                  : () => _watchUnlockAd(context, ads, pacing, withdrawal, purchased, worth),
            ),
          ] else ...[
            if (minReached) ...[
              _WithdrawalStep(
                index: 3,
                state: purchased ? _StepState.done : _StepState.current,
                title: 'Unlock withdrawal',
                subtitle: purchased
                    ? 'Pack purchased'
                    : 'Buy the ${WithdrawalService.unlockPriceLabel} pack to finish',
                isLast: false,
              ),
              if (!purchased) ...[
                _GradientButton(
                  label: 'Unlock for ${WithdrawalService.unlockPriceLabel}',
                  icon: Icons.lock_open_rounded,
                  onTap: () => _buyUnlock(context, iap),
                ),
                const SizedBox(height: 14),
              ],
            ],
            _WithdrawalStep(
              index: 2,
              state: minReached ? _StepState.done : _StepState.current,
              title: 'Reach \$${WithdrawalService.minWithdrawalUsd.toStringAsFixed(0)} USD',
              subtitle: worth == null
                  ? 'Keep mining'
                  : minReached
                      ? 'Minimum reached'
                      : 'You have \$${worth.toStringAsFixed(2)} · need ${minBtc.toStringAsFixed(6)} SOL',
              isLast: true,
            ),
            if (!minReached)
              Text(
                'Keep mining. Unlock withdrawal appears when you hit \$${WithdrawalService.minWithdrawalUsd.toStringAsFixed(0)}.',
                style: _sg(size: 12.5, color: _D.textMid),
              )
            else if (purchased)
              _GradientButton(
                label: 'Request withdrawal',
                icon: Icons.send_rounded,
                onTap: () => _toast(
                  context,
                  'Withdrawal request will be processed. Contact support with your user ID.',
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _buyUnlock(BuildContext context, IapService iap) async {
    if (iap.products.isEmpty) await iap.init();
    final ok = await iap.buyProduct(WithdrawalService.unlockProductId);
    if (!context.mounted) return;
    _toast(
      context,
      ok
          ? 'Complete purchase in Google Play to unlock withdrawal.'
          : (iap.error ?? 'Create product "${WithdrawalService.unlockProductId}" in Play Console.'),
    );
  }

  Future<void> _watchUnlockAd(
    BuildContext context,
    SmartAdManager ads,
    AdPacingService pacing,
    WithdrawalService withdrawal,
    bool purchased,
    double? worth,
  ) async {
    final canShow = await pacing.canShowRewarded();
    if (!canShow) {
      if (context.mounted) {
        _toast(context, 'Wait ${pacing.rewardedCooldownLeft().inSeconds}s before the next ad.');
      }
      return;
    }
    final shown = await ads.showRewarded(onEarned: () {});
    if (!context.mounted) return;
    if (shown) {
      await pacing.markRewardedShown();
      await withdrawal.recordUnlockAdWatched();
      withdrawal.recheckUnlock(purchasedUnlock: purchased, worthUsd: worth);
      final n = withdrawal.unlockAdsWatched;
      _toast(
        context,
        n >= WithdrawalService.rewardedAdsRequired
            ? 'Step 1 done. Now reach \$${WithdrawalService.minWithdrawalUsd.toStringAsFixed(0)} USD.'
            : '$n / ${WithdrawalService.rewardedAdsRequired} ads complete.',
      );
    } else {
      _toast(context, ads.lastError ?? 'Rewarded ad not ready. Try again in a moment.');
    }
  }
}

enum _StepState { locked, current, done }

class _WithdrawalStep extends StatelessWidget {
  final int index;
  final _StepState state;
  final String title;
  final String subtitle;
  final bool isLast;

  const _WithdrawalStep({
    required this.index,
    required this.state,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => _D.green,
      _StepState.current => _D.gold,
      _StepState.locked => _D.textLow,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 14 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.16),
                    border: Border.all(color: color, width: 1.2),
                  ),
                  child: state == _StepState.done
                      ? const Icon(Icons.check_rounded, size: 13, color: _D.green)
                      : state == _StepState.locked
                          ? const Icon(Icons.lock_rounded, size: 11, color: _D.textLow)
                          : Text('$index', style: _mono(size: 10, color: _D.goldText)),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 22,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: state == _StepState.done ? _D.green.withValues(alpha: 0.45) : _D.line,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _sg(
                      size: 13,
                      weight: FontWeight.w700,
                      color: state == _StepState.locked ? _D.textLow : _D.textHi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _sg(size: 11.5, color: _D.textMid, height: 1.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final ReferralService referral;
  final GameStateService game;
  final AuthService auth;

  const _ReferralCard({required this.referral, required this.game, required this.auth});

  String get _code {
    final mine = referral.myCode;
    if (mine != null && mine.isNotEmpty) return mine;
    final user = auth.currentUser;
    final uid = user?.uid;
    if (uid != null && user?.isAnonymous != true) {
      final fromUid = ReferralService.codeCandidatesFromUid(uid);
      if (fromUid.isNotEmpty) return fromUid.first;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share your code. You earn SOL every time a friend joins.',
            style: _sg(size: 12.5, color: _D.textMid, height: 1.35),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _D.pink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _D.pink.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add_rounded, color: _D.pink, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR CODE', style: _sg(size: 9, weight: FontWeight.w700, color: _D.textLow, spacing: 1.2)),
                      Text(code, style: _mono(size: 16, weight: FontWeight.w700, color: _D.pink)),
                    ],
                  ),
                ),
                _IconAction(
                  icon: Icons.copy_rounded,
                  onTap: () {
                    if (code == '—') return;
                    Clipboard.setData(ClipboardData(text: code));
                    _toast(context, 'Code copied');
                  },
                ),
                const SizedBox(width: 8),
                _IconAction(icon: Icons.share_rounded, color: _D.green, onTap: () => _shareReferral(code)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.group_rounded, color: _D.textMid, size: 15),
              const SizedBox(width: 6),
              Text('${referral.friends} friend${referral.friends == 1 ? '' : 's'} joined', style: _sg(size: 12, color: _D.textMid)),
              const Spacer(),
              Text('+${MiningEconomy.toSol(ReferralService.inviterBonusBtc).toStringAsFixed(3)} SOL each', style: _sg(size: 11, weight: FontWeight.w700, color: _D.green)),
            ],
          ),
          const SizedBox(height: 12),
          if (referral.referredUsers.isEmpty)
            Text('No referrals yet.', style: _sg(size: 12, color: _D.textLow))
          else
            ...referral.referredUsers.take(12).map(
                  (user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const _MiniIcon(icon: Icons.person_rounded, color: _D.pink, tint: _D.pinkBg, border: Color(0x66EC4899), size: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _sg(size: 13, weight: FontWeight.w600))),
                    if (user.joinedAt != null)
                      Text('${user.joinedAt!.day}/${user.joinedAt!.month}/${user.joinedAt!.year}', style: _sg(size: 11, color: _D.textLow)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (referral.hasUsedReferralCode)
            Text('You already joined with a friend\'s code.', style: _sg(size: 12, color: _D.textMid))
          else
            _EnterReferralCode(auth: auth, referral: referral, game: game),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _RewardButton(label: '1 Friend', reward: '+0.025 SOL', friends: 1, count: referral.friends, claimed: !referral.canClaimReward('friends_1'), color: _D.green, onClaim: () async {
                await game.grantDirectBtc(0.00005);
                await referral.markClaimed('friends_1');
              })),
              const SizedBox(width: 8),
              Expanded(child: _RewardButton(label: '5 Friends', reward: 'GPU Rig', friends: 5, count: referral.friends, claimed: !referral.canClaimReward('friends_5'), color: _D.electric, onClaim: () async {
                await game.grantRig('gpu_rig');
                await referral.markClaimed('friends_5');
              })),
              const SizedBox(width: 8),
              Expanded(child: _RewardButton(label: '10 Friends', reward: '24h Boost', friends: 10, count: referral.friends, claimed: !referral.canClaimReward('friends_10'), color: _D.gold, onClaim: () async {
                await game.activateBoost(duration: const Duration(hours: 24));
                await referral.markClaimed('friends_10');
              })),
            ],
          ),
        ],
      ),
    );
  }
}

void _shareReferral(String code) {
  if (code.isEmpty || code == '—') return;
  Share.share(
    'Join me on Solana Mining Tycoon! Use my code $code to get started. '
        'Download the app and enter the code in Profile → Invite friends. '
        '${AppConstants.playStoreUrl}',
  );
}

class _EnterReferralCode extends StatefulWidget {
  final AuthService auth;
  final ReferralService referral;
  final GameStateService game;

  const _EnterReferralCode({required this.auth, required this.referral, required this.game});

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

  Future<void> _apply() async {
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
    final name = widget.auth.displayNameOf(widget.auth.currentUser);
    final result = await widget.referral.applyReferral(uid, code, displayName: name);
    if (result.ok) {
      await widget.game.grantDirectBtc(ReferralService.welcomeBonusBtc);
      await widget.referral.load(
        uid,
        displayName: name,
        signedIn: widget.auth.currentUser?.isAnonymous != true,
      );
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _toast(context, result.message);
    if (result.ok) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            cursorColor: _D.green,
            style: _mono(size: 13, color: _D.textHi),
            decoration: InputDecoration(
              hintText: 'Friend\'s code',
              hintStyle: _sg(size: 12, color: _D.textLow),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.045),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: _fieldBorder(),
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(color: _D.green),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _GradientButton(label: 'Apply', compact: true, loading: _loading, onTap: _apply),
      ],
    );
  }

  OutlineInputBorder _fieldBorder({Color color = _D.line}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );
}

class _RewardButton extends StatelessWidget {
  final String label;
  final String reward;
  final int friends;
  final int count;
  final bool claimed;
  final Color color;
  final Future<void> Function() onClaim;

  const _RewardButton({
    required this.label,
    required this.reward,
    required this.friends,
    required this.count,
    required this.claimed,
    required this.color,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final canClaim = count >= friends && !claimed;
    return GestureDetector(
      onTap: canClaim
          ? () async {
        HapticFeedback.lightImpact();
        await onClaim();
        if (context.mounted) _toast(context, '$label reward claimed');
      }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: canClaim ? color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: canClaim ? color.withValues(alpha: 0.4) : _D.line),
        ),
        child: Column(
          children: [
            Icon(claimed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded, color: canClaim ? color : _D.textLow, size: 17),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: _sg(size: 11, weight: FontWeight.w700, color: canClaim ? color : _D.textMid)),
            Text(reward, textAlign: TextAlign.center, style: _sg(size: 10, color: _D.textLow)),
          ],
        ),
      ),
    );
  }
}

class _LegalSupportSection extends StatelessWidget {
  const _LegalSupportSection();

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          _LegalTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => LegalDocumentScreen.openPrivacy(context),
          ),
          _LegalTile(
            icon: Icons.description_outlined,
            label: 'Terms & Conditions',
            onTap: () => LegalDocumentScreen.openTerms(context),
          ),
          _LegalTile(
            icon: Icons.share_rounded,
            label: 'Share App',
            onTap: () => Share.share(
              'Check out Solana Mining Tycoon – mine SOL, run validators, build your farm, and climb the leaderboard! '
                  '${AppConstants.playStoreUrl}',
            ),
          ),
          _LegalTile(icon: Icons.star_rounded, label: 'Rate App', showDivider: false, onTap: () => _rate(context)),
        ],
      ),
    );
  }

  Future<void> _rate(BuildContext context) async {
    await RateAppDialog.show(context);
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _LegalTile({required this.icon, required this.label, required this.onTap, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: _D.textMid, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: _sg(size: 14, weight: FontWeight.w600))),
                const Icon(Icons.chevron_right_rounded, color: _D.textLow, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
      ],
    );
  }
}

class _SignOutTile extends StatelessWidget {
  final AuthService auth;
  final bool isGuest;

  const _SignOutTile({required this.auth, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xF0111114),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _D.red.withValues(alpha: 0.32)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded, color: _D.red, size: 30),
                      const SizedBox(height: 14),
                      Text('Sign out?', style: _sg(size: 20, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        isGuest
                            ? 'As a guest, your progress stays on this device only.'
                            : 'You can sign back in to restore your progress.',
                        textAlign: TextAlign.center,
                        style: _sg(size: 13, color: _D.textMid, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _QuietButton(label: 'Cancel', onTap: () => Navigator.pop(ctx, false))),
                          const SizedBox(width: 10),
                          Expanded(child: _DangerButton(label: 'Sign out', onTap: () => Navigator.pop(ctx, true))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        if (ok == true && context.mounted) {
          await auth.signOut();
          if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _D.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _D.red.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: _D.red, size: 18),
            const SizedBox(width: 10),
            Text('Sign out', style: _sg(size: 14, weight: FontWeight.w700, color: _D.red)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: _D.red, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: _D.gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label.toUpperCase(), style: _sg(size: 10, weight: FontWeight.w700, color: _D.textMid, spacing: 1.5)),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final Color border;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tint = const Color(0xF21F1F26),
    this.border = _D.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9945FF).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tint.withValues(alpha: 0.96), const Color(0xE6121216)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border, width: 0.8),
              ),
              child: child,
            ),
            const Positioned(
              top: 0,
              left: 18,
              right: 18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                  child: SizedBox(height: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  final Color border;
  final double size;

  const _MiniIcon({
    required this.icon,
    required this.color,
    required this.tint,
    required this.border,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11), border: Border.all(color: border)),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color tint;
  final Color border;

  const _Pill({
    required this.label,
    required this.color,
    this.tint = const Color(0xFF1C1C22),
    this.border = _D.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
      child: Text(label, style: _sg(size: 10, weight: FontWeight.w700, color: color, spacing: 1.1)),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconAction({required this.icon, required this.onTap, this.color = _D.pink});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool compact;
  final bool loading;

  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: compact ? 40 : 48,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
        ),
        child: loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 7)],
            Text(label, style: _sg(size: 13, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _QuietButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuietButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: _sg(size: 13, weight: FontWeight.w700, color: _D.textMid)),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _D.red.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _D.red.withValues(alpha: 0.38)),
        ),
        child: Text(label, style: _sg(size: 13, weight: FontWeight.w700, color: _D.red)),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(Offset(size.width * 0.2, 40), 180, const Color(0x309945FF));
    glow(Offset(size.width + 20, size.height * 0.72), 190, const Color(0x2214F195));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: _sg(size: 13, weight: FontWeight.w600)),
      backgroundColor: _D.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _D.line)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);