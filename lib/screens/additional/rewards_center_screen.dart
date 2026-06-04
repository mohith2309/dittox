import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';
import '../../utils/engagement_store.dart';
import '../../widgets/common/pill_appbar_title.dart';

class RewardsCenterScreen extends StatefulWidget {
  static const routeName = '/rewardsCenter';

  const RewardsCenterScreen({super.key});

  @override
  State<RewardsCenterScreen> createState() => _RewardsCenterScreenState();
}

class _RewardsCenterScreenState extends State<RewardsCenterScreen> {
  int _points = 0;
  bool _canCheckIn = false;
  int _lastSpinReward = 0;
  String get _referralCode {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return 'DITTOX';
    // Generate a short unique code from the user's UID
    return 'DX${uid.substring(0, 6).toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    final points = await EngagementStore.getPoints();
    final canCheckIn = await EngagementStore.canCheckInToday();
    if (!mounted) return;
    setState(() {
      _points = points;
      _canCheckIn = canCheckIn;
    });
  }

  Future<void> _dailyCheckIn() async {
    final points = await EngagementStore.checkIn();
    if (!mounted) return;
    setState(() {
      _points = points;
      _canCheckIn = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily check-in complete. +10 points')),
    );
  }

  Future<void> _spinWheel() async {
    final reward = await EngagementStore.spinWheel();
    final points = await EngagementStore.getPoints();
    if (!mounted) return;
    setState(() {
      _lastSpinReward = reward;
      _points = points;
    });
  }

  Future<void> _copyReferral() async {
    await Clipboard.setData(
      ClipboardData(text: 'Use $_referralCode on Dittox and get rewards.'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral message copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Rewards',
          icon: Icons.workspace_premium_rounded,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 12),
          _buildActionsCard(),
          const SizedBox(height: 12),
          _buildMilestonesCard(),
          const SizedBox(height: 12),
          _buildReferralCard(),
          const SizedBox(height: 12),
          _buildBadgesCard(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorPallets.deepBlue, Color(0xFF00A6A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dittox Points',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '$_points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _points >= 100
                ? 'Gold tier unlocked'
                : '${100 - _points} points to Gold tier',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_points.clamp(0, 100)) / 100,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Earn More',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canCheckIn ? _dailyCheckIn : null,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(_canCheckIn ? 'Check In' : 'Checked In'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _spinWheel,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Spin'),
                  ),
                ),
              ],
            ),
            if (_lastSpinReward > 0) ...[
              const SizedBox(height: 10),
              Text('Last spin reward: +$_lastSpinReward points'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard() {
    final milestones = <int>[25, 50, 100, 250];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Milestone Rewards',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...milestones.map((target) {
              final done = _points >= target;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color:
                      done ? ColorPallets.deepBlue : ColorPallets.textSecondary,
                ),
                title: Text('$target points'),
                subtitle: Text(done ? 'Unlocked' : 'Keep printing to unlock'),
                trailing: Text(done ? 'Ready' : '${target - _points} left'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invite Friends',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Share your referral code and track rewards locally.'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorPallets.lightPurplishWhile.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _referralCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ColorPallets.deepBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyReferral,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Invite Message'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesCard() {
    final badges = [
      ('First Print', Icons.print_rounded, true),
      ('Daily Visitor', Icons.today_rounded, !_canCheckIn),
      ('Gold Saver', Icons.local_offer_rounded, _points >= 100),
      ('Power User', Icons.bolt_rounded, _points >= 250),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Badges', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((badge) {
                return Chip(
                  avatar: Icon(
                    badge.$2,
                    size: 18,
                    color: badge.$3
                        ? ColorPallets.deepBlue
                        : ColorPallets.textSecondary,
                  ),
                  label: Text(badge.$1),
                  backgroundColor: badge.$3
                      ? ColorPallets.lightBlue.withValues(alpha: 0.18)
                      : ColorPallets.cardBorder.withValues(alpha: 0.45),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
