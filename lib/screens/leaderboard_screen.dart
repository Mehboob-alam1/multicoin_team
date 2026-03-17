import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/ad_remote_config_service.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../widgets/minimizable_native_ad.dart';
import '../widgets/smart_banner_ad.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFFF7F8FA);
  static const surface  = Color(0xFFFFFFFF);
  static const card     = Color(0xFFFFFFFF);
  static const cardBord = Color(0xFFE2E8F0);
  static const gold     = Color(0xFFF59E0B);
  static const goldDark = Color(0xFFD97706);
  static const electric = Color(0xFF0EA5E9);
  static const green    = Color(0xFF22C55E);
  static const pink     = Color(0xFFEC4899);
  static const textHi   = Color(0xFF0D0F12);
  static const textMid  = Color(0xFF6B7280);
  static const textLow  = Color(0xFF9CA3AF);

  static const gold1 = Color(0xFFFFD700);
  static const gold2 = Color(0xFFC0C0C0);
  static const gold3 = Color(0xFFCD7F32);
}

// ─── Metric tabs ──────────────────────────────────────────────────────────────
class _Tab {
  final String key;
  final String label;
  final IconData icon;
  final Color accent;
  const _Tab({required this.key, required this.label, required this.icon, required this.accent});
}

const _tabs = [
  _Tab(key: 'totalMined', label: 'Total mined', icon: Icons.currency_bitcoin, accent: _D.gold),
  _Tab(key: 'hashRate',   label: 'Hash Rate',  icon: Icons.speed_rounded,      accent: _D.electric),
  _Tab(key: 'farmSize',   label: 'Farm Size',  icon: Icons.warehouse_rounded,  accent: _D.green),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  List<GlobalLeaderboardEntry> _entries = [];
  String  _metric          = 'totalMined';
  bool    _loading         = true;
  String? _error;
  String? _currentUid;
  bool    _initialLoadDone = false;

  late final AnimationController _listAnim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _podiumAnim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _hexAnim = AnimationController(
    vsync: this, duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) { _initialLoadDone = true; _load(); }
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _podiumAnim.dispose();
    _hexAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final lb = context.read<LeaderboardService>();
    setState(() { _loading = true; _error = null; });
    try {
      await lb.fetchTop();
      if (!mounted) return;
      setState(() {
        _entries = List.from(lb.cached);
        _sortEntries();
        _loading = false;
      });
      _podiumAnim.forward(from: 0);
      _listAnim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _switchMetric(String key) {
    setState(() { _metric = key; _sortEntries(); });
    _listAnim.forward(from: 0);
    _podiumAnim.forward(from: 0);
  }

  void _sortEntries() {
    switch (_metric) {
      case 'hashRate': _entries.sort((a, b) => b.hashRate.compareTo(a.hashRate));    break;
      case 'farmSize': _entries.sort((a, b) => b.farmSize.compareTo(a.farmSize));    break;
      default:         _entries.sort((a, b) => b.totalMined.compareTo(a.totalMined));
    }
  }

  _Tab get _currentTab => _tabs.firstWhere((t) => t.key == _metric);

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthService>();
    final adCfg = context.watch<AdRemoteConfigService>();
    _currentUid = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          // ── Subtle drifting hex grid ──────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _hexAnim,
              builder: (_, __) => CustomPaint(
                painter: _HexGridPainter(progress: _hexAnim.value),
              ),
            ),
          ),

          // ── Ambient blobs ─────────────────────────────────────────────────
          Positioned(top: -100, right: -80,
              child: _Blob(color: _D.pink.withValues(alpha: 0.07), size: 340)),
          Positioned(bottom: 60,  left: -100,
              child: _Blob(color: _D.electric.withValues(alpha: 0.05), size: 300)),
          Positioned(top: 220,   left: -50,
              child: _Blob(color: _D.gold.withValues(alpha: 0.04), size: 200)),

          SafeArea(
            child: Column(
              children: [
                _AppBar(loading: _loading, onRefresh: _loading ? null : _load),
                const SizedBox(height: 6),
                _MetricTabRow(selected: _metric, onSelect: _switchMetric),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: _D.gold,
                    backgroundColor: _D.card,
                    child: _buildBody(adCfg),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AdRemoteConfigService adCfg) {
    if (_loading) return const _LoadingState();
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    if (_entries.isEmpty) return const _EmptyState();

    final top10 = _entries.take(10).toList();
    final top3  = top10.take(3).toList();
    final listRanks4to10 = top10.length > 3 ? top10.sublist(3) : <GlobalLeaderboardEntry>[];
    final tab = _currentTab;

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        // ── Top 3 profile cards ──────────────────────────────────────────────
        _TopThreeProfileCards(
          entries:    top3,
          tab:        tab,
          currentUid: _currentUid,
          anim:       _podiumAnim,
        ),
        const SizedBox(height: 20),

        // ── Section label: Top 10 list ───────────────────────────────────────
        if (listRanks4to10.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(children: [
              Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                      color: tab.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('TOP 10',
                  style: TextStyle(
                      color: tab.accent, fontSize: 11,
                      fontWeight: FontWeight.w800, letterSpacing: 2)),
            ]),
          ),

        // ── Ad ───────────────────────────────────────────────────────────────
        if (adCfg.adsActive) ...[
          MinimizableNativeAd(title: 'Sponsored'),
          const SizedBox(height: 10),
        ],

        // ── Vertical list: ranks 4–10 ────────────────────────────────────────
        ...List.generate(listRanks4to10.length, (i) {
          final delay = i * 0.05;
          return AnimatedBuilder(
            animation: _listAnim,
            builder: (_, child) {
              final t     = ((_listAnim.value - delay) / (1 - delay + 0.001)).clamp(0.0, 1.0);
              final curve = Curves.easeOutCubic.transform(t);
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                    offset: Offset(0, 24 * (1 - curve)), child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EntryRow(
                rank:          i + 4,
                entry:         listRanks4to10[i],
                tab:           tab,
                isCurrentUser: listRanks4to10[i].uid == _currentUid,
              ),
            ),
          );
        }),

        if (adCfg.adsActive) ...[
          const SizedBox(height: 12),
          const Center(child: SmartBannerAd()),
        ],
      ],
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final bool loading;
  final VoidCallback? onRefresh;
  const _AppBar({required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 14, 4),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _D.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _D.gold.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: _D.gold.withValues(alpha: 0.2), blurRadius: 12)],
        ),
        child: const Icon(Icons.emoji_events_rounded, color: _D.gold, size: 18),
      ),
      const SizedBox(width: 12),
      const Text(
        'LEADERBOARD',
        style: TextStyle(
          color: _D.textHi,
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 2,
        ),
      ),
      const Spacer(),
      GestureDetector(
        onTap: onRefresh,
        child: AnimatedRotation(
          turns: loading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _D.cardBord, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.refresh_rounded,
                color: loading ? _D.gold : _D.textMid, size: 18),
          ),
        ),
      ),
    ]),
  );
}

