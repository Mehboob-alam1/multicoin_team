import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/ad_remote_config_service.dart';
import '../services/auth_service.dart';
import '../data/test_miners.dart';
import '../services/leaderboard_service.dart';
import '../widgets/screen_ad_slot.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFF08080A);
  static const surface  = Color(0xFF18181C);
  static const card     = Color(0xFF18181C);
  static const cardBord = Color(0x1FFFFFFF);
  static const glassBord = Color(0x2DFFFFFF);
  static const gold     = Color(0xFF9945FF);
  static const goldDark = Color(0xFF7C3AED);
  static const electric = Color(0xFF38BDF8);
  static const green    = Color(0xFF14F195);
  static const pink     = Color(0xFFEC4899);
  static const textHi   = Color(0xFFF4F4F5);
  static const textMid  = Color(0xFFA1A1AA);
  static const textLow  = Color(0xFF71717A);

  static const gold1 = Color(0xFFFFD700);
  static const gold2 = Color(0xFFC0C0C0);
  static const gold3 = Color(0xFFCD7F32);
}

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _label({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _D.textHi,
  double? letterSpacing,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing ?? -0.2,
);

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _D.textHi,
}) => GoogleFonts.spaceMono(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.3,
);

// ─── Metric tabs ──────────────────────────────────────────────────────────────
class _Tab {
  final String key;
  final String label;
  final IconData icon;
  final Color accent;
  const _Tab({
    required this.key,
    required this.label,
    required this.icon,
    required this.accent,
  });
}

const _tabs = [
  _Tab(
    key: 'totalMined',
    label: 'Total mined',
    icon: Icons.hexagon_rounded,
    accent: _D.gold,
  ),
  _Tab(
    key: 'hashRate',
    label: 'Hash Rate',
    icon: Icons.speed_rounded,
    accent: _D.electric,
  ),
  _Tab(
    key: 'farmSize',
    label: 'Farm Size',
    icon: Icons.warehouse_rounded,
    accent: _D.green,
  ),
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
  String _metric = 'totalMined';
  String _region = 'all';
  bool _loading = true;
  String? _error;
  String? _currentUid;
  bool _initialLoadDone = false;

  late final AnimationController _listAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _podiumAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _hexAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _load();
    }
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
    setState(() {
      _loading = true;
      _error = null;
    });
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _switchMetric(String key) {
    setState(() {
      _metric = key;
      _sortEntries();
    });
    _listAnim.forward(from: 0);
    _podiumAnim.forward(from: 0);
  }

  void _switchRegion(String key) {
    setState(() => _region = key);
    _listAnim.forward(from: 0);
    _podiumAnim.forward(from: 0);
  }

  List<GlobalLeaderboardEntry> get _visibleEntries {
    if (_region == 'all') return _entries;
    return _entries.where((e) => e.region == _region).toList();
  }

  void _sortEntries() {
    switch (_metric) {
      case 'hashRate':
        _entries.sort((a, b) => b.hashRate.compareTo(a.hashRate));
        break;
      case 'farmSize':
        _entries.sort((a, b) => b.farmSize.compareTo(a.farmSize));
        break;
      default:
        _entries.sort((a, b) => b.totalMined.compareTo(a.totalMined));
    }
  }

  _Tab get _currentTab => _tabs.firstWhere((t) => t.key == _metric);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
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
          Positioned(
            top: -100,
            right: -80,
            child: _Blob(
              color: _D.pink.withOpacity(0.07),
              size: 340,
            ),
          ),
          Positioned(
            bottom: 60,
            left: -100,
            child: _Blob(
              color: _D.electric.withOpacity(0.05),
              size: 300,
            ),
          ),
          Positioned(
            top: 220,
            left: -50,
            child: _Blob(
              color: _D.gold.withOpacity(0.04),
              size: 200,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _AppBar(loading: _loading, onRefresh: _loading ? null : _load),
                const SizedBox(height: 8),
                _MetricTabRow(
                  selected: _metric,
                  onSelect: _switchMetric,
                ),
                const SizedBox(height: 8),
                _RegionFilterRow(
                  selected: _region,
                  onSelect: _switchRegion,
                ),
                const SizedBox(height: 10),
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
    final visible = _visibleEntries;
    if (visible.isEmpty) return const _EmptyState();

    final shown = visible.take(50).toList();
    final top3 = shown.take(3).toList();
    final rest = shown.length > 3 ? shown.sublist(3) : <GlobalLeaderboardEntry>[];
    final tab = _currentTab;

    return ListView(
      physics: AppTheme.pageScroll,
      padding: EdgeInsets.fromLTRB(
        AppTheme.pagePaddingH,
        8,
        AppTheme.pagePaddingH,
        AppTheme.pageBottomPadding(context),
      ),
      children: [
        // ── Top 3 profile cards ──────────────────────────────────────────────
        _TopThreeProfileCards(
          entries: top3,
          tab: tab,
          currentUid: _currentUid,
          anim: _podiumAnim,
        ),
        const SizedBox(height: 24),

        // ── Section label: Top 10 list ───────────────────────────────────────
        if (rest.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: tab.accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: tab.accent.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'MINERS',
                  style: _label(
                    size: 12,
                    weight: FontWeight.w800,
                    color: tab.accent,
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
          ),

        // ── Ad ───────────────────────────────────────────────────────────────
        if (adCfg.shouldShowSdkAds) ...[
          const ScreenAdSlot(title: 'Leaderboard offer'),
          const SizedBox(height: 12),
        ],

        // ── Vertical list: ranks 4–10 ────────────────────────────────────────
        ...List.generate(rest.length, (i) {
          final delay = (i * 0.04).clamp(0.0, 0.6);
          return AnimatedBuilder(
            animation: _listAnim,
            builder: (_, child) {
              final t = ((_listAnim.value - delay) / (1 - delay + 0.001))
                  .clamp(0.0, 1.0);
              final curve = Curves.easeOutCubic.transform(t);
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - curve)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EntryRow(
                rank: i + 4,
                entry: rest[i],
                tab: tab,
                isCurrentUser: rest[i].uid == _currentUid,
              ),
            ),
          );
        }),

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
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _D.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _D.gold.withOpacity(0.3),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _D.gold.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(Icons.emoji_events_rounded,
              color: _D.gold, size: 20),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [_D.gold, _D.green],
              ).createShader(r),
              child: Text(
                'LEADERBOARD',
                style: _label(
                  size: 16,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Top miners',
              style: _label(
                size: 11,
                weight: FontWeight.w500,
                color: _D.textLow,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onRefresh,
          child: AnimatedRotation(
            turns: loading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xF218181C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _D.glassBord,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: loading ? _D.gold : _D.textMid,
                    size: 19,
                  ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Metric tab row ───────────────────────────────────────────────────────────
class _MetricTabRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _MetricTabRow({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      itemCount: _tabs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final t = _tabs[i];
        final active = t.key == selected;

        return GestureDetector(
          onTap: () => onSelect(t.key),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? t.accent.withOpacity(0.12)
                      : _D.surface.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? t.accent.withOpacity(0.5) : _D.glassBord,
                    width: active ? 1.2 : 0.8,
                  ),
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color: t.accent.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.icon,
                      color: active ? t.accent : _D.textLow,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      t.label,
                      style: _label(
                        size: 12,
                        weight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? t.accent : _D.textLow,
                        letterSpacing: active ? 0.2 : -0.1,
                      ),
                    ),
                  ],
                ),
            ),
          ),
        );
      },
    ),
  );
}

