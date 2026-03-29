import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/achievement_controller.dart';
import '../../widgets/common/custom_widgets.dart';
import '../../config/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<AchievementController>().loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AchievementController>();

    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(
        title: const Text('Achievements'),
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
              // ── Points card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary600, AppTheme.primary500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Points',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${ctrl.userPoints.value?.totalPoints ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat(
                              'Achievements',
                              '${ctrl.userAchievements.length}',
                            ),
                            _vDivider(),
                            _stat(
                              'Streak',
                              '${ctrl.userPoints.value?.currentStreak ?? 0}',
                            ),
                            _vDivider(),
                            _stat(
                              'Level',
                              '${ctrl.userPoints.value?.level ?? 1}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Section header ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    'Your Badges',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ── Badge grid ──
              if (ctrl.userAchievements.isEmpty && ctrl.achievements.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No Achievements Yet',
                    subtitle: 'Complete courses and lessons to earn badges',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((ctx, index) {
                      final all = ctrl.achievements;
                      final unlocked = ctrl.userAchievements
                          .map((a) => a.achievementId)
                          .toList();
                      if (index >= all.length) return null;
                      final achievement = all[index];
                      final isUnlocked = unlocked.contains(achievement.id);

                      return GestureDetector(
                        onTap: () => _showDetail(
                          context,
                          achievement.name ?? achievement.title,
                          isUnlocked,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? AppTheme.secondary500.withValues(alpha: 0.12)
                                : AppTheme.dark600,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isUnlocked
                                  ? AppTheme.secondary500.withValues(alpha: 0.5)
                                  : AppTheme.dark400.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 34,
                                color: isUnlocked
                                    ? AppTheme.secondary500
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  achievement.name ?? achievement.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isUnlocked
                                        ? AppTheme.textLight
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: ctrl.achievements.length),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );

  Widget _vDivider() => Container(
    height: 36,
    width: 1,
    color: Colors.white.withValues(alpha: 0.2),
  );

  void _showDetail(BuildContext context, String name, bool isUnlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark700,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 56,
              color: isUnlocked ? AppTheme.secondary500 : AppTheme.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked ? 'Achievement unlocked!' : 'Not yet unlocked',
              style: TextStyle(
                color: isUnlocked ? AppTheme.primary400 : AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
