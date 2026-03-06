import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/game_state_service.dart';
import '../services/referral_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final game = context.watch<GameStateService>();
    final energy = context.watch<EnergyCoolingService>();
    final referral = context.watch<ReferralService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Icon(Icons.person, size: 50, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? (user?.isAnonymous == true ? 'Guest' : 'User'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (user?.email != null && (user!.email ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (user?.isAnonymous == true) ...[
            const SizedBox(height: 8),
            Text(
              'Guest account. Link Google to keep your progress.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await auth.linkWithGoogle();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account linked with Google')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.link),
                label: const Text('Link Google account'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.factory, color: AppTheme.primary),
                  title: const Text('Farm'),
                  subtitle: Text(
                    '${game.currentFarmTier.name} · Capacity ${game.ownedRigIds.length}/${game.rigCapacity}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.memory, color: AppTheme.primary),
                  title: const Text('Mining power'),
                  subtitle: Text('${game.totalBtcPerMin.toStringAsFixed(8)} BTC/min'),
                ),
                ListTile(
                  leading: const Icon(Icons.query_stats, color: AppTheme.primary),
                  title: const Text('Lifetime mined'),
                  subtitle: Text('${game.lifetimeMinedBtc.toStringAsFixed(6)} BTC'),
                ),
                ListTile(
                  leading: const Icon(Icons.timer, color: AppTheme.primary),
                  title: const Text('Sessions started'),
                  subtitle: Text('${game.totalSessionsStarted}'),
                  trailing: game.isSessionActive
                      ? const Chip(label: Text('Active', style: TextStyle(fontSize: 11)))
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium, color: AppTheme.primary),
                  title: const Text('Premium'),
                  subtitle: Text(game.isPremiumActive ? 'Active' : 'Not active'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add, color: AppTheme.primary),
                  title: const Text('Referral code'),
                  subtitle: Text(referral.myCode ?? 'Loading...'),
                  trailing: Text('Friends: ${referral.friends}'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: referral.canClaimReward('friends_1')
                            ? () async {
                                await game.grantDirectBtc(0.00005);
                                await referral.markClaimed('friends_1');
                              }
                            : null,
                        child: const Text('1 friend reward'),
                      ),
                      FilledButton(
                        onPressed: referral.canClaimReward('friends_5')
                            ? () async {
                                await game.grantRig('gpu_rig');
                                await referral.markClaimed('friends_5');
                              }
                            : null,
                        child: const Text('5 friends reward'),
                      ),
                      FilledButton(
                        onPressed: referral.canClaimReward('friends_10')
                            ? () async {
                                await game.activateBoost(duration: const Duration(hours: 24));
                                await referral.markClaimed('friends_10');
                              }
                            : null,
                        child: const Text('10 friends reward'),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.ac_unit, color: AppTheme.primary),
                  title: const Text('Cooling / Energy'),
                  subtitle: Text(
                    'Cooling ${energy.coolingLevel} · Power ${energy.powerLevel} · Solar ${energy.solarLevel} · Heat ${energy.heat.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primary),
            title: const Text('Sign out', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out'),
                  content: const Text(
                    'Do you want to sign out? If you\'re a guest, progress stays on this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
