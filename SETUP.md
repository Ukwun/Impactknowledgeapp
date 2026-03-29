# ImpactKnowledge Flutter App - Setup Guide

## Complete Setup Instructions

### Step 1: Install Flutter

If you haven't installed Flutter yet:

```bash
# Download from https://flutter.dev/docs/get-started/install
# Then verify installation
flutter doctor
```

All items should show ✓ for proper development setup.

### Step 2: Install Dependencies

```bash
cd c:\DEV3\ImpactEdu\impactknowledge_app
flutter pub get
```

### Step 3: Generate JSON Serialization Files

The app uses `json_serializable` for model serialization:

```bash
flutter pub run build_runner build
```

This generates `.g.dart` files for all models. If you need to regenerate:

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4: Environment Configuration

**Edit `lib/config/app_config.dart`:**

```dart
// Update with your backend URL
static const String apiBaseUrl = 'http://localhost:3000/api'; // or your server

// Update with Flutterwave credentials
static const String flutterwavePublicKey = 'pk_test_xxxxx'; // Your Flutterwave public key
```

### Step 5: Run the App

#### On Android Emulator:
```bash
flutter emulators
flutter emulators launch <emulator_id>
flutter run
```

#### On Physical Device:
```bash
# Connect device and enable USB debugging
flutter devices
flutter run -d <device_id>
```

#### On iOS:
```bash
open ios/Runner.xcworkspace
# Or run directly:
flutter run -d "iPhone 15"
```

## 🏗️ Architecture Overview

### Clean Architecture Pattern

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens & UI Components)          │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│   Business Logic Layer              │
│  (State Managers & Services)        │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│   Data Access Layer                 │
│  (Services & API Clients)           │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│   Data Layer                        │
│  (Models & Local Storage)           │
└─────────────────────────────────────┘
```

### Directory Purposes

**`config/`** - Application-wide configuration
- API endpoints
- Feature flags
- Service locator setup
- Environment variables

**`models/`** - Data models
- Match Prisma schema
- JSON serialization
- Type safety

**`services/`** - Business logic
- API communication (Dio)
- Authentication logic
- Course management
- Payment processing
- Achievement system

**`screens/`** - UI Pages
- Authentication flows
- Dashboard and home
- Course browsing and learning
- Achievements display
- Leaderboard
- Payment screens
- User profile

**`widgets/`** - Reusable Components
- Custom buttons
- Input fields
- Cards
- Loaders
- Error dialogs

**`providers/`** - State Management
- Built with GetX controllers
- Reactive state updates
- Business logic organization

**`storage/`** - Persistence Layer
- Hive for complex objects
- SharedPreferences for simple values
- Secure storage for tokens

## 📲 Feature Implementations

### 1. Authentication Flow

```dart
// lib/services/auth/auth_service.dart

// Login
await authService.login('email@example.com', 'password');

// Token automatically saved to secure storage
// Attached to all API requests

// Logout
await authService.logout();
```

### 2. Course Learning Flow

```dart
// 1. Get enrolled courses
final enrollments = await courseService.getUserEnrollments();

// 2. Get course modules
final modules = await courseService.getCourseModules(courseId);

// 3. Get lessons from module
final lessons = await courseService.getModuleLessons(moduleId);

// 4. Track progress
await courseService.updateLessonProgress(lessonId, status: 'completed');

// 5. Get completion percentage
final progress = await courseService.getEnrollmentProgress(enrollmentId);
```

### 3. Payment Integration

```dart
// 1. Get membership tiers
final tiers = await paymentService.getMembershipTiers();

// 2. Initiate payment
final response = await paymentService.initiateMembershipPayment(
  tierId,
  email: 'user@example.com',
  phoneNumber: '1234567890',
  billingCycle: 'monthly',
);

// 3. Verify payment
final payment = await paymentService.verifyPayment(reference);
```

### 4. Achievement System

```dart
// 1. Get all achievements
final achievements = await achievementService.getAllAchievements();

// 2. Get user achievements
final userAchievements = await achievementService.getUserAchievements();

// 3. Get leaderboard
final leaderboard = await achievementService.getLeaderboard();

// 4. Get user rank
final rank = await achievementService.getUserRank();
```

## 🔗 API Integration Points

All API endpoints are accessed through `ApiService`:

```dart
// GET requests
await apiService.get<T>('/endpoint', fromJson: (data) => Model.fromJson(data));

// POST requests
await apiService.post<T>('/endpoint', data: {...});

// File uploads
await apiService.uploadFile<T>('/endpoint', filePath);

// Token management
await apiService.saveToken(token);
await apiService.clearToken();
```

## 🛠️ Development Workflow

### Adding a New Feature

1. **Create Model** (`lib/models/*/`) - Define data structure
2. **Create Service** (`lib/services/*/`) - Implement API calls
3. **Create State Manager** (`lib/providers/`) - Manage state with GetX
4. **Create Screens** (`lib/screens/*/`) - Build UI
5. **Create Widgets** (`lib/widgets/`) - Reusable components
6. **Register in Service Locator** (`lib/config/service_locator.dart`)

### Code Generation

After modifying models or adding json_serializable:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Code Quality

```bash
# Format code
dart format lib/

# Analyze code
dart analyze

# Run tests
flutter test
```

## 🐛 Debugging

### Enable Verbose Logging

```bash
flutter run -v
```

### API Request Logging

```dart
// In ApiService, logs are automatically enabled via Logger
// Check console for all HTTP requests/responses
```

### Flutter DevTools

```bash
flutter pub global activate devtools
devtools

# Or launch from IDE
```

## 📦 Building for Production

### Android APK

```bash
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Archive)

```bash
flutter build ios --release

# Then open Xcode to submit to App Store
```

## 🔧 Troubleshooting

### Issue: Build fails with "could not find lib/models/auth/user_model.g.dart"

**Solution**: Run build runner
```bash
flutter pub run build_runner build
```

### Issue: API calls fail with 401 Unauthorized

**Solution**: Check token is being saved and sent
```dart
// In ApiService, verify Authorization header is set
final token = await apiService._getToken();
// Should not be null if logged in
```

### Issue: Dio timeout on API calls

**Solution**: Increase timeout or check backend connectivity
```dart
// In app_config.dart
static const Duration apiTimeout = Duration(seconds: 60); // Increase if needed
```

### Issue: Flutterwave payment not working

**Solution**: Verify public key and test mode
```dart
// In app_config.dart
static const String flutterwavePublicKey = 'pk_test_xxxxx'; // Must be correct

// Ensure working in test mode initially
```

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [GetX Documentation](https://github.com/jonataslaw/getx)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Flutterwave Docs](https://developer.flutterwave.com)

## 🚀 Next Steps

1. Build authentication screens
2. Implement course browsing UI
3. Create lesson player component
4. Build payment UI flow
5. Implement local notifications
6. Add offline support
7. Optimize performance
8. Add analytics

## 💬 Support

For issues:
1. Check console output with `flutter run -v`
2. Review error messages carefully
3. Check API is running and accessible
4. Verify configuration matches your setup
