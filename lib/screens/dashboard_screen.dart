
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
import '../models/mining_location.dart';
import '../services/btc_price_service.dart';
import '../services/comeback_bonus_service.dart';
import '../services/daily_boost_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/game_state_service.dart';
import '../services/goals_service.dart';
import '../services/login_streak_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/progression_service.dart';
import '../services/random_drop_service.dart';
import '../services/referral_service.dart';
import '../services/season_service.dart';
import '../services/weekly_challenge_service.dart';
import '../widgets/btc_price_chart.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/screen_ad_slot.dart';
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';
import '../theme/solana.dart';
import '../widgets/app_brand_logo.dart';
import '../widgets/solana_widgets.dart';
import 'home_dashboard_content.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
// Backgrounds
static const pageBg     = Color(0xFF08080A);
static const surface    = Color(0xFF18181C);
static const surfaceAlt = Color(0xFF111114);
static const chipBg     = Color(0xFF1C1C22);

// Borders & Glass
static const border     = Color(0x1FFFFFFF);
static const borderSub  = Color(0x14FFFFFF);
static const glassBorder = Color(0x2DFFFFFF);

// Solana purple
static const amber      = Color(0xFF9945FF);
static const amberText  = Color(0xFFE9D5FF);
static const amberBg    = Color(0xFF1A1228);
static const amberBdr   = Color(0x669945FF);

// Solana green
static const green      = Color(0xFF14F195);
static const greenText  = Color(0xFFBBF7D0);
static const greenBg    = Color(0xFF0A2E22);
static const greenBdr   = Color(0x6614F195);

// Sky
static const blue       = Color(0xFF38BDF8);
static const blueText   = Color(0xFFBAE6FD);
static const blueBg     = Color(0xFF0C1A24);
static const blueBdr    = Color(0xFF164E63);

// Violet
static const violet     = Color(0xFFA78BFA);
static const violetText = Color(0xFFDDD6FE);
static const violetBg   = Color(0xFF1A1228);
static const violetBdr  = Color(0xFF4C1D95);

// Rose
static const rose       = Color(0xFFF43F5E);
static const roseBg     = Color(0xFF3F1219);
static const roseBdr    = Color(0xFF881337);

// Text
static const ink        = Color(0xFFF4F4F5);
static const inkMid     = Color(0xFFA1A1AA);
static const inkFaint   = Color(0xFF71717A);

// Radii
static const r8  = BorderRadius.all(Radius.circular(8));
static const r10 = BorderRadius.all(Radius.circular(10));
static const r12 = BorderRadius.all(Radius.circular(12));
static const r16 = BorderRadius.all(Radius.circular(16));
static const r20 = BorderRadius.all(Radius.circular(20));
static const r24 = BorderRadius.all(Radius.circular(24));
static const r28 = BorderRadius.all(Radius.circular(28));

// Spacing
static const px  = 20.0;
static const gap = 12.0;
static const sec = 28.0;
}

// ─── Typography (Space Grotesk) ───────────────────────────────────────────────
TextStyle _label({
double size = 13,
FontWeight weight = FontWeight.w400,
Color color = _T.ink,
double? letterSpacing,
double? height,
}) => GoogleFonts.spaceGrotesk(
fontSize: size,
fontWeight: weight,
color: color,
letterSpacing: letterSpacing ?? -0.2,
height: height,
);

TextStyle _mono({
double size = 13,
FontWeight weight = FontWeight.w400,
Color color = _T.ink,
}) => GoogleFonts.spaceMono(
fontSize: size,
fontWeight: weight,
color: color,
letterSpacing: -0.3,
);

// ─── Glassmorphism decoration ──────────────────────────────────────────────────
BoxDecoration _glass({
Color? bg,
Gradient? gradient,
Color? border,
BorderRadius? radius,
double opacity = 0.1,
List<BoxShadow>? shadows,
}) => BoxDecoration(
color: gradient == null ? (bg?.withOpacity(opacity) ?? _T.surface.withOpacity(0.1)) : null,
gradient: gradient,
borderRadius: radius ?? _T.r20,
border: Border.all(color: border ?? _T.glassBorder, width: 1),
boxShadow: shadows ?? [
BoxShadow(
color: Colors.white.withOpacity(0.08),
blurRadius: 16,
offset: const Offset(0, 4),
spreadRadius: 0,
),
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 24,
offset: const Offset(0, 8),
spreadRadius: -2,
),
],
);

// ─── Card decoration ──────────────────────────────────────────────────────────
BoxDecoration _card({
Color? bg,
Gradient? gradient,
Color? border,
BorderRadius? radius,
List<BoxShadow>? shadows,
}) => BoxDecoration(
color: gradient == null ? (bg ?? _T.surface) : null,
gradient: gradient,
borderRadius: radius ?? _T.r20,
border: Border.all(color: border ?? _T.glassBorder, width: 0.8),
boxShadow: shadows ?? [
BoxShadow(
color: Colors.white.withOpacity(0.06),
blurRadius: 16,
offset: const Offset(0, 4),
),
BoxShadow(
color: Colors.black.withOpacity(0.15),
blurRadius: 24,
offset: const Offset(0, 8),
),
],
);

class _NoBlur extends StatelessWidget {
  const _NoBlur({required this.filter, required this.child, this.blendMode});
  final ImageFilter filter;
  final Widget child;
  final BlendMode? blendMode;
  @override
  Widget build(BuildContext context) => child;
}

// ─── Glass container helper ───────────────────────────────────────────────────
class _GlassContainer extends StatelessWidget {
final Widget child;
final EdgeInsets padding;
final BorderRadius? radius;
final double opacity;
final Color? tintColor;

const _GlassContainer({
required this.child,
this.padding = const EdgeInsets.all(16),
this.radius,
this.opacity = 0.08,
this.tintColor,
});

@override
Widget build(BuildContext context) {
return Container(
decoration: BoxDecoration(
color: (tintColor ?? _T.surface).withOpacity(0.82),
borderRadius: radius ?? _T.r20,
border: Border.all(color: _T.glassBorder, width: 0.8),
),
padding: padding,
child: child,
);
}
}

