import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../providers/assignment_controller.dart';

class AssignmentListScreen extends StatefulWidget {
  final String courseId;

  const AssignmentListScreen({super.key, required this.courseId});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  late AssignmentController _assignmentController;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _assignmentController = Get.put(AssignmentController());
    _assignmentController.loadAssignments(widget.courseId);
  }

  List<Map<String, dynamic>> _getFilteredAssignments() {
    final assignments = _assignmentController.assignments;

    if (_filterStatus == 'all') return assignments;
    if (_filterStatus == 'pending') {
      return assignments
          .where((a) => DateTime.parse(a['dueDate']).isAfter(DateTime.now()))
          .toList();
    }
    if (_filterStatus == 'submitted') {
      return assignments
          .where((a) => a['submissionStatus'] == 'submitted')
          .toList();
    }
    if (_filterStatus == 'graded') {
      return assignments
          .where((a) => a['submissionStatus'] == 'graded')
          .toList();
    }

    return assignments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: _filterStatus == 'all',
                  onTap: () => setState(() => _filterStatus = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  isActive: _filterStatus == 'pending',
                  onTap: () => setState(() => _filterStatus = 'pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Submitted',
                  isActive: _filterStatus == 'submitted',
                  onTap: () => setState(() => _filterStatus = 'submitted'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Graded',
                  isActive: _filterStatus == 'graded',
                  onTap: () => setState(() => _filterStatus = 'graded'),
                ),
              ],
            ),
          ),
          // Assignments list
          Expanded(
            child: Obx(() {
              if (_assignmentController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = _getFilteredAssignments();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No assignments found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final assignment = filtered[index];
                  return _AssignmentCard(
                    assignment: assignment,
                    onTap: () {
                      Get.toNamed(
                        '/assignment-detail',
                        arguments: assignment['id'],
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onTap;

  const _AssignmentCard({required this.assignment, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppTheme.success500;
      case 'graded':
        return AppTheme.primary500;
      case 'pending':
        return AppTheme.warning500;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  bool _isOverdue() {
    try {
      return DateTime.parse(assignment['dueDate']).isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _isOverdue();
    final statusColor = _getStatusColor(assignment['submissionStatus']);
    final dueDate = _formatDate(assignment['dueDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.darkCard(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assignment['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        assignment['submissionStatus']
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dueDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isOverdue ? Colors.red : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (assignment['grade'] != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Grade',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${assignment['grade']}/100',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary500 : AppTheme.dark400,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary500 : AppTheme.dark400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