class _RegionFilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _RegionFilterRow({required this.selected, required this.onSelect});

  static const _chips = [
    ('all', 'All'),
    (TestMiners.asia, 'Asia'),
    (TestMiners.europe, 'Europe'),
    (TestMiners.americas, 'Americas'),
    (TestMiners.africa, 'Africa'),
    (TestMiners.middleEast, 'Middle East'),
    (TestMiners.oceania, 'Oceania'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: _chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (key, label) = _chips[i];
            final active = key == selected;
            return GestureDetector(
              onTap: () => onSelect(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _D.gold.withOpacity(0.16) : _D.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: active ? _D.gold.withOpacity(0.55) : _D.glassBord,
                  ),
                ),
                child: Text(
                  label,
                  style: _label(
                    size: 11,
                    weight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _D.gold : _D.textMid,
                  ),
                ),
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
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 8,
              right: i == 2 ? 0 : 8,
            ),
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, child) {
                final t = ((anim.value - delay) / (1 - delay + 0.001))
                    .clamp(0.0, 1.0);
                final curve = Curves.easeOutBack.transform(t);

                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - curve)),
                    child: child,
                  ),
                );
              },
              child: _ProfileCard(
                rank: rank,
                entry: e,
                tab: tab,
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

  Color get _medal => switch (rank) {
    1 => _D.gold1,
    2 => _D.gold2,
    _ => _D.gold3,
  };

  double get _avSize => rank == 1 ? 56.0 : 48.0;

  String _valueStr() => switch (tab.key) {
    'hashRate' => '${entry.hashRate.toStringAsFixed(5)}\nSOL/min',
    'farmSize' => '${entry.farmSize}\nrigs',
    _ => '${entry.totalMined.toStringAsFixed(4)}\nSOL',
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF21F1F26), Color(0xE6121216)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrentUser
                  ? _D.electric.withOpacity(0.5)
                  : _D.glassBord,
              width: isCurrentUser ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _medal.withOpacity(rank == 1 ? 0.2 : 0.1),
                blurRadius: rank == 1 ? 20 : 12,
                offset: const Offset(0, 6),
              ),
              if (isCurrentUser)
                BoxShadow(
                  color: _D.electric.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rank badge
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _medal.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _medal, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _medal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: _label(
                      size: rank == 1 ? 12 : 11,
                      weight: FontWeight.w900,
                      color: _medal,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Avatar
              Container(
                width: _avSize,
                height: _avSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_medal, _medal.withOpacity(0.6)],
                  ),
                  border: Border.all(
                    color: isCurrentUser
                        ? _D.electric
                        : _medal.withOpacity(0.8),
                    width: isCurrentUser ? 2.2 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _medal.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: _label(
                      size: rank == 1 ? 22 : 18,
                      weight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Name
              Text(
                entry.flag.isEmpty ? entry.name : '${entry.flag} ${entry.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _label(
                  size: 12,
                  weight: FontWeight.w700,
                  color: isCurrentUser ? _D.electric : _D.textHi,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 5),

              // Value
              Text(
                _valueStr(),
                textAlign: TextAlign.center,
                style: _mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _medal,
                ),
              ),
            ],
          ),
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
    required this.rank,
    required this.entry,
    required this.tab,
    required this.isCurrentUser,
  });

  String _trailing() => switch (tab.key) {
    'hashRate' => '${entry.hashRate.toStringAsFixed(7)}\nSOL/min',
    'farmSize' => '${entry.farmSize}\nrigs',
    _ => '${entry.totalMined.toStringAsFixed(6)}\nSOL',
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCurrentUser
                  ? [
                      _D.electric.withOpacity(0.16),
                      const Color(0xE6121216),
                    ]
                  : const [Color(0xF21F1F26), Color(0xE6121216)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentUser
                  ? _D.electric.withOpacity(0.4)
                  : _D.glassBord,
              width: 0.8,
            ),
            boxShadow: isCurrentUser
                ? [
              BoxShadow(
                color: _D.electric.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
                : null,
          ),
          child: Row(
            children: [
              // Rank + tier
              SizedBox(
                width: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rank',
                      style: _label(
                        size: 14,
                        weight: FontWeight.w800,
                        color: _D.textMid,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rank <= 10
                          ? 'Gold'
                          : rank <= 50
                          ? 'Silver'
                          : 'Bronze',
                      style: _label(
                        size: 9,
                        weight: FontWeight.w700,
                        color: rank <= 10
                            ? _D.gold1
                            : rank <= 50
                            ? _D.gold2
                            : _D.gold3,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tab.accent.withOpacity(0.12),
                  border: Border.all(
                    color: tab.accent.withOpacity(0.35),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tab.accent.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: _label(
                      size: 15,
                      weight: FontWeight.w800,
                      color: tab.accent,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),

              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.flag.isEmpty ? entry.name : '${entry.flag}  ${entry.name}',
                            overflow: TextOverflow.ellipsis,
                            style: _label(
                              size: 13,
                              weight: FontWeight.w700,
                              color: isCurrentUser ? _D.electric : _D.textHi,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _D.electric.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _D.electric.withOpacity(0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'YOU',
                              style: _label(
                                size: 9,
                                weight: FontWeight.w800,
                                color: _D.electric,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.farmSize} rigs · ${entry.hashRate.toStringAsFixed(6)} SOL/min',
                      style: _label(
                        size: 11,
                        color: _D.textLow,
                        weight: FontWeight.w500,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Value
              Text(
                _trailing(),
                textAlign: TextAlign.right,
                style: _mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: tab.accent,
                ),
              ),
            ],
          ),
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _D.gold,
            backgroundColor: _D.cardBord,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Fetching rankings…',
          style: _label(
            size: 13,
            color: _D.textMid,
            weight: FontWeight.w500,
          ),
        ),
      ],
    ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xF218181C),
                  border: Border.all(color: _D.glassBord, width: 0.8),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: _D.textMid,
                ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Rankings unavailable',
            style: _label(
              size: 18,
              weight: FontWeight.w800,
              color: _D.textHi,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _label(
              size: 13,
              color: _D.textMid,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          _GoldBtn(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xF218181C),
                border: Border.all(color: _D.glassBord, width: 0.8),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 44,
                color: _D.textLow,
              ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No miners yet',
          style: _label(
            size: 18,
            weight: FontWeight.w800,
            color: _D.textHi,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mine SOL to claim your spot!',
          style: _label(
            size: 13,
            color: _D.textMid,
            weight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ─── Drifting hex grid background ────────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final double progress;

  const _HexGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A3A).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const r = 26.0;
    const hx = r * 1.732;
    const hy = r * 1.5;

    final cols = (size.width / hx).ceil() + 2;
    final rows = (size.height / hy).ceil() + 2;
    final offX = (progress * hx * 2) % hx;
    final offY = (progress * hy) % hy;

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
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _GoldBtn extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _GoldBtn({
    required this.label,
    this.icon,
    required this.onTap,
  });

  @override
  State<_GoldBtn> createState() => _GoldBtnState();
}

class _GoldBtnState extends State<_GoldBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _isPressed = true),
    onTapUp: (_) => setState(() => _isPressed = false),
    onTapCancel: () => setState(() => _isPressed = false),
    onTap: widget.onTap,
    child: Transform.scale(
      scale: _isPressed ? 0.95 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9945FF), Color(0xFF14F195)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _D.gold.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: Colors.white, size: 17),
                const SizedBox(width: 9),
              ],
              Text(
                widget.label,
                style: _label(
                  size: 14,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _D.bg,
  colorScheme:
  const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);