// ─── Main screen ──────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
const DashboardScreen({super.key});
@override
State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
with SingleTickerProviderStateMixin {
late final AnimationController _pulse;

@override
void initState() {
super.initState();
_pulse = AnimationController(
vsync: this,
duration: const Duration(seconds: 5),
)..repeat(reverse: true);
WidgetsBinding.instance.addPostFrameCallback((_) {
context.read<BtcPriceService>().fetchAll();
final sessions = context.read<GameStateService>().totalSessionsStarted;
context.read<WeeklyChallengeService>().load(sessions);
});
}

@override
void dispose() {
_pulse.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final game            = context.read<GameStateService>();
final btcPrice        = context.watch<BtcPriceService>();
final progression     = context.watch<ProgressionService>();
final dailyBoost      = context.watch<DailyBoostService>();
final drop            = context.watch<RandomDropService>();
final energy          = context.read<EnergyCoolingService>();
final adCfg           = context.watch<AdRemoteConfigService>();
final loginStreak     = context.watch<LoginStreakService>();
final weeklyChallenge = context.watch<WeeklyChallengeService>();
final goals           = context.watch<GoalsService>();
final comeback        = context.watch<ComebackBonusService>();
final referral        = context.watch<ReferralService>();
final season          = context.watch<SeasonService>();
final spin            = context.watch<LuckySpinService>();
final premium         = context.select<GameStateService, bool>((g) => g.isPremiumActive);

return Scaffold(
backgroundColor: _T.pageBg,
body: SafeArea(
child: CustomScrollView(
physics: const AlwaysScrollableScrollPhysics(),
cacheExtent: 400,
slivers: [
// ── App bar ────────────────────────────────────────────────────
SliverAppBar(
pinned: true,
elevation: 0,
backgroundColor: _T.pageBg,
surfaceTintColor: Colors.transparent,
toolbarHeight: 68,
flexibleSpace: Container(
decoration: BoxDecoration(
color: _T.pageBg,
border: Border(
bottom: BorderSide(color: _T.glassBorder, width: 0.8),
),
),
),
title: Row(children: [
_AppBarLogo(),
const SizedBox(width: 14),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text('Mining Tycoon',
style: _label(size: 18, weight: FontWeight.w700, letterSpacing: -0.5)),
const SizedBox(height: 2),
Text('DASHBOARD',
style: _label(
size: 10,
weight: FontWeight.w600,
color: _T.amber,
letterSpacing: 1.2,
)),
],
),
]),
actions: [
if (game.syncInProgress)
Padding(
padding: const EdgeInsets.only(right: 8),
child: SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(strokeWidth: 2, color: _T.amber),
),
),
_AppBarAction(
icon: Icons.person_outline_rounded,
onTap: () => Navigator.pushNamed(context, '/profile'),
),
const SizedBox(width: _T.px),
],
),

SliverPadding(
padding: EdgeInsets.fromLTRB(_T.px, 24, _T.px, AppTheme.pageBottomPadding(context)),
sliver: SliverList(delegate: SliverChildListDelegate([
_LiveMiningBlock(pulse: _pulse),
if (!premium && adCfg.shouldShowSdkAds) ...[
  const SizedBox(height: 16),
  const ScreenAdSlot(title: 'Home offer'),
],
const SizedBox(height: _T.sec),

// ── SOL Market ───────────────────────────────────────────
FadeSlideIn(
delay: const Duration(milliseconds: 120),
child: const _SectionHeader(label: 'SOL Market'),
),
const SizedBox(height: 14),
FadeSlideIn(
delay: const Duration(milliseconds: 135),
child: _GlassContainer(
child: HomeGraphCard(priceService: btcPrice),
),
),
const SizedBox(height: _T.sec),

// ── Quick actions ────────────────────────────────────────
FadeSlideIn(
delay: const Duration(milliseconds: 150),
child: const _SectionHeader(label: 'Quick Actions'),
),
const SizedBox(height: 14),
FadeSlideIn(
delay: const Duration(milliseconds: 165),
child: _QuickActionsRow(context: context),
),
const SizedBox(height: _T.sec),

// ── Bonuses ──────────────────────────────────────────────
FadeSlideIn(
delay: const Duration(milliseconds: 180),
child: const _SectionHeader(label: 'Bonuses & Rewards'),
),
const SizedBox(height: 14),

if (comeback.canClaim) ...[
FadeSlideIn(
delay: const Duration(milliseconds: 195),
child: _ComebackBanner(comeback: comeback, game: game),
),
const SizedBox(height: _T.gap),
],

FadeSlideIn(
delay: const Duration(milliseconds: 210),
child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
Expanded(child: _DailyBoostCard(dailyBoost: dailyBoost)),
const SizedBox(width: _T.gap),
Expanded(child: _LoginStreakCard(loginStreak: loginStreak, game: game)),
]),
),
const SizedBox(height: _T.gap),

FadeSlideIn(
delay: const Duration(milliseconds: 225),
child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
Expanded(child: _WeeklyChallengeCard(weeklyChallenge: weeklyChallenge, game: game)),
const SizedBox(width: _T.gap),
Expanded(child: _GoalsCard(goals: goals, game: game)),
]),
),
const SizedBox(height: _T.gap),

FadeSlideIn(
delay: const Duration(milliseconds: 240),
child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
Expanded(child: _SpinCard(spin: spin)),
const SizedBox(width: _T.gap),
Expanded(child: _ReferralCard(referral: referral)),
]),
),
const SizedBox(height: _T.gap),

FadeSlideIn(
delay: const Duration(milliseconds: 255),
child: _SeasonCard(season: season, game: game),
),
const SizedBox(height: _T.sec),

// ── Operations ───────────────────────────────────────────
FadeSlideIn(
delay: const Duration(milliseconds: 270),
child: const _SectionHeader(label: 'Operations'),
),
const SizedBox(height: 14),

FadeSlideIn(
delay: const Duration(milliseconds: 285),
child: _EnergyCard(energy: energy),
),
const SizedBox(height: _T.gap),

FadeSlideIn(
delay: const Duration(milliseconds: 300),
child: _LocationsCard(progression: progression),
),
const SizedBox(height: _T.sec),

// ── Hidden drop ──────────────────────────────────────────
if (drop.isAvailable) ...[
FadeSlideIn(
delay: const Duration(milliseconds: 315),
child: const _SectionHeader(label: 'Hidden Drop'),
),
const SizedBox(height: 14),
FadeSlideIn(
delay: const Duration(milliseconds: 330),
child: _DropCard(drop: drop, game: game),
),
const SizedBox(height: _T.sec),
],

// ── Discover ─────────────────────────────────────────────
FadeSlideIn(
delay: const Duration(milliseconds: 345),
child: const _SectionHeader(label: 'Discover'),
),
const SizedBox(height: 14),

FadeSlideIn(
delay: const Duration(milliseconds: 360),
child: const _NewsCard(),
),

if (adCfg.canShowWebsiteRedirect) ...[
const SizedBox(height: _T.gap),
FadeSlideIn(
delay: const Duration(milliseconds: 375),
child: _WebsiteCard(adCfg: adCfg),
),
],
const SizedBox(height: _T.sec),

// ── How it works ─────────────────────────────────────────
FadeSlideIn(
delay: const Duration(milliseconds: 390),
child: const _SectionHeader(label: 'How It Works'),
),
const SizedBox(height: 14),

FadeSlideIn(
delay: const Duration(milliseconds: 405),
child: const Column(children: [
HomeHowMiningWorksCard(),
SizedBox(height: 10),
HomeMiningRewardCard(),
SizedBox(height: 10),
HomeSecurityCard(),
SizedBox(height: 10),
HomeTransparencyCard(),
]),
),
const SizedBox(height: 18),

FadeSlideIn(
delay: const Duration(milliseconds: 420),
child: const HomeTestimonialsCard(),
),
const SizedBox(height: 18),

FadeSlideIn(
delay: const Duration(milliseconds: 435),
child: const HomeFaqCard(),
),
])),
),
],
),
),
);
}
}

