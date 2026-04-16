import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../providers/quiz_controller.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late QuizController _quizController;
  late PageController _pageController;
  int _currentQuestion = 0;

  @override
  void initState() {
    super.initState();
    _quizController = Get.find<QuizController>();
    _pageController = PageController();
    _quizController.startQuiz(widget.quizId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _answerQuestion(dynamic answer) {
    _quizController.submitAnswer(_currentQuestion, answer);
  }

  void _nextQuestion() {
    if (_currentQuestion < _quizController.questions.length - 1) {
      _currentQuestion++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      _currentQuestion--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitQuiz() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: const Text(
          'Are you sure you want to submit? You cannot change your answers after submission.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _quizController.submitQuiz();
              Get.back();
              Get.toNamed('/quiz-results');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text('Your progress will not be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ),
        body: Obx(() {
          if (_quizController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_quizController.questions.isEmpty) {
            return const Center(child: Text('No questions available'));
          }

          final questions = _quizController.questions;
          final progress = (_currentQuestion + 1) / questions.length;

          return Column(
            children: [
              // Timer and progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.dark300,
                  border: Border(bottom: BorderSide(color: AppTheme.dark400)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestion + 1} of ${questions.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            'Time: ${_quizController.remainingTime.value}s',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _quizController.remainingTime.value < 60
                                  ? Colors.red
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppTheme.dark400,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Questions
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestion = index;
                    });
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return _QuestionWidget(
                      question: questions[index],
                      onAnswerSelected: _answerQuestion,
                      selectedAnswer: _quizController.userResponses[index],
                    );
                  },
                ),
              ),
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.dark400)),
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentQuestion > 0
                          ? _previousQuestion
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _currentQuestion < questions.length - 1
                          ? _nextQuestion
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ),
              // Submit button
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Submit Quiz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _QuestionWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final Function(dynamic) onAnswerSelected;
  final dynamic selectedAnswer;

  const _QuestionWidget({
    required this.question,
    required this.onAnswerSelected,
    required this.selectedAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final type = question['type'] ?? 'multiple_choice';
    final options = question['options'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['questionText'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          if (type == 'multiple_choice')
            ..._buildMultipleChoiceOptions(options)
          else if (type == 'true_false')
            ..._buildTrueFalseOptions()
          else if (type == 'short_answer')
            ..._buildShortAnswerInput()
          else if (type == 'matching')
            ..._buildMatchingOptions(options),
        ],
      ),
    );
  }

  List<Widget> _buildMultipleChoiceOptions(List options) {
    return options
        .asMap()
        .entries
        .map(
          (entry) => _OptionButton(
            label: entry.value['text'] ?? '',
            isSelected: selectedAnswer == entry.key,
            onTap: () => onAnswerSelected(entry.key),
          ),
        )
        .toList();
  }

  List<Widget> _buildTrueFalseOptions() {
    return [
      _OptionButton(
        label: 'True',
        isSelected: selectedAnswer == true,
        onTap: () => onAnswerSelected(true),
      ),
      _OptionButton(
        label: 'False',
        isSelected: selectedAnswer == false,
        onTap: () => onAnswerSelected(false),
      ),
    ];
  }

  List<Widget> _buildShortAnswerInput() {
    return [
      TextField(
        cursorColor: AppTheme.primary500,
        style: const TextStyle(color: Colors.white),
        decoration: AppTheme.darkInput(hint: 'Type your answer...'),
        onChanged: (value) => onAnswerSelected(value),
      ),
    ];
  }

  List<Widget> _buildMatchingOptions(List options) {
    return [
      const Text(
        'Match the items on the left with the right options',
        style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
      ),
      const SizedBox(height: 16),
      ..._buildMatchingPairs(),
    ];
  }

  List<Widget> _buildMatchingPairs() {
    return List.generate(3, (index) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.darkCard(),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: AppTheme.darkCard(),
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: AppTheme.dark300,
                  style: const TextStyle(color: Colors.white),
                  items: ['Option A', 'Option B', 'Option C']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => onAnswerSelected(value),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppTheme.primary500 : AppTheme.dark400,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppTheme.primary500.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary500
                          : AppTheme.dark400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected
                        ? AppTheme.primary500
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
