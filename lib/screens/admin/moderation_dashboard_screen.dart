import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../config/service_locator.dart';
import '../../services/moderation/moderation_service.dart';

class ModerationDashboardScreen extends StatefulWidget {
  const ModerationDashboardScreen({super.key});

  @override
  State<ModerationDashboardScreen> createState() =>
      _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends State<ModerationDashboardScreen> {
  late ModerationService _moderationService;
  String selectedFilter = 'pending';
  List<dynamic> flags = [];
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _moderationService = getIt<ModerationService>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final flagsResult = await _moderationService.getAdminFlags(
        status: selectedFilter,
      );
      final statsResult = await _moderationService.getModerationStats();

      setState(() {
        flags = flagsResult['data'] ?? [];
        stats = statsResult['stats'] ?? {};
        isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load moderation data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _resolveFlag(int flagId, String action) async {
    try {
      await _moderationService.resolveFlag(
        flagId: flagId,
        action: action,
        resolutionNote: 'Resolved by admin',
      );

      Get.snackbar(
        'Success',
        'Flag $action successfully',
        backgroundColor: AppTheme.primary500,
      );

      _loadData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to resolve flag: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(
        backgroundColor: AppTheme.dark800,
        title: const Text('Content Moderation'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Statistics
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _StatCard(
                          label: 'Total Flags',
                          value: stats['total_flags']?.toString() ?? '0',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Pending',
                          value: stats['pending_flags']?.toString() ?? '0',
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Approved',
                          value: stats['approved_flags']?.toString() ?? '0',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // Filter Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['pending', 'approved', 'rejected', 'all']
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(filter.toUpperCase()),
                                  selected: selectedFilter == filter,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => selectedFilter = filter);
                                      _loadData();
                                    }
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Flags List
                  if (flags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $selectedFilter flags',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: flags.length,
                      itemBuilder: (context, index) {
                        final flag = flags[index];
                        return _FlagCard(
                          flag: flag,
                          onApprove: () => _resolveFlag(flag['id'], 'approved'),
                          onReject: () => _resolveFlag(flag['id'], 'rejected'),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    this.color = AppTheme.primary500,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.dark700,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final dynamic flag;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _FlagCard({
    required this.flag,
    required this.onApprove,
    required this.onReject,
  });

  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'spam':
        return Colors.red;
      case 'inappropriate':
        return Colors.orange;
      case 'misleading':
        return Colors.yellow;
      case 'copyright':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dark700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flag['status'] == 'pending'
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReasonColor(flag['reason']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  flag['reason'].toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getReasonColor(flag['reason']),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(flag['status']),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  flag['status'].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content Info
          Text(
            '${flag['content_type']} #${flag['content_id']}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 8),

          // Reporter Info
          if (flag['full_name'] != null) ...[
            Text(
              'Reported by: ${flag['full_name']}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],

          if (flag['description'] != null) ...[
            Text(
              flag['description'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // Actions (only for pending)
          if (flag['status'] == 'pending')
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
