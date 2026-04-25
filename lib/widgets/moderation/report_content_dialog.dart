import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../config/service_locator.dart';
import '../../services/moderation/moderation_service.dart';

class ReportContentDialog extends StatefulWidget {
  final String contentType; // 'course', 'lesson', 'comment', 'user'
  final int contentId;
  final String? contentTitle;

  const ReportContentDialog({
    super.key,
    required this.contentType,
    required this.contentId,
    this.contentTitle,
  });

  @override
  State<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  late ModerationService _moderationService;
  String selectedReason = 'spam';
  final descriptionController = TextEditingController();
  bool isSubmitting = false;

  final reasons = [
    ('spam', 'Spam or Scam'),
    ('inappropriate', 'Inappropriate Content'),
    ('misleading', 'Misleading Information'),
    ('copyright', 'Copyright Violation'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _moderationService = getIt<ModerationService>();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (selectedReason.isEmpty) {
      Get.snackbar('Error', 'Please select a reason');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await _moderationService.flagContent(
        contentType: widget.contentType,
        contentId: widget.contentId,
        reason: selectedReason,
        description: descriptionController.text.isNotEmpty
            ? descriptionController.text
            : null,
      );

      Get.back();
      Get.snackbar(
        'Success',
        'Thank you for reporting. Our moderation team will review this content.',
        backgroundColor: AppTheme.primary500,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit report: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.dark700,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.flag, color: AppTheme.danger500),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Report Content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),

              if (widget.contentTitle != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dark800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'About: ${widget.contentTitle}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Reason Selection
              const Text(
                'What\'s wrong with this content?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              ...reasons.map((r) {
                final (key, label) = r;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => selectedReason = key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selectedReason == key
                            ? AppTheme.primary500.withValues(alpha: 0.2)
                            : AppTheme.dark800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedReason == key
                              ? AppTheme.primary500
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: key,
                            groupValue: selectedReason,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => selectedReason = v);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Additional Details
              const Text(
                'Additional Details (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Provide more context...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary500),
                  ),
                  filled: true,
                  fillColor: AppTheme.dark800,
                ),
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSubmitting ? null : () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger500,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Text(
                'Your report helps us keep the community safe. All reports are reviewed by our moderation team.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
