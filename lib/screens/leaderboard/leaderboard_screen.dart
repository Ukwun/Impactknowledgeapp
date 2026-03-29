import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/achievement_controller.dart';
import '../../widgets/common/custom_widgets.dart';
import '../../config/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedTimeframe = 'all';

  @override
  void initState() {
    super.initState();
    Get.find<AchievementController>().fetchLeaderboard(
      timeframe: _selectedTimeframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AchievementController>();

    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppTheme.dark700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: Obx(() {
          if (ctrl.isLoading.value) return const LoadingIndicator();

          return CustomScrollView(
            slivers: [
              // ── Timeframe chips ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('All Time', 'all'),
                        const SizedBox(width: 10),
                        _chip('Monthly', 'monthly'),
                        const SizedBox(width: 10),
                        _chip('Weekly', 'weekly'),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Current user rank card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Obx(() {
                    final rank = ctrl.userRank.value;
                    if (rank == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary600, AppTheme.primary500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${rank.rank}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Rank',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${rank.points} Points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${rank.achievementCount} Achievements',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // ── Section header ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Rankings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ── Leaderboard entries ──
              if (ctrl.leaderboard.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No Data Yet',
                    subtitle: 'Earn points to appear on the leaderboard',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, index) {
                      final entry = ctrl.leaderboard[index];
                      final rank = index + 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: rank <= 3
                                ? AppTheme.secondary500.withValues(alpha: 0.10)
                                : AppTheme.dark600.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: rank <= 3
                                  ? AppTheme.secondary500.withValues(
                                      alpha: 0.45,
                                    )
                                  : AppTheme.dark400.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // rank badge
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: rank <= 3
                                      ? LinearGradient(
                                          colors: [
                                            _medalColor(rank),
                                            _medalColor(
                                              rank,
                                            ).withValues(alpha: 0.7),
                                          ],
                                        )
                                      : null,
                                  color: rank > 3 ? AppTheme.dark500 : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    color: rank <= 3
                                        ? Colors.white
                                        : AppTheme.textMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // name + achievements
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${entry.achievementCount} achievements',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // points
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary500.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${entry.points}',
                                  style: const TextStyle(
                                    color: AppTheme.primary400,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: ctrl.leaderboard.length),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final isSelected = _selectedTimeframe == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTimeframe = value);
        Get.find<AchievementController>().fetchLeaderboard(timeframe: value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.dark600,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary500
                : AppTheme.dark400.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return AppTheme.dark500;
    }
  }
}