class _LiveMiningBlock extends StatelessWidget {
  const _LiveMiningBlock({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final btcPrice = context.watch<BtcPriceService>();
    final dailyBoost = context.watch<DailyBoostService>();
    final idle = game.getIdleEarnedIfAny();
    final worthUsd = btcPrice.balanceWorthUsd(game.btcBalance);
    return Column(
      children: [
        if (idle != null && idle > 0) ...[
          _IdleBanner(idle: idle),
          const SizedBox(height: 18),
        ],
        _BalanceHero(
          btcBalance: game.btcBalance,
          worthUsd: worthUsd,
          btcPerMin: game.totalBtcPerMin,
          isBoostActive: dailyBoost.isActive,
          isSessionActive: game.isSessionActive,
          sessionTimeLeft: game.sessionTimeLeft,
          pulse: pulse,
        ),
        SizedBox(height: AppTheme.cardSpacing + 4),
        _MineCTA(
          isActive: game.isSessionActive,
          onTap: () async {
            if (!game.isSessionActive) {
              await game.startMiningSession();
            }
            if (context.mounted) Navigator.pushNamed(context, '/farm');
          },
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: _T.gap,
          crossAxisSpacing: _T.gap,
          childAspectRatio: 2.2,
          children: [
            _StatCard(
              icon: Icons.memory_rounded,
              iconColor: _T.blue,
              iconBg: _T.blueBg,
              iconBdr: _T.blueBdr,
              label: 'Active rigs',
              value: '${game.ownedRigIds.length}',
            ),
            _StatCard(
              icon: Icons.factory_rounded,
              iconColor: _T.amber,
              iconBg: _T.amberBg,
              iconBdr: _T.amberBdr,
              label: 'Farm tier',
              value: game.currentFarmTier.name,
            ),
            _StatCard(
              icon: Icons.savings_rounded,
              iconColor: _T.green,
              iconBg: _T.greenBg,
              iconBdr: _T.greenBdr,
              label: 'Lifetime mined',
              value: '${game.lifetimeMinedBtc.toStringAsFixed(4)} SOL',
            ),
            _StatCard(
              icon: Icons.bolt_rounded,
              iconColor: _T.violet,
              iconBg: _T.violetBg,
              iconBdr: _T.violetBdr,
              label: 'Rate / min',
              value: '${game.totalBtcPerMin.toStringAsFixed(6)} SOL',
            ),
          ],
        ),
      ],
    );
  }
}

// ─── App bar logo ─────────────────────────────────────────────────────────────
class _AppBarLogo extends StatelessWidget {
@override
Widget build(BuildContext context) => const AppBrandLogo(size: 42, circular: true);
}

// ─── App bar action button ────────────────────────────────────────────────────
class _AppBarAction extends StatelessWidget {
final IconData icon;
final VoidCallback onTap;
const _AppBarAction({required this.icon, required this.onTap});

@override
Widget build(BuildContext context) => GestureDetector(
onTap: onTap,
child: ClipRRect(
borderRadius: _T.r12,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
child: Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: _T.surface.withOpacity(0.12),
borderRadius: _T.r12,
border: Border.all(color: _T.glassBorder, width: 0.8),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 8,
offset: const Offset(0, 2),
)
],
),
child: Icon(icon, color: _T.inkMid, size: 18),
),
),
),
);
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
final String label;
const _SectionHeader({required this.label});

@override
Widget build(BuildContext context) => Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Container(
width: 2.5,
height: 16,
margin: const EdgeInsets.only(right: 11),
decoration: BoxDecoration(
color: _T.amber,
borderRadius: BorderRadius.circular(2),
boxShadow: [
BoxShadow(
color: _T.amber.withOpacity(0.4),
blurRadius: 8,
offset: const Offset(0, 2),
)
],
),
),
Text(
label.toUpperCase(),
style: _label(
size: 11,
weight: FontWeight.w700,
color: _T.inkMid,
letterSpacing: 1.4,
),
),
],
);
}

