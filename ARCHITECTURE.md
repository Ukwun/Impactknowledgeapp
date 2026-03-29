# ImpactKnowledge Flutter App - Architecture Documentation

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter App (Mobile)                  │
├─────────────────────────────────────────────────────────┤
│  UI Layer (Screens & Widgets)                           │
│  ├─ Auth Screens (Login, Signup, Reset)                │
│  ├─ Dashboard & Navigation                             │
│  ├─ Course Learning UI                                 │
│  ├─ Achievement & Leaderboard Display                  │
│  ├─ Payment & Membership UI                            │
│  └─ User Profile & Settings                            │
├─────────────────────────────────────────────────────────┤
│  State Management Layer (GetX Controllers)              │
│  ├─ AuthController (Manages auth state)                │
│  ├─ CourseController (Course & enrollment state)       │
│  ├─ AchievementController (Achievements state)         │
│  └─ PaymentController (Payment & membership state)     │
├─────────────────────────────────────────────────────────┤
│  Service Layer (Business Logic)                         │
│  ├─ AuthService                                        │
│  ├─ CourseService                                      │
│  ├─ AchievementService                                 │
│  └─ PaymentService                                     │
├─────────────────────────────────────────────────────────┤
│  Data Access Layer (API Client)                         │
│  ├─ ApiService (Dio HTTP Client)                       │
│  ├─ Request/Response Interceptors                      │
│  ├─ Token Management                                   │
│  └─ Error Handling                                     │
├─────────────────────────────────────────────────────────┤
│  Local Storage Layer                                    │
│  ├─ SecureStorage (Tokens)                            │
│  ├─ SharedPreferences (Settings)                       │
│  └─ Hive Database (Complex Objects)                    │
├─────────────────────────────────────────────────────────┤
│                 Backend API Server (Node.js/Next.js)    │
│  ├─ Authentication Endpoints                           │
│  ├─ Course Management Endpoints                        │
│  ├─ Payment Processing Endpoints                       │
│  ├─ Achievement System Endpoints                       │
│  └─ User Profile Endpoints                             │
├─────────────────────────────────────────────────────────┤
│                   PostgreSQL Database                   │
│  (Shared with web version - same Prisma schema)        │
└─────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

### Authentication Flow
```
1. User enters credentials
   ↓
2. LoginScreen → AuthController
   ↓
3. AuthController → AuthService.login()
   ↓
4. AuthService → ApiService.post('/auth/login')
   ↓
5. Backend validates & returns JWT token
   ↓
6. ApiService saves token in SecureStorage
   ↓
7. AuthController updates UI with logged-in state
   ↓
8. App navigates to Dashboard
```

### Course Learning Flow
```
1. User views courses
   ↓
2. CoursesScreen → CourseController.getCourses()
   ↓
3. CourseController → CourseService.getAllCourses()
   ↓
4. CourseService → ApiService.get('/courses')
   ↓
5. Backend returns course list
   ↓
6. CourseController stores in local state (reactive)
   ↓
7. Screen rebuilds with course data
   ↓
8. User enrolls → CourseService.enrollCourse()
   ↓
9. Backend creates enrollment record
   ↓
10. App navigates to course modules
```

### Payment Flow
```
1. User selects membership tier
   ↓
2. CheckoutScreen → PaymentController.initPayment()
   ↓
3. PaymentController → PaymentService.initiateMembershipPayment()
   ↓
4. PaymentService → ApiService.post('/payments/membership/initiate')
   ↓
5. Backend creates payment record & returns Flutterwave link
   ↓
6. App opens Flutterwave payment UI (WebView)
   ↓
7. User completes payment on Flutterwave
   ↓
8. Flutterwave redirects to app with reference
   ↓
9. App calls PaymentService.verifyPayment(reference)
   ↓
10. Backend verifies with Flutterwave & confirms
   ↓
11. PaymentController updates state & shows success
```

## Service Layer Details

### ApiService (core/services/api/api_service.dart)

**Responsibilities:**
- HTTP communication via Dio
- Request/response interceptors
- Token management (save/retrieve/clear)
- Error handling and logging
- File upload support

**Key Methods:**
```dart
get<T>(endpoint, headers, fromJson)
post<T>(endpoint, data, fromJson)
put<T>(endpoint, data, fromJson)
delete<T>(endpoint, fromJson)
uploadFile<T>(endpoint, filePath)
saveToken(token)
clearToken()
```

### AuthService (services/auth/auth_service.dart)

**Responsibilities:**
- User authentication (login/signup)
- Token refresh logic
- Password reset flows
- User session management
- Check authentication status

**Key Methods:**
```dart
login(email, password)
signup(request)
logout()
getCurrentUser()
refreshToken()
forgotPassword(email)
resetPassword(token, newPassword)
isLoggedIn()
```

### CourseService (services/course/course_service.dart)

**Responsibilities:**
- Course browsing and search
- Enrollment management
- Progress tracking
- Module and lesson retrieval
- Course completion

