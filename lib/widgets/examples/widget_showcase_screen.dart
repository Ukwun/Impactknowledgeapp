import 'package:flutter/material.dart';
import '../common/common_widgets.dart';
import '../forms/app_forms.dart';
import '../../config/app_theme.dart';

/// Example screen demonstrating all widget library components
/// This serves as a comprehensive reference for developers
class WidgetLibraryShowcase extends StatefulWidget {
  const WidgetLibraryShowcase({Key? key}) : super(key: key);

  @override
  State<WidgetLibraryShowcase> createState() => _WidgetLibraryShowcaseState();
}

class _WidgetLibraryShowcaseState extends State<WidgetLibraryShowcase> {
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _notificationsEnabled = true;
  String _selectedOption = 'option1';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark400,
      appBar: AppBar(
        title: const Text('Widget Library Showcase'),
        backgroundColor: AppTheme.dark400,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARDS SECTION
            _buildSectionTitle('Cards'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  const Text(
                    'Basic Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a basic card with default styling',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppGradientCard(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.purple[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: const Column(
                children: [
                  Text(
                    'Gradient Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Card with gradient background',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // BUTTONS SECTION
            _buildSectionTitle('Buttons'),
            const SizedBox(height: 12),
            AppButton(
              label: 'Primary Button',
              onPressed: () => _showSnackBar('Primary button tapped!'),
            ),
            const SizedBox(height: 12),
            AppOutlineButton(
              label: 'Outline Button',
              onPressed: () => _showSnackBar('Outline button tapped!'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Loading Button',
              onPressed: () {
                setState(() => _isLoading = !_isLoading);
              },
              isLoading: _isLoading,
            ),

            const SizedBox(height: 24),

            // BADGES SECTION
            _buildSectionTitle('Badges'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppBadge(
                  label: 'In Progress',
                  backgroundColor: Colors.blue,
                  icon: Icons.hourglass_bottom,
                ),
                AppBadge(
                  label: 'Completed',
                  backgroundColor: Colors.green,
                  icon: Icons.check_circle,
                ),
                AppBadge(
                  label: 'Premium',
                  backgroundColor: Colors.amber,
                  icon: Icons.star,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // PROGRESS SECTION
            _buildSectionTitle('Progress'),
            const SizedBox(height: 12),
            AppProgressIndicator(value: 0.35, label: 'Course Completion'),
            const SizedBox(height: 16),
            AppProgressIndicator(
              value: 0.75,
              label: 'Download Progress',
              valueColor: Colors.green,
            ),

            const SizedBox(height: 24),

            // LIST ITEMS SECTION
            _buildSectionTitle('List Items'),
            const SizedBox(height: 12),
            AppListTile(
              leading: Icon(Icons.person, color: AppTheme.primary500),
              title: 'John Doe',
              subtitle: 'john@example.com',
              onTap: () => _showSnackBar('John Doe tapped!'),
            ),
            const SizedBox(height: 8),
            AppListTile(
              leading: Icon(Icons.book, color: AppTheme.primary500),
              title: 'Flutter Basics',
              subtitle: '45 lessons',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
              onTap: () => _showSnackBar('Course tapped!'),
            ),

            const SizedBox(height: 24),

            // INPUT FIELDS SECTION
            _buildSectionTitle('Input Fields'),
            const SizedBox(height: 12),
            AppTextField(
              hintText: 'Full Name',
              controller: _nameController,
              validator: FormValidators.validateRequired,
            ),
            const SizedBox(height: 12),
            AppTextField(
              hintText: 'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: FormValidators.validateEmail,
            ),
            const SizedBox(height: 12),
            AppTextField(
              hintText: 'Password',
              controller: _passwordController,
              obscureText: true,
              validator: FormValidators.validatePassword,
            ),

            const SizedBox(height: 24),

            // SELECTION WIDGETS SECTION
            _buildSectionTitle('Selection Items'),
            const SizedBox(height: 12),
            AppCheckbox(
              label: 'I agree to terms and conditions',
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() => _agreedToTerms = value);
              },
            ),
            const SizedBox(height: 12),
            AppRadioButton<String>(
              label: 'Option 1',
              value: 'option1',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() => _selectedOption = value!);
              },
            ),
            AppRadioButton<String>(
              label: 'Option 2',
              value: 'option2',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() => _selectedOption = value!);
              },
            ),
            const SizedBox(height: 12),
            AppSwitch(
              label: 'Enable Notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              description: 'Receive course updates',
            ),

            const SizedBox(height: 24),

            // EMPTY STATE SECTION
            _buildSectionTitle('Empty States'),
            const SizedBox(height: 12),
            AppCard(
              child: AppEmptyState(
                icon: Icons.inbox,
                title: 'No Items Yet',
                message: 'Start by creating your first item',
                actionLabel: 'Create Item',
                onActionPressed: () => _showSnackBar('Create item tapped!'),
              ),
            ),

            const SizedBox(height: 24),

            // LOADING SECTION
            _buildSectionTitle('Loading States'),
            const SizedBox(height: 12),
            AppLoadingShimmer(height: 80, borderRadius: 12),
            const SizedBox(height: 12),
            AppSkeletonLoading(itemCount: 2, itemHeight: 60),

            const SizedBox(height: 24),

            // DIVIDER
            AppDivider(),

            const SizedBox(height: 24),

            // FORM SECTION
            _buildSectionTitle('Dynamic Forms'),
            const SizedBox(height: 12),
            AppDynamicForm(
              fields: [
                FormFieldConfig(
                  name: 'course_name',
                  label: 'Course Name',
                  hintText: 'e.g., Flutter 101',
                  isRequired: true,
                  validator: FormValidators.validateRequired,
                ),
                FormFieldConfig(
                  name: 'course_description',
                  label: 'Description',
                  hintText: 'Describe your course',
                  isRequired: true,
                  validator: FormValidators.validateMinLength,
                ),
              ],
              submitLabel: 'Create Course',
              onSubmit: () => _showSnackBar('Form submitted!'),
              onChanges: (values) {
                debugPrint('Form values: $values');
              },
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary500.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary500, width: 1),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary500,
        ),
      ),
    );
  }
}