// ─── Idle banner ──────────────────────────────────────────────────────────────
class _IdleBanner extends StatelessWidget {
final double idle;
const _IdleBanner({required this.idle});

@override
Widget build(BuildContext context) => ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
decoration: _glass(
bg: _T.amber,
border: _T.amberBdr,
opacity: 0.1,
shadows: [
BoxShadow(
color: _T.amber.withOpacity(0.2),
blurRadius: 20,
offset: const Offset(0, 6),
),
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 16,
offset: const Offset(0, 4),
),
],
),
child: Row(children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: _T.amber.withOpacity(0.18),
borderRadius: BorderRadius.circular(11),
border: Border.all(color: _T.amberBdr, width: 1),
),
child: const Icon(Icons.notifications_active_rounded,
color: _T.amber, size: 18),
),
const SizedBox(width: 13),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Welcome back!',
style: _label(
size: 14,
weight: FontWeight.w700,
color: _T.amberText,
)),
const SizedBox(height: 2),
Text('Miners earned +${idle.toStringAsFixed(8)} SOL while away',
style: _label(size: 12, color: _T.amber)),
],
),
),
const SizedBox(width: 6),
Icon(Icons.chevron_right_rounded,
color: _T.amber.withOpacity(0.4), size: 20),
]),
),
),
);
}

// ─── Balance hero card ────────────────────────────────────────────────────────
class _BalanceHero extends StatelessWidget {
final double btcBalance;
final double? worthUsd;
final double btcPerMin;
final bool isBoostActive, isSessionActive;
final Duration sessionTimeLeft;
final AnimationController pulse;

const _BalanceHero({
required this.btcBalance,
required this.worthUsd,
required this.btcPerMin,
required this.isBoostActive,
required this.isSessionActive,
required this.sessionTimeLeft,
required this.pulse,
});

@override
Widget build(BuildContext context) {
final intPart = btcBalance.floor().toString();
final decPart = '.${btcBalance.toStringAsFixed(12).split('.')[1]}';

return ClipRRect(
borderRadius: _T.r28,
child: Container(
decoration: BoxDecoration(
borderRadius: _T.r28,
gradient: Solana.brand,
boxShadow: [
BoxShadow(
color: _T.amber.withOpacity(0.3),
blurRadius: 40,
offset: const Offset(0, 20),
),
BoxShadow(
color: _T.green.withOpacity(0.1),
blurRadius: 80,
offset: const Offset(-20, -20),
),
],
),
padding: const EdgeInsets.all(1.5),
child: Container(
decoration: const BoxDecoration(
gradient: Solana.cardWash,
borderRadius: BorderRadius.all(Radius.circular(27)),
),
clipBehavior: Clip.hardEdge,
child: Stack(children: [
// Ambient glow
Positioned(
top: -100,
right: -100,
child: AnimatedBuilder(
animation: pulse,
builder: (_, __) => Container(
width: 280,
height: 280,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: RadialGradient(colors: [
_T.amber.withOpacity(0.08 + 0.06 * pulse.value),
Colors.transparent,
]),
),
),
),
),

// Dot texture
Positioned.fill(child: CustomPaint(painter: _DotTexture())),

Padding(
padding: const EdgeInsets.all(26),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Header row
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(children: [
Container(
width: 32,
height: 32,
decoration: BoxDecoration(
color: _T.amberBg,
borderRadius: BorderRadius.circular(10),
border: Border.all(color: _T.amberBdr, width: 1),
),
child: const Icon(Icons.hexagon_rounded,
color: _T.amber, size: 16),
),
const SizedBox(width: 11),
Text('SOL BALANCE',
style: _label(
size: 11,
weight: FontWeight.w600,
color: _T.inkMid,
letterSpacing: 1.8,
)),
]),
Row(children: [
if (isBoostActive)
_StatusPill(
label: '2× BOOST',
color: _T.amber,
bg: _T.amberBg,
border: _T.amberBdr,
textColor: _T.amberText,
),
if (isBoostActive && isSessionActive)
const SizedBox(width: 7),
if (isSessionActive)
_StatusPill(
label: 'LIVE',
color: _T.green,
bg: _T.greenBg,
border: _T.greenBdr,
textColor: _T.greenText,
),
]),
],
),

const SizedBox(height: 28),

// Balance display
FittedBox(
fit: BoxFit.scaleDown,
alignment: Alignment.centerLeft,
child: Row(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
Text(
intPart,
style: GoogleFonts.spaceGrotesk(
fontSize: 48,
fontWeight: FontWeight.w700,
color: _T.ink,
height: 1.0,
letterSpacing: -1.5,
),
),
Padding(
padding: const EdgeInsets.only(bottom: 6),
child: Text(
decPart,
style: GoogleFonts.spaceMono(
fontSize: 16,
fontWeight: FontWeight.w500,
color: _T.amber,
height: 1.0,
),
),
),
Padding(
padding: const EdgeInsets.only(bottom: 8, left: 9),
child: Text('SOL',
style: _label(
size: 13,
weight: FontWeight.w600,
color: _T.inkMid,
letterSpacing: 0.8,
)),
),
],
),
),

const SizedBox(height: 6),
Text(
worthUsd != null
? '≈ \$${worthUsd!.toStringAsFixed(2)} USD'
    : '≈ — USD',
style: _label(size: 13, color: _T.inkMid),
),

const SizedBox(height: 24),
Container(
height: 0.8,
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
_T.border,
_T.border.withOpacity(0),
_T.border,
],
),
),
),
const SizedBox(height: 20),

// Footer row
Row(children: [
_PulseDot(),
const SizedBox(width: 9),
Text(
'${btcPerMin.toStringAsFixed(8)} SOL/min',
style: _mono(
size: 12,
weight: FontWeight.w500,
color: _T.green,
),
),
const Spacer(),
if (isSessionActive) ...[
Icon(Icons.timer_outlined,
color: _T.inkFaint, size: 13),
const SizedBox(width: 6),
Text(
'${sessionTimeLeft.inMinutes}:${(sessionTimeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
style: _mono(size: 12, color: _T.inkMid),
),
],
]),
],
),
),
]),
),
),
);
}
}

// ─── Dot texture painter ──────────────────────────────────────────────────────
class _DotTexture extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()..color = const Color(0xFF000000).withOpacity(0.018);
const step = 20.0;
for (double x = 0; x < size.width; x += step) {
for (double y = 0; y < size.height; y += step) {
canvas.drawCircle(Offset(x, y), 0.8, paint);
}
}
}

@override
bool shouldRepaint(_) => false;
}

// ─── Status pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
final String label;
final Color color, bg, border, textColor;

const _StatusPill({
required this.label,
required this.color,
required this.bg,
required this.border,
required this.textColor,
});

