import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/btc_price_service.dart';
import '../services/game_state_service.dart';
import '../services/referral_service.dart';
import '../services/weekly_challenge_service.dart';
import '../services/lucky_spin_service.dart';
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';
import '../widgets/btc_price_chart.dart';
import '../widgets/fade_slide_in.dart';

// ─── Balance hero: BTC balance, USD below, BTC price + arrow on right ─────────
class HomeBalanceHero extends StatelessWidget {
  final double btcBalance;
  final double? worthUsd;
  final BtcPriceService priceService;

  const HomeBalanceHero({
    super.key,
    required this.btcBalance,
    this.worthUsd,
    required this.priceService,
  });

  @override
  Widget build(BuildContext context) {
    final price = priceService.priceUsd;
    final change24h = priceService.priceChange24h;
    final isUp = priceService.isPriceUp;
    final parts = btcBalance.toStringAsFixed(8).split('.');

    return Container(
      padding: const EdgeInsets.all(HomeTheme.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: HomeTheme.limeCardGradient,
        ),
        border: Border.all(color: HomeTheme.limeBorderSubtle),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.lime.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BTC MINING BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: HomeTheme.limeTextLow,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      parts[0],
                      style: HomeTheme.monoNumber(fontSize: 32, weight: FontWeight.w800).copyWith(
                        color: HomeTheme.limeTextHigh,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '.${parts[1]}',
                      style: HomeTheme.monoNumber(fontSize: 18, weight: FontWeight.w600).copyWith(
                        color: HomeTheme.lime,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'BTC',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HomeTheme.lime,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  worthUsd != null ? '≈ \$${worthUsd!.toStringAsFixed(2)} USD' : '≈ — USD',
                  style: TextStyle(fontSize: 12, color: HomeTheme.limeTextMid),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: HomeTheme.limeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HomeTheme.limeBorderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'BTC PRICE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: HomeTheme.limeTextLow),
                ),
                const SizedBox(height: 4),
                if (price != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(0)}',
                        style: HomeTheme.monoNumber(fontSize: 14, weight: FontWeight.w700).copyWith(color: HomeTheme.limeTextHigh),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                        color: isUp ? HomeTheme.limeSuccess : HomeTheme.limeDanger,
                        size: 24,
                      ),
                    ],
                  ),
                  if (change24h != null)
                    Text(
                      '${change24h >= 0 ? '+' : ''}${change24h.toStringAsFixed(2)}% 24h',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUp ? HomeTheme.limeSuccess : HomeTheme.limeDanger,
                      ),
                    ),
                ] else
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: HomeTheme.lime),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Three vertical cards: Difficulty, Network, Reward ───────────────────────
class HomeThreeStatsRow extends StatelessWidget {
  const HomeThreeStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _HomeMiniCard(title: 'Difficulty', value: '—', icon: Icons.tune_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _HomeMiniCard(title: 'Network', value: 'Mainnet', icon: Icons.lan_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _HomeMiniCard(title: 'Reward', value: '6.25 ₿', icon: Icons.emoji_events_rounded)),
      ],
    );
  }
}

