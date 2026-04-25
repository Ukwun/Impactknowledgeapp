import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/service_locator.dart';
import '../../services/api/api_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final ApiService _apiService = getIt<ApiService>();
  final TextEditingController _queryController = TextEditingController();

  String _selectedType = 'all';
  bool _loading = false;
  Map<String, dynamic> _results = {};

  final List<String> _types = [
    'all',
    'courses',
    'lessons',
    'assignments',
    'quizzes',
    'events',
    'users',
  ];

  Future<void> _runSearch() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) return;

    setState(() => _loading = true);
    final response = await _apiService.globalSearch(q, type: _selectedType);
    final data = response['data'];
    setState(() {
      _results = data is Map<String, dynamic> ? data : {};
      _loading = false;
    });
  }

  Widget _section(
    String title,
    List list,
    IconData icon,
    VoidCallback? onViewAll,
  ) {
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.darkCard(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary400),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 8),
          ...list
              .take(4)
              .map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    (item['title'] ?? item['name'] ?? 'Untitled').toString(),
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                  subtitle: Text(
                    (item['description'] ?? item['course_title'] ?? '')
                        .toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  onTap: () {
                    if (title == 'Courses') {
                      Get.toNamed(
                        AppRoutes.courseDetail,
                        arguments: item['id'].toString(),
                      );
                    } else if (title == 'Assignments') {
                      Get.toNamed(
                        AppRoutes.assignmentDetail,
                        arguments: item['id'].toString(),
                      );
                    } else if (title == 'Quizzes') {
                      Get.toNamed(
                        AppRoutes.quiz,
                        arguments: item['id'].toString(),
                      );
                    } else if (title == 'Events') {
                      Get.toNamed(
                        AppRoutes.eventDetail,
                        arguments: item['id'].toString(),
                      );
                    }
                  },
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(
        backgroundColor: AppTheme.dark700,
        title: const Text('Global Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText:
                    'Search courses, lessons, quizzes, assignments, events',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.dark700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.primary400),
                  onPressed: _runSearch,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final t = _types[index];
                  final selected = _selectedType == t;
                  return ChoiceChip(
                    label: Text(t[0].toUpperCase() + t.substring(1)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedType = t);
                      if (_queryController.text.trim().isNotEmpty) {
                        _runSearch();
                      }
                    },
                    selectedColor: AppTheme.primary500,
                    backgroundColor: AppTheme.dark700,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppTheme.textMuted,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'Search to discover content across the platform',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView(
                      children: [
                        _section(
                          'Courses',
                          _results['courses'] ?? [],
                          Icons.school_outlined,
                          null,
                        ),
                        _section(
                          'Lessons',
                          _results['lessons'] ?? [],
                          Icons.play_lesson_outlined,
                          null,
                        ),
                        _section(
                          'Assignments',
                          _results['assignments'] ?? [],
                          Icons.assignment_outlined,
                          null,
                        ),
                        _section(
                          'Quizzes',
                          _results['quizzes'] ?? [],
                          Icons.quiz_outlined,
                          null,
                        ),
                        _section(
                          'Events',
                          _results['events'] ?? [],
                          Icons.event_outlined,
                          null,
                        ),
                        _section(
                          'Users',
                          _results['users'] ?? [],
                          Icons.people_outline,
                          null,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
