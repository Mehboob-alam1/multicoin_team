import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

import '../services/ad_remote_config_service.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../widgets/minimizable_native_ad.dart';
import '../widgets/smart_banner_ad.dart';

// ─── Design tokens (shared across app) ───────────────────────────────────────
class _D {
  static const bg       = Color(0xFF080B12);
  static const surface  = Color(0xFF0E1420);
  static const card     = Color(0xFF121826);
  static const cardBord = Color(0xFF1E2A3A);
  static const gold     = Color(0xFFF5A623);
  static const goldSoft = Color(0xFFFFD97D);
  static const electric = Color(0xFF00D4FF);
  static const green    = Color(0xFF00E5A0);
  static const pink     = Color(0xFFFF6B9D);
  static const textHi   = Color(0xFFF0F4FF);
  static const textMid  = Color(0xFF8899BB);
  static const textLow  = Color(0xFF3D4F6B);

  // Rank medal colors
  static const rank1 = Color(0xFFFFD700);
  static const rank2 = Color(0xFFC0C0C0);
  static const rank3 = Color(0xFFCD7F32);
}

// ─── Metric tab model ─────────────────────────────────────────────────────────
class _Tab {
  final String key;
  final String label;
  final IconData icon;
  final Color accent;
  const _Tab({required this.key, required this.label, required this.icon, required this.accent});
}