@override
Widget build(BuildContext context) => Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
decoration: BoxDecoration(
color: bg,
borderRadius: BorderRadius.circular(7),
border: Border.all(color: border, width: 0.8),
),
child: Text(
label,
style: _label(
size: 9,
weight: FontWeight.w700,
color: textColor,
letterSpacing: 0.8,
),
),
);
}

// ─── Pulse dot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
@override
State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
late final AnimationController _c = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 1400),
)..repeat(reverse: true);

@override
void dispose() {
_c.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) => AnimatedBuilder(
animation: _c,
builder: (_, __) => Container(
width: 8,
height: 8,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: _T.green,
boxShadow: [
BoxShadow(
color: _T.green.withOpacity(0.25 + 0.35 * _c.value),
blurRadius: 6 + 8 * _c.value,
spreadRadius: _c.value * 0.8,
)
],
),
),
);
}

// ─── Mine CTA ─────────────────────────────────────────────────────────────────
class _MineCTA extends StatefulWidget {
final bool isActive;
final VoidCallback onTap;

const _MineCTA({required this.isActive, required this.onTap});

@override
State<_MineCTA> createState() => _MineCTAState();
}

class _MineCTAState extends State<_MineCTA> {
bool _isPressed = false;

@override
Widget build(BuildContext context) {
final bg = widget.isActive ? _T.greenBg : _T.amberBg;
final border = widget.isActive ? _T.greenBdr : _T.amberBdr;
final ic = widget.isActive ? _T.green : _T.amber;
final tc = widget.isActive ? _T.greenText : _T.amberText;

return GestureDetector(
onTapDown: (_) => setState(() => _isPressed = true),
onTapUp: (_) => setState(() => _isPressed = false),
onTapCancel: () => setState(() => _isPressed = false),
onTap: widget.onTap,
child: Transform.scale(
scale: _isPressed ? 0.96 : 1.0,
child: ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
height: 58,
decoration: _glass(
bg: bg,
border: border,
radius: _T.r20,
opacity: 0.12,
shadows: [
BoxShadow(
color: ic.withOpacity(0.15),
blurRadius: 20,
offset: const Offset(0, 6),
),
],
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 32,
height: 32,
decoration: BoxDecoration(
color: ic.withOpacity(0.16),
borderRadius: BorderRadius.circular(10),
border: Border.all(color: ic.withOpacity(0.3), width: 0.8),
),
child: Icon(
widget.isActive
? Icons.bolt_rounded
    : Icons.play_arrow_rounded,
color: ic,
size: 17,
),
),
const SizedBox(width: 11),
Text(
widget.isActive
? 'Session running — View farm'
    : 'Start mining session',
style: _label(
size: 15,
weight: FontWeight.w600,
color: tc,
letterSpacing: -0.2,
),
),
const SizedBox(width: 9),
Icon(Icons.arrow_forward_rounded,
color: ic.withOpacity(0.3), size: 16),
],
),
),
),
),
),
);
}
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
final IconData icon;
final Color iconColor, iconBg, iconBdr;
final String label, value;

const _StatCard({
required this.icon,
required this.iconColor,
required this.iconBg,
required this.iconBdr,
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) => Container(
width: double.infinity,
height: double.infinity,
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
decoration: BoxDecoration(
color: _T.surface.withOpacity(0.82),
borderRadius: _T.r20,
border: Border.all(color: _T.glassBorder, width: 0.8),
),
child: Row(children: [
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: iconBg,
borderRadius: BorderRadius.circular(11),
border: Border.all(color: iconBdr, width: 0.8),
),
child: Icon(icon, color: iconColor, size: 18),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(label,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: _label(size: 11, color: _T.inkMid, weight: FontWeight.w500)),
const SizedBox(height: 4),
Text(
value,
style: _label(size: 13, weight: FontWeight.w700),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
],
),
),
]),
);
}

// ─── Quick actions row ────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
final BuildContext context;

const _QuickActionsRow({required this.context});

@override
Widget build(BuildContext ctx) {
final items = [
(Icons.account_balance_wallet_outlined, 'Wallet', _T.blue, _T.blueBg,
_T.blueBdr, '/profile'),
(Icons.payments_outlined, 'Withdraw', _T.green, _T.greenBg, _T.greenBdr,
'/profile'),
(Icons.group_add_outlined, 'Invite', _T.violet, _T.violetBg,
_T.violetBdr, '/profile'),
(Icons.show_chart_rounded, 'Stats', _T.amber, _T.amberBg, _T.amberBdr,
'/farm'),
];

return Row(
children: List.generate(items.length, (i) {
final item = items[i];
return Expanded(
child: Padding(
padding: EdgeInsets.only(right: i < items.length - 1 ? _T.gap : 0),
child: GestureDetector(
onTap: () => Navigator.pushNamed(context, item.$6),
child: _GlassContainer(
radius: _T.r20,
opacity: 0.08,
padding: const EdgeInsets.symmetric(vertical: 20),
child: Column(children: [
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: item.$4,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: item.$5, width: 0.8),
boxShadow: [
BoxShadow(
color: item.$3.withOpacity(0.12),
blurRadius: 12,
offset: const Offset(0, 3),
)
],
),
child: Icon(item.$1, color: item.$3, size: 18),
),
const SizedBox(height: 11),
Text(item.$2,
style: _label(size: 12, weight: FontWeight.w600)),
]),
),
),
),
);
}),
);
}
}

// ─── Comeback banner ──────────────────────────────────────────────────────────
class _ComebackBanner extends StatelessWidget {
final ComebackBonusService comeback;
final GameStateService game;

const _ComebackBanner({required this.comeback, required this.game});

@override
Widget build(BuildContext context) => ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
decoration: _glass(
bg: _T.amber,
border: _T.amberBdr,
radius: _T.r20,
opacity: 0.1,
shadows: [
BoxShadow(
color: _T.amber.withOpacity(0.2),
blurRadius: 24,
offset: const Offset(0, 8),
),
],
),
child: Row(children: [
const Text('👋', style: TextStyle(fontSize: 28)),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Welcome back!',
style: _label(
size: 15,
weight: FontWeight.w700,
color: _T.amberText,
)),
const SizedBox(height: 2),
Text(
'+${MiningEconomy.toSol(ComebackBonusService.bonusBtc).toStringAsFixed(4)} SOL waiting for you',
style: _label(size: 13, weight: FontWeight.w500, color: _T.amber),
),
],
),
),
const SizedBox(width: 13),
_ActionChip(
label: 'Claim',
textColor: _T.amberText,
bg: _T.amber.withOpacity(0.14),
border: _T.amberBdr,
onTap: () async {
await game.grantDirectBtc(ComebackBonusService.bonusBtc);
await comeback.markClaimed();
if (context.mounted)
_showToast(context, '🎁 Welcome back bonus claimed!');
},
),
]),
),
),
);
}

