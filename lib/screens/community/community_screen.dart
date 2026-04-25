import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../config/service_locator.dart';
import '../../services/api/api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ApiService _apiService = getIt<ApiService>();
  bool _loading = true;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    final response = await _apiService.listRoleResources(
      'circle-member',
      includeAll: true,
    );
    final data = response['data'];
    setState(() {
      _posts = data is List
          ? data
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList()
          : [];
      _loading = false;
    });
  }

  Future<void> _createPost() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Community Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Post'),
              minLines: 4,
              maxLines: 7,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  bodyController.text.trim().isEmpty) {
                return;
              }
              await _apiService.createRoleResource('circle-member', {
                'title': titleController.text.trim(),
                'description': bodyController.text.trim(),
                'status': 'active',
                'metadata': {'kind': 'post'},
              });
              if (mounted) {
                Get.back();
                await _loadPosts();
              }
            },
            child: const Text('Post'),
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
        title: const Text('Community'),
        backgroundColor: AppTheme.dark700,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Post'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No community posts yet',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.darkCard(radius: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title']?.toString() ?? 'Untitled',
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['description']?.toString() ?? '',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary500.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (post['status'] ?? 'active').toString(),
                                style: const TextStyle(
                                  color: AppTheme.primary400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              post['created_at']?.toString().split('T').first ??
                                  '',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
