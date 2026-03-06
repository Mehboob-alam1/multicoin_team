import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<GlobalLeaderboardEntry> _entries = [];
  String _metric = 'totalMined';
  bool _loading = true;
  String? _error;
  String? _currentUid;
  bool _initialLoadDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final leaderboard = context.read<LeaderboardService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await leaderboard.fetchTop();
      final list = leaderboard.cached;
      if (!mounted) return;
      setState(() {
        _entries = list;
        _sortEntries();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    _currentUid ??= auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                          FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.leaderboard, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text('No entries yet. Mine BTC to appear!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'totalMined', label: Text('Total BTC')),
                                ButtonSegment(value: 'hashRate', label: Text('Hash rate')),
                                ButtonSegment(value: 'farmSize', label: Text('Farm size')),
                              ],
                              selected: {_metric},
                              onSelectionChanged: (v) {
                                setState(() {
                                  _metric = v.first;
                                  _sortEntries();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final e = _entries[index];
                          final rank = index + 1;
                          final isCurrentUser = e.uid == _currentUid;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              color: isCurrentUser ? AppTheme.primary.withValues(alpha: 0.15) : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: rank <= 3 ? AppTheme.btcGold.withValues(alpha: 0.3) : AppTheme.primary.withValues(alpha: 0.3),
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      color: rank <= 3 ? AppTheme.btcGold : AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis)),
                                    if (isCurrentUser) const Padding(padding: EdgeInsets.only(left: 8), child: Text('You', style: TextStyle(color: AppTheme.primary, fontSize: 12))),
                                  ],
                                ),
                                subtitle: Text(
                                  'Hash ${e.hashRate.toStringAsFixed(8)} BTC/min · Farm ${e.farmSize} rigs',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                                ),
                                trailing: Text(
                                  '${e.totalMined.toStringAsFixed(4)} BTC',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.primary),
                                ),
                              ),
                            ),
                          );
                        },
                            ),
                          ),
                        ],
                      ),
      ),
    );
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
}