// ─── Bonus mini card ──────────────────────────────────────────────────────────
class _BonusMini extends StatelessWidget {
final IconData icon;
final Color iconColor, iconBg, iconBdr;
final String title, subtitle;
final String? badge;
final Color? badgeBg, badgeBdr, badgeTextColor;
final double? progress;
final Color? progressColor;
final VoidCallback? onTap;

const _BonusMini({
required this.icon,
required this.iconColor,
required this.iconBg,
required this.iconBdr,
required this.title,
required this.subtitle,
this.badge,
this.badgeBg,
this.badgeBdr,
this.badgeTextColor,
this.progress,
this.progressColor,
this.onTap,
});

@override
Widget build(BuildContext context) {
final isActive = badge != null && onTap != null;

return GestureDetector(
onTap: onTap,
child: ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(16),
decoration: _glass(
border: isActive ? (badgeBdr ?? _T.amberBdr) : _T.glassBorder,
radius: _T.r20,
opacity: 0.08,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: iconBg,
borderRadius: BorderRadius.circular(11),
border: Border.all(color: iconBdr, width: 0.8),
),
child: Icon(icon, color: iconColor, size: 17),
),
if (badge != null)
Container(
padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
decoration: BoxDecoration(
color: badgeBg ?? _T.amberBg,
borderRadius: BorderRadius.circular(7),
border: Border.all(
color: badgeBdr ?? _T.amberBdr, width: 0.8),
),
child: Text(
badge!,
style: _label(
size: 9,
weight: FontWeight.w700,
color: badgeTextColor ?? _T.amberText,
letterSpacing: 0.7,
),
),
),
],
),
const SizedBox(height: 13),
Text(title,
style: _label(size: 14, weight: FontWeight.w700)),
const SizedBox(height: 3),
Text(subtitle,
style: _label(size: 12, color: _T.inkMid, weight: FontWeight.w500)),
if (progress != null) ...[
const SizedBox(height: 11),
ClipRRect(
borderRadius: BorderRadius.circular(3),
child: LinearProgressIndicator(
value: progress!.clamp(0.0, 1.0),
minHeight: 3.5,
backgroundColor: _T.chipBg.withOpacity(0.5),
valueColor: AlwaysStoppedAnimation(
progressColor ?? _T.amber),
),
),
],
],
),
),
),
),
);
}
}

// ─── Individual bonus cards ───────────────────────────────────────────────────
class _DailyBoostCard extends StatelessWidget {
final DailyBoostService dailyBoost;

const _DailyBoostCard({required this.dailyBoost});

@override
Widget build(BuildContext context) {
final ready = dailyBoost.canClaim;
return _BonusMini(
icon: Icons.bolt_rounded,
iconColor: _T.amber,
iconBg: _T.amberBg,
iconBdr: _T.amberBdr,
title: 'Daily boost',
subtitle: ready ? '2× speed ready!' : 'Resets in 24h',
badge: ready ? 'READY' : null,
badgeBg: _T.amberBg,
badgeBdr: _T.amberBdr,
badgeTextColor: _T.amberText,
onTap: ready
? () async {
final ok = await dailyBoost.claim();
if (ok && context.mounted)
_showToast(context, '⚡ 2× boost activated!');
}
    : null,
);
}
}

class _LoginStreakCard extends StatelessWidget {
final LoginStreakService loginStreak;
final GameStateService game;

const _LoginStreakCard({required this.loginStreak, required this.game});

@override
Widget build(BuildContext context) {
final days = loginStreak.streakDays;
final can = loginStreak.canClaimStreak3 || loginStreak.canClaimStreak7;

return _BonusMini(
icon: Icons.local_fire_department_rounded,
iconColor: _T.rose,
iconBg: _T.roseBg,
iconBdr: _T.roseBdr,
title: 'Login streak',
subtitle: days == 0 ? 'Come back tomorrow' : '$days day${days == 1 ? '' : 's'} 🔥',
badge: can ? 'CLAIM' : null,
badgeBg: _T.greenBg,
badgeBdr: _T.greenBdr,
badgeTextColor: _T.greenText,
onTap: can
? () async {
if (loginStreak.canClaimStreak7) {
await game.grantDirectBtc(0.00003);
await loginStreak.markStreak7Claimed();
if (context.mounted)
_showToast(context, '🔥 7-day reward!');
} else {
await game.grantDirectBtc(0.00001);
await loginStreak.markStreak3Claimed();
if (context.mounted)
_showToast(context, '🔥 3-day reward!');
}
}
    : null,
);
}
}

class _WeeklyChallengeCard extends StatelessWidget {
final WeeklyChallengeService weeklyChallenge;
final GameStateService game;

const _WeeklyChallengeCard(
{required this.weeklyChallenge, required this.game});

@override
Widget build(BuildContext context) {
final prog = weeklyChallenge.progressThisWeek(game.totalSessionsStarted);
final can = weeklyChallenge.canClaim(game.totalSessionsStarted);

return _BonusMini(
icon: Icons.emoji_events_rounded,
iconColor: _T.violet,
iconBg: _T.violetBg,
iconBdr: _T.violetBdr,
title: 'Weekly',
subtitle: '$prog/${WeeklyChallengeService.targetSessions} sessions',
badge: can ? 'CLAIM' : '$prog/${WeeklyChallengeService.targetSessions}',
badgeBg: can ? _T.greenBg : _T.violetBg,
badgeBdr: can ? _T.greenBdr : _T.violetBdr,
badgeTextColor: can ? _T.greenText : _T.violetText,
progress:
prog / WeeklyChallengeService.targetSessions,
progressColor: _T.violet,
onTap: can
? () async {
await game.grantDirectBtc(
WeeklyChallengeService.rewardBtc);
await weeklyChallenge.markClaimed();
if (context.mounted)
_showToast(context, '🏆 Weekly reward!');
}
    : null,
);
}
}

