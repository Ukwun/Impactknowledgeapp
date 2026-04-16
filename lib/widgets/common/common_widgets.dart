/// Comprehensive reusable widget library for ImpactKnowledge Education app
///
/// This library contains all commonly used UI components organized by category:
/// - Cards (AppCard, AppGradientCard)
/// - Buttons (AppButton, AppOutlineButton)
/// - Input fields (AppTextField)
/// - Progress (AppProgressIndicator)
/// - Badges & Status (AppBadge)
/// - List Items (AppListTile)
/// - Empty States (AppEmptyState)
/// - Dividers (AppDivider)
/// - Loading (AppLoadingShimmer, AppSkeletonLoading)
///
/// ## Usage Examples
///
/// ### Simple Card
/// ```dart
/// AppCard(
///   child: Text('Hello World'),
/// )
/// ```
///
/// ### Button with Loading
/// ```dart
/// AppButton(
///   label: 'Submit',
///   isLoading: isLoading,
///   onPressed: submitForm,
/// )
/// ```
///
/// ### Text Field with Validation
/// ```dart
/// AppTextField(
///   hintText: 'Email',
///   controller: emailController,
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) {
///     if (value?.isEmpty ?? true) return 'Required';
///     return null;
///   },
/// )
/// ```
///
/// ## Theme Integration
/// All widgets use the AppTheme color scheme. Customize colors in:
/// `lib/config/app_theme.dart`
///
/// ## Performance Notes
/// - Widgets use StatefulWidget only when necessary (e.g., AppTextField for obscure toggle)
/// - All widgets are optimized for performance
/// - Use const constructors where possible

export 'app_widgets.dart';