const _tabs = [
  _Tab(key: 'totalMined', label: 'Total BTC',  icon: Icons.currency_bitcoin,    accent: _D.gold),
  _Tab(key: 'hashRate',   label: 'Hash Rate',  icon: Icons.speed_rounded,       accent: _D.electric),
  _Tab(key: 'farmSize',   label: 'Farm Size',  icon: Icons.warehouse_rounded,   accent: _D.green),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  List<GlobalLeaderboardEntry> _entries = [];
  String _metric = 'totalMined';
  bool _loading = true;
  String? _error;
  String? _currentUid;
  bool _initialLoadDone = false;

  late final AnimationController _listAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

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
      _listAnim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _sortEntries() {
    switch (_metric) {
      case 'hashRate':  _entries.sort((a, b) => b.hashRate.compareTo(a.hashRate)); break;
      case 'farmSize':  _entries.sort((a, b) => b.farmSize.compareTo(a.farmSize)); break;
      default:          _entries.sort((a, b) => b.totalMined.compareTo(a.totalMined));
    }
  }

  _Tab get _currentTab => _tabs.firstWhere((t) => t.key == _metric);

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthService>();
    final adCfg = context.watch<AdRemoteConfigService>();
    _currentUid ??= auth.currentUser?.uid;

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // Ambient glow
            Positioned(
              top: -80,
              right: -60,
              child: _Blob(color: _D.pink.withValues(alpha: 0.06), size: 300),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: _Blob(color: _D.electric.withValues(alpha: 0.04), size: 260),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── App bar ──────────────────────────────────────────────
                  _AppBar(loading: _loading, onRefresh: _loading ? null : _load),
                  const SizedBox(height: 4),

                  // ── Metric tabs ──────────────────────────────────────────
                  _MetricTabs(
                    selected: _metric,
                    onSelect: (key) {
                      setState(() { _metric = key; _sortEntries(); });
                      _listAnim.forward(from: 0);
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Body ─────────────────────────────────────────────────
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
      ),
    );
  }

  Widget _buildBody(AdRemoteConfigService adCfg) {
    if (_loading) return const _LoadingState();
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    if (_entries.isEmpty) return const _EmptyState();

    // Top-3 podium + rest of list
    final top3   = _entries.take(3).toList();
    final rest   = _entries.skip(3).toList();
    final tab    = _currentTab;

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        if (adCfg.adsActive) ...[
          MinimizableNativeAd(title: 'Sponsored'),
          const SizedBox(height: 12),
        ],

        // Podium
        _Podium(entries: top3, tab: tab, currentUid: _currentUid),
        const SizedBox(height: 20),

        // Rest
        ...List.generate(rest.length, (i) {
          final rank  = i + 4;
          final entry = rest[i];
          final delay = i * 0.04;
          return AnimatedBuilder(
            animation: _listAnim,
            builder: (_, child) {
              final t = (((_listAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0));
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - t)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EntryTile(
                rank:          rank,
                entry:         entry,
                tab:           tab,
                isCurrentUser: entry.uid == _currentUid,
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
    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
    child: Row(
      children: [
        const Icon(Icons.emoji_events_rounded, color: _D.gold, size: 22),
        const SizedBox(width: 10),
        const Text(
          'LEADERBOARD',
          style: TextStyle(
            color: _D.gold,
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 2.5,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onRefresh,
          child: AnimatedRotation(
            turns: loading ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _D.cardBord,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: loading ? _D.textLow : _D.textMid,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Metric tabs ──────────────────────────────────────────────────────────────
class _MetricTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _MetricTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tabs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final t = _tabs[i];
        final active = t.key == selected;
        return GestureDetector(
          onTap: () => onSelect(t.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active ? t.accent.withValues(alpha: 0.15) : _D.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? t.accent.withValues(alpha: 0.5) : _D.cardBord,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(t.icon, color: active ? t.accent : _D.textLow, size: 14),
                const SizedBox(width: 6),
                Text(
                  t.label,
                  style: TextStyle(
                    color: active ? t.accent : _D.textLow,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ─── Podium (top 3) ───────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<GlobalLeaderboardEntry> entries;
  final _Tab tab;
  final String? currentUid;
  const _Podium({required this.entries, required this.tab, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Always show 1st in center, 2nd left, 3rd right
    Widget slot(int rank) {
      if (rank > entries.length) return const Expanded(child: SizedBox());
      final e = entries[rank - 1];
      return Expanded(
        child: _PodiumSlot(
          rank:          rank,
          entry:         e,
          tab:           tab,
          isCurrentUser: e.uid == currentUid,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [slot(2), slot(1), slot(3)],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final int rank;
  final GlobalLeaderboardEntry entry;
  final _Tab tab;
  final bool isCurrentUser;
  const _PodiumSlot({
    required this.rank,
    required this.entry,
    required this.tab,
    required this.isCurrentUser,
  });

  Color get _medalColor => switch (rank) {
    1 => _D.rank1,
    2 => _D.rank2,
    _ => _D.rank3,
  };

  double get _height => switch (rank) { 1 => 110.0, 2 => 82.0, _ => 68.0 };

  String _value() {
    return switch (tab.key) {
      'hashRate' => '${entry.hashRate.toStringAsFixed(6)}\nBTC/min',
      'farmSize' => '${entry.farmSize}\nrigs',
      _          => '${entry.totalMined.toStringAsFixed(4)}\nBTC',
    };
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      children: [
        // Avatar
        Container(
          width: rank == 1 ? 52 : 42,
          height: rank == 1 ? 52 : 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _medalColor,
              _medalColor.withValues(alpha: 0.4),
            ]),
            boxShadow: [
              BoxShadow(
                color: _medalColor.withValues(alpha: 0.4),
                blurRadius: 14,
              ),
            ],
            border: isCurrentUser
                ? Border.all(color: _D.electric, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: rank == 1 ? 22 : 17,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrentUser ? _D.electric : _D.textHi,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _value(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _medalColor,
            fontFamily: AppTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        // Podium block
        Container(
          height: _height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _medalColor.withValues(alpha: 0.25),
                _medalColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              top:   BorderSide(color: _medalColor.withValues(alpha: 0.5), width: 1),
              left:  BorderSide(color: _medalColor.withValues(alpha: 0.2), width: 1),
              right: BorderSide(color: _medalColor.withValues(alpha: 0.2), width: 1),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: _medalColor,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w900,
                fontSize: rank == 1 ? 24 : 18,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Regular entry tile ───────────────────────────────────────────────────────
class _EntryTile extends StatelessWidget {
  final int rank;
  final GlobalLeaderboardEntry entry;
  final _Tab tab;
  final bool isCurrentUser;
  const _EntryTile({
    required this.rank,
    required this.entry,
    required this.tab,
    required this.isCurrentUser,
  });

  String _trailing() => switch (tab.key) {
    'hashRate' => '${entry.hashRate.toStringAsFixed(8)} BTC/min',
    'farmSize' => '${entry.farmSize} rigs',
    _          => '${entry.totalMined.toStringAsFixed(6)} BTC',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: isCurrentUser
          ? _D.electric.withValues(alpha: 0.07)
          : _D.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isCurrentUser
            ? _D.electric.withValues(alpha: 0.35)
            : _D.cardBord,
        width: 1,
      ),
    ),
    child: Row(
      children: [
        // Rank badge
        SizedBox(
          width: 32,
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: _D.textMid,
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tab.accent.withValues(alpha: 0.15),
            border: Border.all(color: tab.accent.withValues(alpha: 0.3), width: 1),
          ),
          child: Center(
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: tab.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    entry.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrentUser ? _D.electric : _D.textHi,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
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
                        style: TextStyle(color: _D.electric, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(
                '${entry.farmSize} rigs · ${entry.hashRate.toStringAsFixed(6)} BTC/min',
                style: const TextStyle(color: _D.textMid, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Value
        Text(
          _trailing(),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: tab.accent,
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// ─── States ───────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      color: _D.gold,
      strokeWidth: 2,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _D.card,
              shape: BoxShape.circle,
              border: Border.all(color: _D.cardBord),
            ),
            child: const Icon(Icons.cloud_off_rounded, size: 32, color: _D.textMid),
          ),
          const SizedBox(height: 20),
          const Text('Could not load rankings',
              style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _D.textMid, fontSize: 12)),
          const SizedBox(height: 24),
          _GoldBtn(label: 'Retry', icon: Icons.refresh_rounded, onTap: onRetry),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _D.card,
            shape: BoxShape.circle,
            border: Border.all(color: _D.cardBord),
          ),
          child: const Icon(Icons.emoji_events_outlined, size: 40, color: _D.textLow),
        ),
        const SizedBox(height: 20),
        const Text('No miners yet',
            style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Mine BTC to claim your spot!',
            style: TextStyle(color: _D.textMid, fontSize: 13)),
      ],
    ),
  );
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
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
        boxShadow: [BoxShadow(color: _D.gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, color: Colors.black, size: 16), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: AppTheme.fontFamily,
  textTheme: AppTheme.darkTextTheme,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);