class _GoalsCard extends StatelessWidget {
final GoalsService goals;
final GameStateService game;

const _GoalsCard({required this.goals, required this.game});

@override
Widget build(BuildContext context) {
final can = goals.canClaimDaily || goals.canClaimWeekly;

return _BonusMini(
icon: Icons.flag_rounded,
iconColor: _T.blue,
iconBg: _T.blueBg,
iconBdr: _T.blueBdr,
title: 'Daily goals',
subtitle: '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}% mined',
badge: can
? 'CLAIM'
    : '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}%',
badgeBg: can ? _T.greenBg : _T.blueBg,
badgeBdr: can ? _T.greenBdr : _T.blueBdr,
badgeTextColor: can ? _T.greenText : _T.blueText,
progress: goals.dailyProgressPercent,
progressColor: _T.blue,
onTap: can
? () async {
if (goals.canClaimDaily) {
await game.grantDirectBtc(GoalsService.dailyRewardBtc);
await goals.claimDaily();
if (context.mounted)
_showToast(context, '🎯 Daily goal reward!');
}
}
    : null,
);
}
}

class _SpinCard extends StatelessWidget {
final LuckySpinService spin;

const _SpinCard({required this.spin});

@override
Widget build(BuildContext context) => _BonusMini(
icon: Icons.casino_outlined,
iconColor: _T.violet,
iconBg: _T.violetBg,
iconBdr: _T.violetBdr,
title: 'Lucky spin',
subtitle: 'Try your luck',
badge: 'SPIN',
badgeBg: _T.violetBg,
badgeBdr: _T.violetBdr,
badgeTextColor: _T.violetText,
onTap: () => Navigator.pushNamed(context, '/spin'),
);
}

class _ReferralCard extends StatelessWidget {
final ReferralService referral;

const _ReferralCard({required this.referral});

@override
Widget build(BuildContext context) => _BonusMini(
icon: Icons.people_outline_rounded,
iconColor: _T.green,
iconBg: _T.greenBg,
iconBdr: _T.greenBdr,
title: 'Referrals',
subtitle: '${referral.friends} friends joined',
badge: 'INVITE',
badgeBg: _T.greenBg,
badgeBdr: _T.greenBdr,
badgeTextColor: _T.greenText,
onTap: () => Navigator.pushNamed(context, '/profile'),
);
}

// ─── Season card ──────────────────────────────────────────────────────────────
class _SeasonCard extends StatelessWidget {
final SeasonService season;
final GameStateService game;

const _SeasonCard({required this.season, required this.game});

@override
Widget build(BuildContext context) {
final next = SeasonService.freeMilestones
    .firstWhere((m) => m > season.xp,
orElse: () => SeasonService.freeMilestones.last);
final progress = (season.xp / next).clamp(0.0, 1.0);

return ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(20),
decoration: _glass(
bg: _T.amber,
border: _T.amberBdr,
radius: _T.r20,
opacity: 0.1,
shadows: [
BoxShadow(
color: _T.amber.withOpacity(0.15),
blurRadius: 24,
offset: const Offset(0, 8),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: _T.amber.withOpacity(0.16),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: _T.amberBdr, width: 1),
),
child: const Icon(Icons.emoji_events_rounded,
color: _T.amber, size: 21),
),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Season ${season.seasonId}',
style: _label(
size: 15,
weight: FontWeight.w700,
)),
const SizedBox(height: 2),
Text('${season.xp} / $next XP',
style: _label(size: 13, color: _T.inkMid)),
],
),
),
Text('${(progress * 100).toStringAsFixed(0)}%',
style: _label(
size: 19,
weight: FontWeight.w700,
color: _T.amber,
)),
]),
const SizedBox(height: 19),
ClipRRect(
borderRadius: BorderRadius.circular(4),
child: LinearProgressIndicator(
value: progress,
minHeight: 6,
backgroundColor: _T.amber.withOpacity(0.16),
valueColor:
const AlwaysStoppedAnimation(_T.amber),
),
),
...List.generate(SeasonService.freeMilestones.length, (i) {
if (!season.canClaimFree(i)) return const SizedBox.shrink();
return Padding(
padding: const EdgeInsets.only(top: 15),
child: _ActionChip(
label:
'${SeasonService.freeMilestones[i]} XP → +${MiningEconomy.toSol(SeasonService.freeRewardsBtc[i]).toStringAsFixed(4)} SOL',
textColor: _T.amberText,
bg: _T.amber.withOpacity(0.12),
border: _T.amberBdr,
onTap: () async {
await game.grantDirectBtc(
SeasonService.freeRewardsBtc[i]);
await season.claimFreeReward(i);
if (context.mounted)
_showToast(context, '🏆 Season reward!');
},
),
);
}),
],
),
),
),
);
}
}

// ─── Energy card ──────────────────────────────────────────────────────────────
class _EnergyCard extends StatelessWidget {
final EnergyCoolingService energy;

const _EnergyCard({required this.energy});

@override
Widget build(BuildContext context) {
final t = (energy.heat / 100).clamp(0.0, 1.0);
final heatColor = Color.lerp(_T.green, _T.rose, t)!;

return ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(18),
decoration: _glass(
radius: _T.r20,
opacity: 0.08,
),
child: Row(children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: heatColor.withOpacity(0.11),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: heatColor.withOpacity(0.25), width: 0.8),
),
child: Icon(Icons.thermostat_rounded,
color: heatColor, size: 21),
),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Energy & cooling',
style:
_label(size: 14, weight: FontWeight.w700)),
const SizedBox(height: 9),
ClipRRect(
borderRadius: BorderRadius.circular(3),
child: LinearProgressIndicator(
value: t,
minHeight: 4.5,
backgroundColor: _T.chipBg.withOpacity(0.4),
valueColor:
AlwaysStoppedAnimation(heatColor),
),
),
],
),
),
const SizedBox(width: 18),
Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
Text('${energy.heat.toStringAsFixed(0)}°',
style: _mono(
size: 24,
weight: FontWeight.w700,
color: heatColor,
)),
const SizedBox(height: 2),
Text('×${energy.efficiencyMultiplier.toStringAsFixed(2)}',
style: _mono(size: 12, color: _T.inkMid)),
],
),
]),
),
),
);
}
}

