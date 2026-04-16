import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'app_widgets.dart';

// ============================================
// FORM FIELD MODELS
// ============================================

class FormFieldConfig {
  final String name;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final bool isRequired;
  final bool obscureText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  FormFieldConfig({
    required this.name,
    required this.label,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.obscureText = false,
    this.prefixIcon,
    this.validator,
  });
}

// ============================================
// DYNAMIC FORM WIDGET
// ============================================

class AppDynamicForm extends StatefulWidget {
  final List<FormFieldConfig> fields;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isLoading;
  final void Function(Map<String, String>) onChanges;

  const AppDynamicForm({
    super.key,
    required this.fields,
    this.submitLabel = 'Submit',
    required this.onSubmit,
    this.isLoading = false,
    required this.onChanges,
  });

  @override
  State<AppDynamicForm> createState() =>
      _AppDynamicFormState();
}

class _AppDynamicFormState
    extends State<AppDynamicForm> {
  late Map<String, TextEditingController>
      _controllers;
  late GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _controllers = {};
    for (final field in widget.fields) {
      _controllers[field.name] =
          TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller
        in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState
        ?.validate() ??
        false) {
      final values =
          <String, String>{};
      _controllers.forEach(
        (key, controller) {
          values[key] =
              controller.text;
        },
      );
      widget.onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: () {
        final values =
            <String, String>{};
        _controllers.forEach(
          (key, controller) {
            values[key] =
                controller.text;
          },
        );
        widget.onChanges(values);
      },
      child: Column(
        children: [
          ...widget.fields
              .map(
                (field) => Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Text(
                        field
                            .label,
                        style:
                            const TextStyle(
                          fontSize:
                              14,
                          fontWeight:
                              FontWeight
                                  .w600,
                          color: Colors
                              .white,
                        ),
                      ),
                      if (field
                          .isRequired)
                        const Text(
                          ' *',
                          style:
                              TextStyle(
                            color: Colors
                                .red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  AppTextField(
                    hintText: field
                        .hintText,
                    controller:
                        _controllers[
                      field.name,
                    ]!,
                    keyboardType:
                        field
                            .keyboardType,
                    obscureText: field
                        .obscureText,
                    prefixIcon: field
                        .prefixIcon !=
                        null
                        ? Icon(
                      field
                          .prefixIcon,
                    )
                        : null,
                    validator:
                        field.validator,
                  ),
                ],
              ),
            ),
          )
              .toList(),
          const SizedBox(height: 24),
          AppButton(
            label: widget
                .submitLabel,
            onPressed:
                _submitForm,
            isLoading: widget
                .isLoading,
            isEnabled:
                !widget.isLoading,
          ),
        ],
      ),
    );
  }
}

// ============================================
// MULTI-STEP FORM WIDGET
// ============================================

class AppMultiStepForm
    extends StatefulWidget {
  final List<String> steps;
  final List<Widget> contents;
  final VoidCallback onCompleted;
  final bool isLoading;

  const AppMultiStepForm({
    super.key,
    required this.steps,
    required this.contents,
    required this.onCompleted,
    this.isLoading = false,
  });

  @override
  State<AppMultiStepForm> createState() =>
      _AppMultiStepFormState();
}