**Key Methods:**
```dart
getAllCourses(page, category, search)
getCourseById(courseId)
getCourseModules(courseId)
getModuleLessons(moduleId)
enrollCourse(courseId)
getUserEnrollments(page)
updateLessonProgress(lessonId, status, score)
completeCourse(enrollmentId)
getEnrollmentProgress(enrollmentId)
```

### AchievementService (services/achievement/achievement_service.dart)

**Responsibilities:**
- Retrieve achievements
- Manage user achievements
- Leaderboard data
- Points tracking
- User ranking

**Key Methods:**
```dart
getAllAchievements()
getUserAchievements(page)
getUserPoints()
getLeaderboard(page, timeframe)
getUserRank()
getLeaderboardAroundUser()
getSpecificUserAchievements(userId)
```

### PaymentService (services/payment/payment_service.dart)

**Responsibilities:**
- Membership tier management
- Payment initiation
- Payment verification
- Payment history
- Membership status

**Key Methods:**
```dart
getMembershipTiers()
initiateCoursePayment(courseId, email, phone)
initiateMembershipPayment(tierId, email, phone, cycle)
verifyPayment(reference)
getUserPayments(page, status)
getUserMembership()
cancelMembership()
isCoursePurchased(courseId)
```

## State Management with GetX

### Controller Pattern

```dart
class CourseController extends GetxController {
  // Dependencies
  final CourseService courseService = getIt<CourseService>();
  
  // Reactive state
  final courses = RxList<Course>();
  final isLoading = false.obs;
  final error = RxString('');
  
  // Methods
  Future<void> fetchCourses() async {
    try {
      isLoading.value = true;
      error.value = '';
      courses.value = await courseService.getAllCourses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
```

### Controller Usage in UI

```dart
class CoursesScreen extends StatelessWidget {
  final courseController = Get.find<CourseController>();
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (courseController.isLoading.value) {
        return const CircularProgressIndicator();
      }
      
      return ListView.builder(
        itemCount: courseController.courses.length,
        itemBuilder: (context, index) {
          return CourseCard(course: courseController.courses[index]);
        },
      );
    });
  }
}
```

## Local Storage Architecture

### Secure Token Storage
```dart
// Automatic handling in ApiService
await secureStorage.write(key: 'auth_token', value: token);
final token = await secureStorage.read(key: 'auth_token');
```

### Preferences
```dart
// SharedPreferences for simple values
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('onboarding_completed', true);
bool completed = prefs.getBool('onboarding_completed') ?? false;
```

### Complex Objects (Optional Hive)
```dart
// For offline caching of courses, achievements, etc.
// Can be added later if needed
```

## Error Handling Strategy

### API Error Handling
```dart
try {
  await apiService.get('/courses');
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Token expired - refresh
    await refreshToken();
  } else if (e.response?.statusCode == 403) {
    // Forbidden - permission denied
  } else if (e.type == DioExceptionType.connectionTimeout) {
    // No internet
  }
}
```

### UI Error Display
```dart
// Global error handling
Get.snackbar(
  'Error',
  'Failed to load courses',
  backgroundColor: Colors.red,
  colorText: Colors.white,
);

// Or show error in UI
if (courseController.error.value.isNotEmpty) {
  return ErrorWidget(message: courseController.error.value);
}
```

## Security Considerations

1. **Token Security**
   - Stored in secure storage (KeyChain on iOS, KeyStore on Android)
   - Automatically attached to requests
   - Refreshed when expired

2. **Data Encryption**
   - HTTPS/SSL for all API communication
   - Sensitive data not logged

3. **Input Validation**
   - Email and password validation
   - All user inputs sanitized

4. **API Security**
   - JWT token validation on backend
   - Role-based access control (RBAC)
   - Rate limiting on sensitive endpoints

## Performance Optimization

1. **API Requests**
   - Pagination for list endpoints (page, pageSize)
   - Lazy loading of course content
   - Caching with Hive when needed

2. **UI Performance**
   - Virtual scrolling for long lists
   - Image caching (cached_network_image)
   - Code splitting and lazy routes

3. **Memory Management**
   - Proper controller disposal
   - Stream cleanup
   - Image memory management

## Testing Strategy

### Unit Tests
```dart
// Test services independently
test('AuthService login should return AuthResponse', () async {
  final response = await authService.login('...', '...');
  expect(response.accessToken, isNotEmpty);
});
```

### Widget Tests
```dart
// Test UI components
testWidgets('LoginScreen shows email field', (WidgetTester tester) async {
  await tester.pumpWidget(const LoginScreen());
  expect(find.byType(TextField), findsWidgets);
});
```

### Integration Tests
```dart
// Test full flows
testWidgets('User can login and view dashboard', (WidgetTester tester) async {
  // Full app flow test
});
```

## Deployment Architecture

```
┌─────────────────────────────────────┐
│      Development (local backend)    │
│      Testing & QA                   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Staging (production backend)      │
│   Final verification                │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Production Release                │
│   ├─ Google Play (Android)          │
│   └─ Apple App Store (iOS)          │
└─────────────────────────────────────┘
```

---

**Key Principle**: The Flutter app is a CLIENT consuming the same APIs and database as the web version. No duplication of business logic or data.
