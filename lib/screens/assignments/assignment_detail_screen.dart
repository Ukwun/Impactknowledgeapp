import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../providers/assignment_controller.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late AssignmentController _assignmentController;
  late TextEditingController _answerController;
  final List<String> _selectedFiles = [];
  Map<String, dynamic>? _assignment;

  @override
  void initState() {
    super.initState();
    _assignmentController = Get.find<AssignmentController>();
    _answerController = TextEditingController();
    _loadAssignmentDetail();
  }

  Future<void> _loadAssignmentDetail() async {
    _assignment = _assignmentController.getAssignmentById(widget.assignmentId);
    final submissionId =
        _assignment?['submissionId']?.toString() ??
        _assignment?['submission_id']?.toString();
    if (submissionId != null && submissionId.isNotEmpty) {
      await _assignmentController.getSubmission(submissionId);
    }
    setState(() {});
  }

  Future<void> _pickFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedFiles.add(image.path);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  void _submitAssignment() {
    if (_answerController.text.isEmpty && _selectedFiles.isEmpty) {
      Get.snackbar(
        'Error',
        'Please provide an answer or upload a file',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assignment?'),
        content: const Text(
          'Are you sure you want to submit? You may not be able to modify your submission after submission.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _assignmentController.submitAssignment(
                widget.assignmentId,
                _answerController.text,
                _selectedFiles,
              );
              Get.back();
              Get.back();
              Get.snackbar(
                'Success',
                'Assignment submitted successfully',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_assignment == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSubmissionOpen = DateTime.parse(
      _assignment!['dueDate'],
    ).isAfter(DateTime.now());
    final isSubmitted = _assignment!['submissionStatus'] != 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment title
            Text(
              _assignment!['title'] ?? 'Untitled',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _assignment!['description'] ?? '',
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),

            // Key information
            Container(
              decoration: AppTheme.darkCard(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Due Date',
                    value: _formatDate(_assignment!['dueDate']),
                  ),
                  const Divider(color: AppTheme.dark400),
                  _InfoRow(
                    label: 'Points',
                    value: '${_assignment!['points'] ?? 100} pts',
                  ),
                  const Divider(color: AppTheme.dark400),
                  _InfoRow(
                    label: 'Status',
                    value: _assignment!['submissionStatus']
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    valueColor: _getStatusColor(
                      _assignment!['submissionStatus'],
                    ),
                  ),
                  if (_assignment!['grade'] != null) ...[
                    const Divider(color: AppTheme.dark400),
                    _InfoRow(
                      label: 'Grade',
                      value: '${_assignment!['grade']}/100',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full description/instructions
            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: AppTheme.darkCard(),
              padding: const EdgeInsets.all(16),
              child: Text(
                _assignment!['fullDescription'] ??
                    'No detailed instructions provided.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submission section
            if (!isSubmitted) ...[
              const Text(
                'Your Submission',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Answer text field
              TextField(
                controller: _answerController,
                maxLines: 6,
                cursorColor: AppTheme.primary500,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.darkInput(
                  hint: 'Type your answer or explanation here...',
                ),
              ),
              const SizedBox(height: 16),

              // File upload
              Container(
                decoration: AppTheme.darkCard(),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSubmissionOpen ? _pickFile : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: isSubmissionOpen
                                    ? AppTheme.primary500
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Attach Files',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Click to upload PDF, DOC, or images',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_selectedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(color: AppTheme.dark400),
                            const SizedBox(height: 12),
                            ..._selectedFiles.map((file) {
                              final fileName = file.split('/').last;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      size: 20,
                                      color: AppTheme.primary500,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFiles.removeAt(
                                            _selectedFiles.indexOf(file),
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmissionOpen ? _submitAssignment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success500,
                    disabledBackgroundColor: Colors.grey[600],
                  ),
                  child: Text(
                    isSubmissionOpen
                        ? 'Submit Assignment'
                        : 'Submission Closed',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                decoration: AppTheme.darkCard(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Submission',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _assignment!['submissionContent'] ?? 'No text submission',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSubmissionFileActions(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute}';
    } catch (e) {
      return dateStr;
    }
  }

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

  Future<void> _openSubmissionFile(String submissionId) async {
    final url = await _assignmentController.resolveSubmissionFileUrl(
      submissionId,
    );

    if (url == null || url.isEmpty) {
      Get.snackbar(
        'File unavailable',
        'Unable to resolve file URL for this submission.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      Get.snackbar(
        'Invalid file URL',
        'The file URL is not valid.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      Get.snackbar(
        'Open failed',
        'Could not open the file. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildSubmissionFileActions() {
    final submission = _assignmentController.currentSubmission.value;
    final submissionId =
        submission?['id']?.toString() ??
        _assignment?['submissionId']?.toString() ??
        _assignment?['submission_id']?.toString();
    final fileUrl =
        submission?['fileUrl']?.toString() ??
        submission?['file_url']?.toString() ??
        _assignment?['fileUrl']?.toString() ??
        _assignment?['file_url']?.toString();

    if (submissionId == null ||
        submissionId.isEmpty ||
        fileUrl == null ||
        fileUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            await _openSubmissionFile(submissionId);
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Open or Download File'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await _assignmentController.deleteSubmissionFile(
              submissionId,
            );
            if (ok) {
              setState(() {
                _assignment?.remove('fileUrl');
                _assignment?.remove('file_url');
              });
              Get.snackbar(
                'Deleted',
                'Submission file removed',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete File'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
