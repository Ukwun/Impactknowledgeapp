import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/course_controller.dart';

class LessonContentEditorScreen extends StatefulWidget {
  const LessonContentEditorScreen({super.key});

  @override
  State<LessonContentEditorScreen> createState() =>
      _LessonContentEditorScreenState();
}

class _LessonContentEditorScreenState extends State<LessonContentEditorScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _minutesController = TextEditingController(text: '20');
  final _formKey = GlobalKey<FormState>();

  late final CourseController _courseController;
  String? _courseId;
  String? _selectedModuleId;
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    _courseController = Get.find<CourseController>();

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _courseId = args['courseId']?.toString();
    }

    if (_courseId != null) {
      _courseController.getCourseModules(_courseId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _wrapSelection(String before, String after) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (sel.start < 0 || sel.end < 0) return;
    final start = sel.start;
    final end = sel.end;
    final selected = text.substring(start, end);
    final updated = text.replaceRange(start, end, '$before$selected$after');
    _contentController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: start + before.length + selected.length + after.length,
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(onPressed: onTap, icon: Icon(icon), tooltip: tooltip);
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null || _selectedModuleId == null) {
      Get.snackbar('Missing fields', 'Please select course module');
      return;
    }

    final lesson = await _courseController.createLessonForCourse(
      _courseId!,
      moduleId: _selectedModuleId!,
      title: _titleController.text.trim(),
      description: _summaryController.text.trim(),
      contentBody: _contentController.text,
      contentType: 'rich_text',
      durationMinutes: int.tryParse(_minutesController.text.trim()),
    );

    if (lesson != null && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Lesson Editor'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _previewMode = !_previewMode),
            child: Text(_previewMode ? 'Edit' : 'Preview'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Lesson Title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Lesson Summary'),
                maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final modules = _courseController.courseModules;
                      return DropdownButtonFormField<String>(
                        value: _selectedModuleId,
                        hint: const Text('Select module'),
                        items: modules
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m.id,
                                child: Text(m.title),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedModuleId = v),
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _minutesController,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            if (!_previewMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 4,
                  children: [
                    _toolbarButton(
                      Icons.format_bold,
                      'Bold',
                      () => _wrapSelection('**', '**'),
                    ),
                    _toolbarButton(
                      Icons.format_italic,
                      'Italic',
                      () => _wrapSelection('*', '*'),
                    ),
                    _toolbarButton(
                      Icons.title,
                      'Heading',
                      () => _wrapSelection('\n## ', ''),
                    ),
                    _toolbarButton(
                      Icons.format_list_bulleted,
                      'Bullet list',
                      () => _wrapSelection('\n- ', ''),
                    ),
                    _toolbarButton(
                      Icons.link,
                      'Link',
                      () => _wrapSelection('[', '](https://)'),
                    ),
                    _toolbarButton(
                      Icons.code,
                      'Code',
                      () => _wrapSelection('`', '`'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _previewMode
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _contentController.text.isEmpty
                                ? 'Preview will appear here.'
                                : _contentController.text,
                          ),
                        ),
                      )
                    : TextFormField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText:
                              'Rich Content (supports markdown-style formatting)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Lesson content is required'
                            : null,
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saveLesson,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Publish Lesson Content'),
          ),
        ),
      ),
    );
  }
}