// ─── Metric tab row ───────────────────────────────────────────────────────────
class _MetricTabRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _MetricTabRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tabs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final t      = _tabs[i];
        final active = t.key == selected;
        return GestureDetector(
          onTap: () => onSelect(t.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: active ? t.accent.withValues(alpha: 0.14) : _D.card,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: active ? t.accent.withValues(alpha: 0.55) : _D.cardBord,
                width: active ? 1.5 : 1,
              ),
              boxShadow: active
                  ? [BoxShadow(color: t.accent.withValues(alpha: 0.15), blurRadius: 10)]
                  : null,
            ),
            child: Row(children: [
              Icon(t.icon, color: active ? t.accent : _D.textLow, size: 14),
              const SizedBox(width: 6),
              Text(t.label,
                  style: TextStyle(
                    color: active ? t.accent : _D.textLow,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  )),
            ]),
          ),
        );
      },
    ),
  );
}

// ─── Top 3 profile cards ─────────────────────────────────────────────────────
class _TopThreeProfileCards extends StatelessWidget {
  final List<GlobalLeaderboardEntry> entries;
  final _Tab tab;
  final String? currentUid;
  final AnimationController anim;
  const _TopThreeProfileCards({
    required this.entries,
    required this.tab,
    required this.currentUid,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Row(
      children: List.generate(3, (i) {
        if (i >= entries.length) {
          return const Expanded(child: SizedBox());
        }
        final rank = i + 1;
        final e = entries[i];
        final delay = i * 0.12;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, child) {
                final t = ((anim.value - delay) / (1 - delay + 0.001)).clamp(0.0, 1.0);
                final curve = Curves.easeOutBack.transform(t);
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - curve)),
                    child: child,
                  ),
                );
              },
              child: _ProfileCard(
                rank:          rank,
                entry:         e,
                tab:           tab,
                isCurrentUser: e.uid == currentUid,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final int rank;
  final GlobalLeaderboardEntry entry;
  final _Tab tab;
  final bool isCurrentUser;
  const _ProfileCard({
    required this.rank,
    required this.entry,
    required this.tab,
    required this.isCurrentUser,
  });

  Color get _medal => switch (rank) { 1 => _D.gold1, 2 => _D.gold2, _ => _D.gold3 };
  double get _avSize => rank == 1 ? 52.0 : 44.0;

  String _valueStr() => switch (tab.key) {
    'hashRate' => '${entry.hashRate.toStringAsFixed(5)}\nBTC/min',
    'farmSize' => '${entry.farmSize}\nrigs',
    _          => '${entry.totalMined.toStringAsFixed(4)}\nBTC',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? _D.electric.withValues(alpha: 0.5) : _D.cardBord,
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _medal.withValues(alpha: 0.12),
            blurRadius: rank == 1 ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _medal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _medal, width: 1.2),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: _medal,
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: rank == 1 ? 11 : 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: _avSize,
            height: _avSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_medal, _medal.withValues(alpha: 0.55)],
              ),
              border: Border.all(
                color: isCurrentUser ? _D.electric : _medal.withValues(alpha: 0.8),
                width: isCurrentUser ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _medal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: rank == 1 ? 20 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCurrentUser ? _D.electric : _D.textHi,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _valueStr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _medal,
              fontFamily: AppTheme.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Entry row ────────────────────────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final int rank;
  final GlobalLeaderboardEntry entry;
  final _Tab tab;
  final bool isCurrentUser;
  const _EntryRow({
    required this.rank, required this.entry,
    required this.tab,  required this.isCurrentUser,
  });

  String _trailing() => switch (tab.key) {
    'hashRate' => '${entry.hashRate.toStringAsFixed(7)}\nBTC/min',
    'farmSize' => '${entry.farmSize}\nrigs',
    _          => '${entry.totalMined.toStringAsFixed(6)}\nBTC',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: isCurrentUser ? _D.electric.withValues(alpha: 0.07) : _D.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isCurrentUser ? _D.electric.withValues(alpha: 0.4) : _D.cardBord,
      ),
    ),
    child: Row(children: [
      // Rank + tier
      SizedBox(
        width: 42,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$rank',
                style: const TextStyle(
                    color: _D.textLow, fontFamily: AppTheme.fontFamily,
                    fontSize: 13, fontWeight: FontWeight.w700)),
            Text(
              rank <= 10 ? 'Gold' : rank <= 50 ? 'Silver' : 'Bronze',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: rank <= 10 ? _D.gold1 : rank <= 50 ? _D.gold2 : _D.gold3,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),

      // Avatar
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tab.accent.withValues(alpha: 0.12),
          border: Border.all(color: tab.accent.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: tab.accent, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
      const SizedBox(width: 12),

      // Name + subtitle
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isCurrentUser ? _D.electric : _D.textHi,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _D.electric.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _D.electric.withValues(alpha: 0.4)),
                ),
                child: const Text('YOU',
                    style: TextStyle(
                        color: _D.electric, fontSize: 9,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(
              '${entry.farmSize} rigs · ${entry.hashRate.toStringAsFixed(6)} BTC/min',
              style: const TextStyle(color: _D.textLow, fontSize: 10)),
        ]),
      ),
      const SizedBox(width: 10),

      // Value
      Text(
        _trailing(), textAlign: TextAlign.right,
        style: TextStyle(
            color: tab.accent, fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700, fontSize: 11, height: 1.4),
      ),
    ]),
  );
}