class _HomeMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _HomeMiniCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        color: HomeTheme.limeSurface,
        border: Border.all(color: HomeTheme.limeBorderFaint),
      ),
      child: Column(
        children: [
          Icon(icon, color: HomeTheme.lime, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: HomeTheme.limeTextMid),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: HomeTheme.monoNumber(fontSize: 12).copyWith(color: HomeTheme.limeTextHigh, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Graph card: BTC chart with 24h, 1d, 3d, 7d and low/high/vol ─────────────
class HomeGraphCard extends StatelessWidget {
  final BtcPriceService priceService;

  const HomeGraphCard({super.key, required this.priceService});

  @override
  Widget build(BuildContext context) {
    final high = priceService.high24h;
    final low = priceService.low24h;
    final vol = priceService.volume24h;

    return Container(
      padding: const EdgeInsets.all(HomeTheme.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        color: HomeTheme.limeSurface,
        border: Border.all(color: HomeTheme.limeBorderFaint),
        boxShadow: const [BoxShadow(color: Color(0x28000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BTC Price',
                style: TextStyle(
                  color: HomeTheme.limeTextHigh,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Row(
                children: [
                  _GraphChip(label: '24H'),
                  const SizedBox(width: 6),
                  _GraphChip(label: '7D', active: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 160, child: BtcPriceChart()),
          const SizedBox(height: 12),
          Row(
            children: [
              if (low != null) _GraphStat(label: 'Low', value: '\$${low.toStringAsFixed(0)}'),
              if (low != null && high != null) const SizedBox(width: 16),
              if (high != null) _GraphStat(label: 'High', value: '\$${high.toStringAsFixed(0)}'),
              if (high != null && vol != null) const SizedBox(width: 16),
              if (vol != null) _GraphStat(label: 'Vol', value: _formatVol(vol)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatVol(double v) {
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _GraphChip extends StatelessWidget {
  final String label;
  final bool active;

  const _GraphChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? HomeTheme.lime.withOpacity(0.2) : HomeTheme.limeBorderFaint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? HomeTheme.lime : HomeTheme.limeTextMid,
        ),
      ),
    );
  }
}

class _GraphStat extends StatelessWidget {
  final String label;
  final String value;

  const _GraphStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: HomeTheme.limeTextLow)),
        Text(value, style: HomeTheme.monoNumber(fontSize: 12).copyWith(color: HomeTheme.limeTextHigh)),
      ],
    );
  }
}

// ─── Mining CTA button ───────────────────────────────────────────────────────
class HomeMiningButton extends StatelessWidget {
  final VoidCallback onTap;

  const HomeMiningButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: HomeTheme.lime,
          foregroundColor: HomeTheme.limeTextOnLime,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          'Start Mining',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

// ─── Hashrate & Est. monthly cards ───────────────────────────────────────────
class HomeHashrateCards extends StatelessWidget {
  final GameStateService game;

  const HomeHashrateCards({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final ratePerHr = game.totalBtcPerMin * 60;
    final estMonthly = ratePerHr * 24 * 30;

    return Row(
      children: [
        Expanded(
          child: _HomeStatCard(
            title: 'Hashrate',
            value: '${(game.totalBtcPerMin * 60).toStringAsFixed(6)} ₿/hr',
            icon: Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HomeStatCard(
            title: 'Est. monthly',
            value: '${estMonthly.toStringAsFixed(6)} ₿',
            icon: Icons.calendar_month_rounded,
          ),
        ),
      ],
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _HomeStatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HomeTheme.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        color: HomeTheme.limeSurface,
        border: Border.all(color: HomeTheme.limeBorderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HomeTheme.lime, size: 22),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 11, color: HomeTheme.limeTextMid)),
          const SizedBox(height: 4),
          Text(
            value,
            style: HomeTheme.monoNumber(fontSize: 13).copyWith(color: HomeTheme.limeTextHigh, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Earnings card ──────────────────────────────────────────────────────────
class HomeEarningsCard extends StatelessWidget {
  final GameStateService game;

  const HomeEarningsCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HomeTheme.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        color: HomeTheme.limeSurface,
        border: Border.all(color: HomeTheme.limeBorderFaint),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total earned', style: TextStyle(fontSize: 12, color: HomeTheme.limeTextMid)),
              const SizedBox(height: 4),
              Text(
                '${game.lifetimeMinedBtc.toStringAsFixed(6)} ₿',
                style: HomeTheme.monoNumber(fontSize: 20).copyWith(color: HomeTheme.lime, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Icon(Icons.trending_up_rounded, color: HomeTheme.lime, size: 32),
        ],
      ),
    );
  }
}

// ─── Upgrade mining power button → Shop ──────────────────────────────────────
class HomeUpgradeButton extends StatelessWidget {
  const HomeUpgradeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/shop'),
        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
        label: const Text('Upgrade mining power'),
        style: OutlinedButton.styleFrom(
          foregroundColor: HomeTheme.lime,
          side: BorderSide(color: HomeTheme.lime),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─── Grid: Lucky Spin + Referral (row 1), Challenges (row 2) ──────────────────
class HomeSpinReferralChallengesGrid extends StatelessWidget {
  final LuckySpinService spin;
  final ReferralService referral;
  final WeeklyChallengeService weekly;

  const HomeSpinReferralChallengesGrid({
    super.key,
    required this.spin,
    required this.referral,
    required this.weekly,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Lucky Spin | Referral (two items horizontal)
        Row(
          children: [
            Expanded(
              child: _HomeFeatureCard(
                icon: Icons.casino_rounded,
                title: 'Lucky Spin',
                subtitle: spin.canSpin ? 'Spin for rewards!' : 'Next spin in 24h',
                onTap: () => Navigator.pushNamed(context, '/lucky-spin'),
                accent: HomeTheme.lime,
                compact: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomeFeatureCard(
                icon: Icons.group_add_rounded,
                title: 'Referral',
                subtitle: '${referral.friends} friends',
                onTap: () => Navigator.pushNamed(context, '/profile'),
                accent: HomeTheme.limeSuccess,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Challenges (full width)
        _HomeFeatureCard(
          icon: Icons.emoji_events_rounded,
          title: 'Weekly challenge',
          subtitle: 'Complete sessions for rewards',
          onTap: () => Navigator.pushNamed(context, '/profile'),
          accent: HomeTheme.limeWarning,
          compact: false,
        ),
      ],
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;
  final bool compact;

  const _HomeFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 12.0 : HomeTheme.md;
    final iconSize = compact ? 20.0 : 24.0;
    final titleSize = compact ? 13.0 : 14.0;
    final subtitleSize = compact ? 11.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
            color: HomeTheme.limeSurface,
            border: Border.all(color: HomeTheme.limeBorderFaint),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: iconSize),
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: HomeTheme.limeTextHigh,
                        fontWeight: FontWeight.w700,
                        fontSize: titleSize,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: HomeTheme.limeTextMid, fontSize: subtitleSize),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: HomeTheme.limeTextLow),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── How BTC mining works (text card) ───────────────────────────────────────
class HomeHowMiningWorksCard extends StatelessWidget {
  const HomeHowMiningWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HomeTheme.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        color: HomeTheme.cardLight,
        border: Border.all(color: HomeTheme.cardLightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: HomeTheme.limeDark, size: 22),
              const SizedBox(width: 10),
              Text(
                'How BTC mining works',
                style: TextStyle(color: HomeTheme.cardLightTextHigh, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bitcoin mining uses computing power to solve complex puzzles. Miners compete to add new blocks to the blockchain and earn block rewards (currently 6.25 BTC) plus transaction fees. Your simulated hashrate earns you BTC over time.',
            style: TextStyle(color: HomeTheme.cardLightTextMid, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Mining reward card ─────────────────────────────────────────────────────
class HomeMiningRewardCard extends StatelessWidget {
  const HomeMiningRewardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeIconTitleCard(
      icon: Icons.card_giftcard_rounded,
      title: 'Mining reward',
      body: 'Earn BTC as your rigs run. Upgrade rigs and boost your rate in the Shop.',
    );
  }
}

// ─── Security first card ────────────────────────────────────────────────────
class HomeSecurityCard extends StatelessWidget {
  const HomeSecurityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeIconTitleCard(
      icon: Icons.security_rounded,
      title: 'Security first',
      body: 'Your balance is stored securely. We never store private keys.',
    );
  }
}

// ─── Transparency and trust card ────────────────────────────────────────────
class HomeTransparencyCard extends StatelessWidget {
  const HomeTransparencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeIconTitleCard(
      icon: Icons.verified_user_rounded,
      title: 'Transparency & trust',
      body: 'Real-time BTC price from CoinGecko. Clear stats and no hidden fees.',
    );
  }
}

class _HomeIconTitleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HomeIconTitleCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HomeTheme.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        color: HomeTheme.cardLight,
        border: Border.all(color: HomeTheme.cardLightBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HomeTheme.limeDark, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: HomeTheme.cardLightTextHigh, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(color: HomeTheme.cardLightTextMid, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Testimonials horizontal scroll ─────────────────────────────────────────
class HomeTestimonialsCard extends StatelessWidget {
  const HomeTestimonialsCard({super.key});

  static const _items = [
    _Testimonial('Alex M.', 'Earned my first 0.001 BTC in a week. Addictive!', '⭐⭐⭐⭐⭐'),
    _Testimonial('Sarah K.', 'Clean app, real price data. Love the mining sim.', '⭐⭐⭐⭐⭐'),
    _Testimonial('Mike T.', 'Upgraded rigs and doubled my rate. Worth it.', '⭐⭐⭐⭐⭐'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Testimonials',
            style: TextStyle(color: HomeTheme.limeTextHigh, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = _items[i];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Container(
                  padding: const EdgeInsets.all(HomeTheme.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
                    color: HomeTheme.cardLight,
                    border: Border.all(color: HomeTheme.cardLightBorder),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.stars, style: TextStyle(fontSize: 12, color: HomeTheme.limeWarning)),
                      const SizedBox(height: 8),
                      Text(
                        t.quote,
                        style: TextStyle(color: HomeTheme.cardLightTextHigh, fontSize: 13, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(t.author, style: TextStyle(color: HomeTheme.cardLightTextMid, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Testimonial {
  final String author;
  final String quote;
  final String stars;

  const _Testimonial(this.author, this.quote, this.stars);
}

// ─── FAQ card ──────────────────────────────────────────────────────────────
class HomeFaqCard extends StatelessWidget {
  const HomeFaqCard({super.key});

  static const _faqs = [
    _Faq('What is Bitcoin mining?', 'Mining is the process of validating transactions and adding new blocks to the Bitcoin blockchain. Miners earn rewards in BTC.'),
    _Faq('How do I earn more BTC?', 'Upgrade your mining rigs in the Shop and complete sessions. Higher hashrate = more BTC per hour.'),
    _Faq('Is my balance real?', 'This app simulates mining. Your in-app balance is for fun; withdraw options may apply in-app only.'),
    _Faq('Where does the price come from?', 'We use CoinGecko API for real-time BTC/USD price.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HomeTheme.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        color: HomeTheme.cardLight,
        border: Border.all(color: HomeTheme.cardLightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: HomeTheme.limeDark, size: 22),
              const SizedBox(width: 10),
              Text(
                'FAQ',
                style: TextStyle(color: HomeTheme.cardLightTextHigh, fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._faqs.asMap().entries.map((e) {
            final faq = e.value;
            final isLast = e.key == _faqs.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq.q,
                    style: TextStyle(color: HomeTheme.cardLightTextHigh, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    faq.a,
                    style: TextStyle(color: HomeTheme.cardLightTextMid, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;

  const _Faq(this.q, this.a);
}
