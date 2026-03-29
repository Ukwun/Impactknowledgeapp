import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/course_controller.dart';
import '../../widgets/common/custom_widgets.dart';
import '../../widgets/course/course_widgets.dart';
import '../../config/routes.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  late ScrollController _scrollController;
  int _currentPage = 1;
  final List<String> _categories = [
    'All',
    'Technology',
    'Business',
    'Design',
    'Science',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    final courseController = Get.find<CourseController>();
    courseController.fetchAllCourses(page: 1);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _currentPage++;
      Get.find<CourseController>().fetchAllCourses(page: _currentPage);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseController = Get.find<CourseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Courses'),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                courseController.searchQuery.value = value;
                courseController.fetchAllCourses(
                  page: 1,
                  category: _selectedCategory == 'All'
                      ? null
                      : _selectedCategory,
                  search: value.isEmpty ? null : value,
                );
              },
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),

          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      _currentPage = 1;
                      courseController.fetchAllCourses(
                        page: 1,
                        category: category == 'All' ? null : category,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Courses List
          Expanded(
            child: Obx(() {
              if (courseController.isLoading.value &&
                  courseController.courses.isEmpty) {
                return const LoadingIndicator(message: 'Loading courses...');
              }

              if (courseController.courses.isEmpty) {
                return const EmptyState(
                  title: 'No Courses Found',
                  subtitle: 'Try adjusting your search or filters',
                );
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount:
                    courseController.courses.length +
                    (courseController.isLoading.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == courseController.courses.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: LoadingIndicator(message: 'Loading more...'),
                    );
                  }

                  final course = courseController.courses[index];
                  return CourseCard(
                    course: course,
                    onTap: () {
                      courseController.getCourseDetails(course.id);
                      Get.toNamed(AppRoutes.courseDetail);
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
