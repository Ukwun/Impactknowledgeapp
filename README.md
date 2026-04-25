# ImpactKnowledge Mobile App (Flutter)

A complete Flutter mobile application for the ImpactKnowledge online learning platform. This app mirrors all functionality from the web version with a native mobile-first experience.

## 📱 Features

### ✅ Implemented
- **Authentication System**
  - User registration and login
  - Token-based authentication (JWT)
  - Password reset & forgot password
  - Secure token storage
  
- **Course Management**
  - Browse and search courses
  - Organize courses by category and difficulty
  - Enroll in courses
  - Track progress across modules and lessons
  - Video, text, quiz, and assignment lesson types

- **User Dashboard**
  - Overview of enrolled courses
  - Progress tracking
  - Recommendations based on interests
  - Quick access to in-progress courses

- **Achievements & Gamification**
  - Unlock badges and achievements
  - Points accumulation system
  - Global leaderboard
  - User rankings and statistics

- **Payments & Membership**
  - Stripe-hosted checkout for online payments
  - Multiple pricing tiers (Free, Starter, Pro, Premium)
  - Monthly and annual billing options
  - Course purchase functionality
  - Payment history and receipts

- **User Profile**
  - Profile information management
  - Avatar upload
  - Account settings
  - Security and privacy controls

- **Onboarding**
  - User preferences setup
  - Interest selection
  - Learning goals definition
  - Skip option for experienced users

## 🏗️ Project Structure

```
impactknowledge_app/
├── lib/
│   ├── config/
│   │   ├── app_config.dart          # App-wide configuration
│   │   └── service_locator.dart     # Dependency injection setup
│   │
│   ├── models/                       # Data models (matching Prisma schema)
│   │   ├── auth/
│   │   │   └── user_model.dart
│   │   ├── courses/
│   │   │   └── course_model.dart
│   │   ├── achievements/
│   │   │   └── achievement_model.dart
│   │   └── payments/
│   │       └── payment_model.dart
│   │
│   ├── services/                     # Business logic layer
│   │   ├── api/
│   │   │   └── api_service.dart     # HTTP client (Dio)
│   │   ├── auth/
│   │   │   └── auth_service.dart
│   │   ├── course/
│   │   │   └── course_service.dart
│   │   ├── achievement/
│   │   │   └── achievement_service.dart
│   │   └── payment/
│   │       └── payment_service.dart
│   │
│   ├── screens/                      # UI Screens
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── courses/
│   │   ├── achievements/
│   │   ├── leaderboard/
│   │   ├── payments/
│   │   ├── profile/
│   │   └── onboarding/
│   │
│   ├── widgets/                      # Reusable UI components
│   ├── providers/                    # State management (GetX/Provider)
│   ├── storage/                      # Local storage management
│   ├── utils/                        # Utility functions
│   ├── constants/                    # App-wide constants
│   └── main.dart                     # Application entry point
│
├── pubspec.yaml                      # Dependencies
└── README.md                         # This file
```

## 🎯 Key Dependencies

- **State Management**: `get` (GetX framework)
- **HTTP Client**: `dio` (REST API communication)
- **Storage**: `hive`, `shared_preferences`, `flutter_secure_storage`
- **Authentication**: `jwt_decoder`, Firebase Auth (optional)
- **Payments**: Hosted checkout via backend Stripe integration
- **Navigation**: `go_router`

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for iOS)

### Installation

```bash
cd impactknowledge_app
flutter pub get
flutter pub run build_runner build
flutter run
```

## ⚙️ Configuration

Update `lib/config/app_config.dart` with your backend URLs:

```dart
static const String apiBaseUrl = 'http://your-backend-url/api';
static const String flutterwavePublicKey = 'YOUR_PUBLIC_KEY';
```

## 📡 API Integration

Connects to the same backend APIs as the web version with JWT authentication.

## 🔐 Security Features

- ✅ Secure token storage
- ✅ JWT token validation and refresh
- ✅ Secure password handling
- ✅ SSL/TLS support

## 📊 Database Schema Compatibility

Uses the same Prisma schema as the web version for data consistency.

## 🧪 Testing

```bash
flutter test
flutter test --coverage
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (12.0+)

---

**Same Backend, Same Database, New Experience** - ImpactKnowledge App