// ─── States ───────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 40, height: 40,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: _D.gold, backgroundColor: _D.cardBord),
      ),
      const SizedBox(height: 14),
      const Text('Fetching rankings…',
          style: TextStyle(color: _D.textMid, fontSize: 12)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _D.card,
            border: Border.all(color: _D.cardBord),
          ),
          child: const Icon(Icons.cloud_off_rounded, size: 32, color: _D.textMid),
        ),
        const SizedBox(height: 20),
        const Text('Rankings unavailable',
            style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _D.textMid, fontSize: 12)),
        const SizedBox(height: 24),
        _GoldBtn(label: 'Try again', icon: Icons.refresh_rounded, onTap: onRetry),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: _D.card,
          border: Border.all(color: _D.cardBord),
        ),
        child: const Icon(Icons.emoji_events_outlined, size: 40, color: _D.textLow),
      ),
      const SizedBox(height: 20),
      const Text('No miners yet',
          style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 6),
      const Text('Mine BTC to claim your spot!',
          style: TextStyle(color: _D.textMid, fontSize: 13)),
    ]),
  );
}

// ─── Drifting hex grid background ────────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final double progress;
  const _HexGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A3A).withValues(alpha: 0.22)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const r  = 26.0;
    const hx = r * 1.732;
    const hy = r * 1.5;

    final cols   = (size.width  / hx).ceil() + 2;
    final rows   = (size.height / hy).ceil() + 2;
    final offX   = (progress * hx * 2) % hx;
    final offY   = (progress * hy)     % hy;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * hx + (row.isOdd ? hx / 2 : 0) - offX;
        final cy = row * hy - offY;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = math.pi / 180 * (60 * i - 30);
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HexGridPainter old) => old.progress != progress;
}

// ─── Shared ───────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: const SizedBox.shrink(),
    ),
  );
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: _D.gold.withValues(alpha: 0.35),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, color: Colors.black, size: 16), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);