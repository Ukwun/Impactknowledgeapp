import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/service_locator.dart';
import '../../services/api/api_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _apiService = getIt<ApiService>();

  final RxBool _loading = false.obs;
  final RxList<Map<String, dynamic>> _users = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _partners = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _testimonials =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _roleResources =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _moderationFlags =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> _moderationStats = <String, dynamic>{}.obs;
  final RxSet<int> _selectedFlagIds = <int>{}.obs;

  String _selectedNamespace = 'mentor';
  String _moderationStatus = 'pending';
  String _moderationContentType = 'all';
  String _moderationReason = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadUsers(),
      _loadTiers(),
      _loadContent(),
      _loadRoleResources(),
      _loadModeration(),
    ]);
  }

  Future<void> _loadUsers() async {
    _loading.value = true;
    try {
      final response = await _apiService.getAdminUsers(limit: 100);
      final data = response['data'];
      if (data is List) {
        _users.assignAll(data.cast<Map<String, dynamic>>());
      }
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _loadTiers() async {
    _loading.value = true;
    try {
      final response = await _apiService.getAdminMembershipTiers();
      final data = response['data'];
      if (data is List) {
        _tiers.assignAll(data.cast<Map<String, dynamic>>());
      }
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _loadContent() async {
    _loading.value = true;
    try {
      final partnersResponse = await _apiService.getAdminPartners();
      final testimonialsResponse = await _apiService.getAdminTestimonials();
      final partnersData = partnersResponse['data'];
      final testimonialsData = testimonialsResponse['data'];
      if (partnersData is List) {
        _partners.assignAll(partnersData.cast<Map<String, dynamic>>());
      }
      if (testimonialsData is List) {
        _testimonials.assignAll(testimonialsData.cast<Map<String, dynamic>>());
      }
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _loadRoleResources() async {
    _loading.value = true;
    try {
      final response = await _apiService.listRoleResources(
        _selectedNamespace,
        includeAll: true,
      );
      final data = response['data'];
      if (data is List) {
        _roleResources.assignAll(data.cast<Map<String, dynamic>>());
      }
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _loadModeration() async {
    _loading.value = true;
    try {
      final flagsResponse = await _apiService.getModerationFlags(
        status: _moderationStatus,
        contentType: _moderationContentType == 'all'
            ? null
            : _moderationContentType,
        reason: _moderationReason == 'all' ? null : _moderationReason,
        limit: 200,
      );
      final statsResponse = await _apiService.getModerationStats();

      final flagsData = flagsResponse['data'];
      if (flagsData is List) {
        _moderationFlags.assignAll(flagsData.cast<Map<String, dynamic>>());
      }

      if (statsResponse['stats'] is Map<String, dynamic>) {
        _moderationStats.assignAll(
          statsResponse['stats'] as Map<String, dynamic>,
        );
      }

      _selectedFlagIds.clear();
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _changeRole(int userId, String role) async {
    await _apiService.changeUserRole(userId, role);
    await _loadUsers();
  }

  Future<void> _toggleActive(int userId, bool active) async {
    if (active) {
      await _apiService.reactivateUser(userId);
    } else {
      await _apiService.deactivateUser(userId);
    }
    await _loadUsers();
  }

  Future<void> _createTier() async {
    final nameController = TextEditingController();
    final monthlyController = TextEditingController();
    final annualController = TextEditingController();
    final benefitsController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Membership Tier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: monthlyController,
                decoration: const InputDecoration(labelText: 'Monthly Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: annualController,
                decoration: const InputDecoration(labelText: 'Annual Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: benefitsController,
                decoration: const InputDecoration(
                  labelText: 'Benefits (comma-separated)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await _apiService.createMembershipTier({
                'name': nameController.text.trim(),
                'monthlyPrice':
                    double.tryParse(monthlyController.text.trim()) ?? 0,
                'annualPrice':
                    double.tryParse(annualController.text.trim()) ?? 0,
                'benefits': benefitsController.text.trim(),
              });
              if (mounted) {
                Get.back();
                await _loadTiers();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTier(int id) async {
    await _apiService.deleteMembershipTier(id);
    await _loadTiers();
  }

  Future<void> _createPartner() async {
    final nameController = TextEditingController();
    final websiteController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: websiteController,
              decoration: const InputDecoration(labelText: 'Website URL'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _apiService.createPartner({
                'name': nameController.text.trim(),
                'websiteUrl': websiteController.text.trim(),
              });
              if (mounted) {
                Get.back();
                await _loadContent();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editPartner(Map<String, dynamic> partner) async {
    final nameController = TextEditingController(
      text: partner['name']?.toString() ?? '',
    );
    final websiteController = TextEditingController(
      text: partner['website_url']?.toString() ?? '',
    );
    bool isActive = partner['is_active'] == true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Edit Partner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: websiteController,
                decoration: const InputDecoration(labelText: 'Website URL'),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _apiService.updatePartner(partner['id'] as int, {
                  'name': nameController.text.trim(),
                  'websiteUrl': websiteController.text.trim(),
                  'isActive': isActive,
                });
                if (mounted) {
                  Get.back();
                  await _loadContent();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestimonial() async {
    final quoteController = TextEditingController();
    final authorController = TextEditingController();
    final roleController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Testimonial'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quoteController,
                decoration: const InputDecoration(labelText: 'Quote'),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Author Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _apiService.createTestimonial({
                'quote': quoteController.text.trim(),
                'authorName': authorController.text.trim(),
                'authorRole': roleController.text.trim(),
              });
              if (mounted) {
                Get.back();
                await _loadContent();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTestimonial(Map<String, dynamic> testimonial) async {
    final quoteController = TextEditingController(
      text: testimonial['quote']?.toString() ?? '',
    );
    final authorController = TextEditingController(
      text: testimonial['author_name']?.toString() ?? '',
    );
    final roleController = TextEditingController(
      text: testimonial['author_role']?.toString() ?? '',
    );
    bool isActive = testimonial['is_active'] == true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Edit Testimonial'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quoteController,
                  decoration: const InputDecoration(labelText: 'Quote'),
                  minLines: 2,
                  maxLines: 4,
                ),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(labelText: 'Author'),
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Author Role'),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _apiService.updateTestimonial(testimonial['id'] as int, {
                  'quote': quoteController.text.trim(),
                  'authorName': authorController.text.trim(),
                  'authorRole': roleController.text.trim(),
                  'isActive': isActive,
                });
                if (mounted) {
                  Get.back();
                  await _loadContent();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveFlag(int flagId, String action) async {
    await _apiService.resolveModerationFlag(flagId, action: action);
    await _loadModeration();
  }

  Future<void> _bulkResolveSelectedFlags(String action) async {
    if (_selectedFlagIds.isEmpty) return;
    await _apiService.resolveModerationFlagsBulk(
      _selectedFlagIds.toList(),
      action: action,
    );
    await _loadModeration();
  }

  Future<void> _exportReport(String type) async {
    _loading.value = true;
    try {
      final savedPath = await _apiService.saveAdminReportToFile(type);
      if (savedPath == null || savedPath.isEmpty) {
        Get.snackbar('Export failed', 'No data returned');
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Export saved: $type'),
          content: SizedBox(
            width: 520,
            child: SelectableText(
              'Your export was saved successfully.\n\nPath:\n$savedPath',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _createRoleResource() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create ${_selectedNamespace.replaceAll('_', ' ')} resource',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _apiService.createRoleResource(_selectedNamespace, {
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
                'status': 'active',
              });
              if (mounted) {
                Get.back();
                await _loadRoleResources();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _editRoleResource(Map<String, dynamic> item) async {
    final titleController = TextEditingController(
      text: item['title']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: item['description']?.toString() ?? '',
    );
    String status = item['status']?.toString() ?? 'active';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Edit Resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('active')),
                  DropdownMenuItem(value: 'paused', child: Text('paused')),
                  DropdownMenuItem(value: 'archived', child: Text('archived')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => status = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _apiService.updateRoleResource(
                  _selectedNamespace,
                  item['id'].toString(),
                  {
                    'title': titleController.text.trim(),
                    'description': descController.text.trim(),
                    'status': status,
                  },
                );
                if (mounted) {
                  Get.back();
                  await _loadRoleResources();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Membership Tiers'),
            Tab(text: 'Landing Content'),
            Tab(text: 'Exports'),
            Tab(text: 'Role Resources'),
            Tab(text: 'Moderation'),
          ],
        ),
      ),
      body: Obx(() {
        if (_loading.value && _users.isEmpty && _tiers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final id = user['id'] as int;
                  final active = user['is_active'] == true;
                  final role = (user['role'] ?? 'student').toString();
                  return ListTile(
                    title: Text(
                      user['full_name']?.toString() ??
                          user['email']?.toString() ??
                          'User',
                    ),
                    subtitle: Text('${user['email'] ?? ''} • $role'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: role,
                          onChanged: (v) {
                            if (v != null) {
                              _changeRole(id, v);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'student',
                              child: Text('student'),
                            ),
                            DropdownMenuItem(
                              value: 'facilitator',
                              child: Text('facilitator'),
                            ),
                            DropdownMenuItem(
                              value: 'instructor',
                              child: Text('instructor'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('admin'),
                            ),
                          ],
                        ),
                        Switch(
                          value: active,
                          onChanged: (v) => _toggleActive(id, v),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _createTier,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Tier'),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadTiers,
                    child: ListView.builder(
                      itemCount: _tiers.length,
                      itemBuilder: (context, index) {
                        final tier = _tiers[index];
                        return ListTile(
                          title: Text(tier['name']?.toString() ?? 'Tier'),
                          subtitle: Text(
                            'Monthly: ${tier['monthly_price'] ?? 0}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteTier(tier['id'] as int),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Partners',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _createPartner,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Partner'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._partners.map(
                      (p) => ListTile(
                        title: Text(p['name']?.toString() ?? 'Partner'),
                        subtitle: Text(p['website_url']?.toString() ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editPartner(p),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                await _apiService.deletePartner(p['id'] as int);
                                await _loadContent();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Testimonials',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _createTestimonial,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Testimonial'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._testimonials.map(
                      (t) => ListTile(
                        title: Text(t['author_name']?.toString() ?? 'Author'),
                        subtitle: Text(
                          t['quote']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editTestimonial(t),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                await _apiService.deleteTestimonial(
                                  t['id'] as int,
                                );
                                await _loadContent();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unified Exports',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Operational exports for analytics and downstream BI.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _exportReport('users'),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Export Users'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _exportReport('payments'),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Export Payments'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _exportReport('course-performance'),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('Export Course Performance'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _exportReport('completion-cohorts'),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Export Completion Cohorts'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _selectedNamespace,
                        items: const [
                          DropdownMenuItem(
                            value: 'mentor',
                            child: Text('mentor'),
                          ),
                          DropdownMenuItem(
                            value: 'circle-member',
                            child: Text('circle-member'),
                          ),
                          DropdownMenuItem(
                            value: 'progress',
                            child: Text('progress'),
                          ),
                        ],
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() => _selectedNamespace = v);
                          await _loadRoleResources();
                        },
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _createRoleResource,
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadRoleResources,
                      child: ListView.builder(
                        itemCount: _roleResources.length,
                        itemBuilder: (context, index) {
                          final item = _roleResources[index];
                          return ListTile(
                            title: Text(
                              item['title']?.toString() ?? 'Untitled',
                            ),
                            subtitle: Text(
                              '${item['description'] ?? ''}\nStatus: ${item['status'] ?? 'active'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editRoleResource(item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await _apiService.deleteRoleResource(
                                      _selectedNamespace,
                                      item['id'].toString(),
                                    );
                                    await _loadRoleResources();
                                  },
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        DropdownButton<String>(
                                          value: _moderationStatus,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'pending',
                                              child: Text('pending'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'approved',
                                              child: Text('approved'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'rejected',
                                              child: Text('rejected'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'all',
                                              child: Text('all'),
                                            ),
                                          ],
                                          onChanged: (v) async {
                                            if (v == null) return;
                                            setState(
                                              () => _moderationStatus = v,
                                            );
                                            await _loadModeration();
                                          },
                                        ),
                                        DropdownButton<String>(
                                          value: _moderationContentType,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'all',
                                              child: Text('all types'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'course',
                                              child: Text('course'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'lesson',
                                              child: Text('lesson'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'comment',
                                              child: Text('comment'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'user',
                                              child: Text('user'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'assignment',
                                              child: Text('assignment'),
                                            ),
                                          ],
                                          onChanged: (v) async {
                                            if (v == null) return;
                                            setState(
                                              () => _moderationContentType = v,
                                            );
                                            await _loadModeration();
                                          },
                                        ),
                                        DropdownButton<String>(
                                          value: _moderationReason,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'all',
                                              child: Text('all reasons'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'spam',
                                              child: Text('spam'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'inappropriate',
                                              child: Text('inappropriate'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'misleading',
                                              child: Text('misleading'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'copyright',
                                              child: Text('copyright'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'other',
                                              child: Text('other'),
                                            ),
                                          ],
                                          onChanged: (v) async {
                                            if (v == null) return;
                                            setState(
                                              () => _moderationReason = v,
                                            );
                                            await _loadModeration();
                                          },
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _selectedFlagIds.isEmpty
                                              ? null
                                              : () => _bulkResolveSelectedFlags(
                                                  'approved',
                                                ),
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: Text(
                                            'Approve (${_selectedFlagIds.length})',
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _selectedFlagIds.isEmpty
                                              ? null
                                              : () => _bulkResolveSelectedFlags(
                                                  'rejected',
                                                ),
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                          ),
                                          label: const Text('Reject Selected'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pending: ${_moderationStats['pending_flags'] ?? 0} • Approved: ${_moderationStats['approved_flags'] ?? 0} • Rejected: ${_moderationStats['rejected_flags'] ?? 0}',
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: RefreshIndicator(
                                        onRefresh: _loadModeration,
                                        child: ListView.builder(
                                          itemCount: _moderationFlags.length,
                                          itemBuilder: (context, index) {
                                            final item =
                                                _moderationFlags[index];
                                            final id = item['id'] as int;
                                            final selected = _selectedFlagIds
                                                .contains(id);
                                            return ListTile(
                                              leading: Checkbox(
                                                value: selected,
                                                onChanged: (v) {
                                                  if (v == true) {
                                                    _selectedFlagIds.add(id);
                                                  } else {
                                                    _selectedFlagIds.remove(id);
                                                  }
                                                },
                                              ),
                                              title: Text(
                                                '${item['content_type'] ?? 'content'} #${item['content_id'] ?? '-'} • ${item['reason'] ?? 'issue'}',
                                              ),
                                              subtitle: Text(
                                                '${item['description'] ?? 'No description'}\nReported by: ${item['full_name'] ?? item['email'] ?? item['reported_by'] ?? '-'} • Status: ${item['status'] ?? 'pending'}',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              isThreeLine: true,
                                              trailing: Wrap(
                                                spacing: 4,
                                                children: [
                                                  IconButton(
                                                    tooltip: 'Approve',
                                                    onPressed: () =>
                                                        _resolveFlag(
                                                          id,
                                                          'approved',
                                                        ),
                                                    icon: const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Reject',
                                                    onPressed: () =>
                                                        _resolveFlag(
                                                          id,
                                                          'rejected',
                                                        ),
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Reset to pending',
                                                    onPressed: () =>
                                                        _resolveFlag(
                                                          id,
                                                          'pending',
                                                        ),
                                                    icon: const Icon(
                                                      Icons.hourglass_bottom,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