// ─── Locations card ───────────────────────────────────────────────────────────
class _LocationsCard extends StatelessWidget {
final ProgressionService progression;

const _LocationsCard({required this.progression});

@override
Widget build(BuildContext context) => ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(18),
decoration: _glass(
radius: _T.r20,
opacity: 0.08,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(children: [
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: _T.blueBg,
borderRadius: BorderRadius.circular(11),
border: Border.all(color: _T.blueBdr, width: 0.8),
),
child: const Icon(Icons.map_outlined,
color: _T.blue, size: 17),
),
const SizedBox(width: 12),
Text('Mining locations',
style: _label(size: 14, weight: FontWeight.w700)),
]),
const SizedBox(height: 17),
Wrap(
spacing: 8,
runSpacing: 8,
children: MiningLocations.all.map((loc) {
final on = progression.unlockedLocations.contains(loc.id);
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 12, vertical: 8),
decoration: BoxDecoration(
color: on ? _T.blueBg : _T.chipBg,
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: on ? _T.blueBdr : _T.borderSub,
width: 0.8,
),
),
child: Row(mainAxisSize: MainAxisSize.min, children: [
if (on) ...[
const Icon(Icons.check_circle_rounded,
color: _T.blue, size: 13),
const SizedBox(width: 6),
],
Text(
loc.name,
style: _label(
size: 12,
weight: on ? FontWeight.w600 : FontWeight.w500,
color: on ? _T.blueText : _T.inkMid,
),
),
]),
);
}).toList(),
),
],
),
),
),
);
}

// ─── Drop card ────────────────────────────────────────────────────────────────
class _DropCard extends StatelessWidget {
final RandomDropService drop;
final GameStateService game;

const _DropCard({required this.drop, required this.game});

@override
Widget build(BuildContext context) => ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(18),
decoration: _glass(
bg: _T.amber,
border: _T.amberBdr,
radius: _T.r20,
opacity: 0.1,
shadows: [
BoxShadow(
color: _T.amber.withOpacity(0.18),
blurRadius: 20,
offset: const Offset(0, 6),
),
],
),
child: Row(children: [
const Text('✨', style: TextStyle(fontSize: 28)),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Hidden crypto block!',
style: _label(
size: 15,
weight: FontWeight.w700,
color: _T.amberText,
)),
const SizedBox(height: 2),
Text('Tap to collect bonus SOL',
style: _label(size: 13, color: _T.inkMid)),
],
),
),
const SizedBox(width: 13),
_ActionChip(
label: 'Collect',
textColor: _T.amberText,
bg: _T.amber.withOpacity(0.14),
border: _T.amberBdr,
onTap: () async {
final bonus = await drop.collect();
if (bonus != null) await game.grantDirectBtc(bonus);
if (context.mounted)
_showToast(context,
'+${MiningEconomy.toSol(bonus ?? 0).toStringAsFixed(6)} SOL collected!');
},
),
]),
),
),
);
}

// ─── News card ────────────────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
const _NewsCard();

@override
Widget build(BuildContext context) => GestureDetector(
onTap: () => Navigator.pushNamed(context, '/news'),
child: ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(16),
decoration: _glass(
radius: _T.r20,
opacity: 0.08,
),
child: Row(children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: _T.amberBg,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: _T.amberBdr, width: 0.8),
),
child: const Icon(Icons.article_outlined,
color: _T.amber, size: 19),
),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Latest Solana news',
style: _label(
size: 14,
weight: FontWeight.w700,
)),
const SizedBox(height: 3),
Text('Stay updated on the Solana network',
style: _label(size: 12, color: _T.inkMid)),
],
),
),
Icon(Icons.chevron_right_rounded,
color: _T.inkFaint, size: 21),
]),
),
),
),
);
}

// ─── Website card ─────────────────────────────────────────────────────────────
class _WebsiteCard extends StatelessWidget {
final AdRemoteConfigService adCfg;

const _WebsiteCard({required this.adCfg});

@override
Widget build(BuildContext context) {
final url = adCfg.customTabUrl;
final display =
url.length > 36 ? '${url.substring(0, 36)}…' : url;

return ClipRRect(
borderRadius: _T.r20,
child: _NoBlur(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(16),
decoration: _glass(
radius: _T.r20,
opacity: 0.08,
),
child: Row(children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: _T.blueBg,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: _T.blueBdr, width: 0.8),
),
child: const Icon(Icons.open_in_browser_rounded,
color: _T.blue, size: 19),
),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Open website',
style: _label(
size: 14,
weight: FontWeight.w700,
)),
const SizedBox(height: 3),
Text(display,
style: _label(size: 12, color: _T.inkMid),
maxLines: 1,
overflow: TextOverflow.ellipsis),
],
),
),
const SizedBox(width: 11),
_ActionChip(
label: 'Open',
textColor: _T.blueText,
bg: _T.blueBg,
border: _T.blueBdr,
onTap: () => adCfg.openCustomTab(url),
),
]),
),
),
);
}
}

// ─── Action chip ──────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
final String label;
final Color textColor, bg, border;
final VoidCallback onTap;

const _ActionChip({
required this.label,
required this.textColor,
required this.bg,
required this.border,
required this.onTap,
});

@override
Widget build(BuildContext context) => GestureDetector(
onTap: onTap,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
decoration: BoxDecoration(
color: bg,
borderRadius: BorderRadius.circular(10),
border: Border.all(color: border, width: 0.8),
),
child: Text(label,
style: _label(
size: 13,
weight: FontWeight.w700,
color: textColor,
)),
),
);
}

// ─── Toast ────────────────────────────────────────────────────────────────────
void _showToast(BuildContext context, String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
message,
style: _label(size: 14, weight: FontWeight.w500, color: _T.ink),
),
backgroundColor: _T.surface,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
side: const BorderSide(color: _T.glassBorder, width: 0.8),
),
margin: const EdgeInsets.all(18),
elevation: 6,
),
);
}