class _AppMultiStepFormState
    extends State<AppMultiStepForm> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep <
        widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      widget.onCompleted();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step Indicator
        Padding(
          padding: const EdgeInsets
              .only(bottom: 32),
          child: Row(
            children: [
              ...widget.steps
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration:
                            BoxDecoration(
                          shape: BoxShape
                              .circle,
                          color: entry
                                  .key <=
                              _currentStep
                              ? AppTheme
                                  .primary500
                              : AppTheme
                                  .dark400,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style:
                                const TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color: Colors
                                  .white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        entry.value,
                        style:
                            TextStyle(
                          fontSize: 12,
                          color: entry
                                  .key <=
                              _currentStep
                              ? Colors
                                  .white
                              : Colors
                                  .grey[600],
                        ),
                        textAlign:
                            TextAlign
                                .center,
                      ),
                    ],
                  ),
                ),
                  )
                  .toList(),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            child: widget.contents[
              _currentStep,
            ],
          ),
        ),

        // Navigation Buttons
        const SizedBox(height: 24),
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppOutlineButton(
                  label: 'Previous',
                  onPressed:
                      _previousStep,
                ),
              ),
            if (_currentStep > 0)
              const SizedBox(
                width: 12,
              ),
            Expanded(
              child: AppButton(
                label: _currentStep ==
                    widget.steps
                        .length -
                    1
                    ? 'Complete'
                    : 'Next',
                onPressed: _nextStep,
                isLoading:
                    widget.isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================
// FORM VALIDATION UTILS
// ============================================

class FormValidators {
  static String? validateEmail(
    String? value,
  ) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    const emailPattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    if (!RegExp(emailPattern)
        .hasMatch(value ?? '')) {
      return 'Invalid email format';
    }
    return null;
  }

  static String? validatePassword(
    String? value,
  ) {
    if (value?.isEmpty ?? true) {
      return 'Password is required';
    }
    if ((value ?? '').length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]')
        .hasMatch(value ?? '')) {
      return 'Password must contain uppercase letter';
    }
    if (!RegExp(r'[a-z]')
        .hasMatch(value ?? '')) {
      return 'Password must contain lowercase letter';
    }
    if (!RegExp(r'[0-9]')
        .hasMatch(value ?? '')) {
      return 'Password must contain number';
    }
    return null;
  }

  static String? validatePhoneNumber(
    String? value,
  ) {
    if (value?.isEmpty ?? true) {
      return 'Phone number is required';
    }
    const phonePattern =
        r'^\+?[\d\s\-()]{10,}$';
    if (!RegExp(phonePattern)
        .hasMatch(value ?? '')) {
      return 'Invalid phone number';
    }
    return null;
  }

  static String? validateRequired(
    String? value,
  ) {
    if (value?.isEmpty ?? true) {
      return 'This field is required';
    }
    return null;
  }

  static String? validateMinLength(
    String? value,
    int minLength,
  ) {
    if (value?.isEmpty ?? true) {
      return 'This field is required';
    }
    if ((value ?? '').length <
        minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }

  static String? validateMaxLength(
    String? value,
    int maxLength,
  ) {
    if ((value ?? '').length >
        maxLength) {
      return 'Must be at most $maxLength characters';
    }
    return null;
  }

  static String? validateUrl(
    String? value,
  ) {
    if (value?.isEmpty ?? true) {
      return 'URL is required';
    }
    const urlPattern =
        r'^https?://[^\s/$.?#].[^\s]*$';
    if (!RegExp(urlPattern)
        .hasMatch(value ?? '')) {
      return 'Invalid URL format';
    }
    return null;
  }
}

// ============================================
// CHECKBOX & RADIO WIDGETS
// ============================================

class AppCheckbox extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const AppCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  State<AppCheckbox> createState() =>
      _AppCheckboxState();
}

class _AppCheckboxState
    extends State<AppCheckbox> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: widget.value,
          onChanged: (newValue) {
            widget.onChanged(
              newValue ?? false,
            );
          },
          activeColor:
              widget.activeColor ??
                  AppTheme.primary500,
          side: const BorderSide(
            color: AppTheme.dark400,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              widget
                  .onChanged(!widget.value);
            },
            child: Text(
              widget.label,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppRadioButton<T>
    extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const AppRadioButton({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor:
              AppTheme.primary500,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Text(
              label,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// SWITCH WIDGET
// ============================================

class AppSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  const AppSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
      children: [
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (description !=
                null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color: AppTheme
                      .textMuted,
                ),
              ),
            ],
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor:
              AppTheme.primary500,
        ),
      ],
    );
  }
}
