# ImpactKnowledge Flutter App - User Flow & Navigation Guide

## Complete User Journey

This document outlines the complete user flow from app launch through all major features.

---

## 1. App Launch Flow

```
App Startup
   ↓
[main.dart]
   ↓
Service Locator Initialization
   ↓
GetMaterialApp with Routes
   ↓
Check if User Logged In (AuthController.isLoggedIn)
   ├─→ YES → Redirect to Dashboard
   └─→ NO  → Show Login Screen
```

---

## 2. Authentication Journey

### 2.1 First Time User: Sign Up Flow

```
LOGIN SCREEN
   ↓
[No Account Link]
   ↓
SIGNUP SCREEN
   │
   ├─→ Enter: First Name, Last Name, Email
   ├─→ Enter: Password (8+ chars), Confirm
   ├─→ Optional: Country, Profession, Reason
   │
   └─→ [Create Account Button]
       ↓
       API: POST /auth/signup
       ↓
       AuthService.signup()
       ↓
       Response: UserProfile + JWT Token
       ↓
       Save Token (Secure Storage)
       ↓
       AuthController.isLoggedIn = true
       ↓
       ONBOARDING SCREEN (5-step setup)
           ├─→ Step 1: Welcome
           ├─→ Step 2: Select Interests (min 2)
           ├─→ Step 3: Choose Learning Goal
           ├─→ Step 4: Notification Preferences
           ├─→ Step 5: Completion
           │
           └─→ [Get Started]
               ↓
               DASHBOARD SCREEN
```

### 2.2 Returning User: Login Flow

```
LOGIN SCREEN
   ├─→ Enter: Email
   ├─→ Enter: Password
   │
   └─→ [Login Button]
       ↓
       API: POST /auth/login
       ↓
       AuthService.login()
       ↓
       Response: UserProfile + JWT Token
       ↓
       Save Token (Secure Storage)
       ↓
       AuthController.isLoggedIn = true
       ↓
       Auto-redirect to DASHBOARD
           (via ever() listener)
```

### 2.3 Forgot Password Flow

```
LOGIN SCREEN
   ↓
[Forgot Password Link]
   ↓
FORGOT PASSWORD SCREEN
   ├─→ Enter: Email
   │
   └─→ [Reset Button]
       ↓
       API: POST /auth/forgot-password
       ↓
       AuthService.forgotPassword()
       ↓
       Show: Success Message
       ├─→ "Check your email for reset link"
       │
       └─→ [Back to Login]
           ↓
           LOGIN SCREEN
```

---

## 3. Main App Navigation

### 3.1 Dashboard (Home Hub)

```
DASHBOARD
├─ TAB 1: HOME
│  ├─→ User Greeting ("Welcome, John!")
│  ├─→ Continue Learning (carousel)
│  │   └─→ [Tap Course] → COURSE DETAIL → LESSON
│  │
│  └─→ Browse Courses (top 3)
│      └─→ [Browse All] → COURSES LIST
│
├─ TAB 2: COURSES
│  └─→ COURSES LIST SCREEN
│
├─ TAB 3: ACHIEVEMENTS  
│  └─→ ACHIEVEMENTS SCREEN
│
└─ TAB 4: PROFILE
   └─→ PROFILE SCREEN
   
Bottom Menu Items:
├─→ [Profile Settings] → PROFILE (Edit Mode)
├─→ [Leaderboard] → LEADERBOARD SCREEN
├─→ [Membership] → MEMBERSHIP SCREEN
├─→ [Settings] → PROFILE (Settings)
└─→ [Logout] → LOGIN SCREEN
```

---

## 4. Course Learning Path

### 4.1 Browse & Enroll

```
DASHBOARD (HOME)
   ↓
Browse Courses (top 3 or [Browse All])
   ↓
COURSES LIST SCREEN
├─ Search Bar (reactive)
├─ Category Filters:
│  ├─ All
│  ├─ Technology
│  ├─ Business
│  ├─ Design
│  └─ Science
├─ Infinite Scroll Pagination
│
└─ [Tap Course Card]
   ↓
   COURSE DETAIL SCREEN
   ├─ Cover Image
   ├─ Title & Metadata
   ├─ Description
   ├─ Learning Outcomes
   │
   └─ IF NOT ENROLLED:
       └─→ [Enroll Button]
           ↓
           API: POST /courses/{id}/enroll
           ↓
           CourseService.enrollCourse()
           ↓
           Show: Modules List
           ↓
           [Continue Learning Button]
           ↓
           LESSON SCREEN

   └─ IF ALREADY ENROLLED:
       └─→ [Continue Learning Button]
           ↓
           LESSON SCREEN
```

### 4.2 Learning & Progress

```
LESSON SCREEN
├─ Lessons List (from module)
├─ Lesson Type Icon (video/text/quiz/assignment)
├─ Duration & Metadata
│
└─ [Tap Lesson]
   ↓
   Modal Bottom Sheet Opens
   ├─ Lesson Title
   ├─ Lesson Content
   ├─ Type Badge
   │
   └─ [Mark as Complete Button]
       ↓
       API: PUT /lessons/{id}/progress
       ↓
       CourseService.updateLessonProgress()
       ↓
       Show: Success Toast
       ↓
       Update: Progress Bar
       │
       └─ IF ALL LESSONS COMPLETE:
           ↓
           Complete Course
           ↓
           API: POST /courses/{id}/complete
           ↓
           Award: Points + Achievement
           ↓
           Show: Success Message
```

---

## 5. Gamification & Achievements

### 5.1 Achievements Screen

```
DASHBOARD (PROFILE) → [Achievements Tab]
   ↓
ACHIEVEMENTS SCREEN
├─ Points Summary (gradient card)
│  ├─ Total Points
│  ├─ Achievement Count
│  ├─ Streak Counter
│  └─ Level
│
├─ Achievement Badges Grid (3 columns)
│  ├─ Locked (grayed out)
│  ├─ Unlocked (colored)
│  │
│  └─ [Tap Badge]
│     ↓
│     Achievement Detail Modal
│     ├─ Badge Icon
│     ├─ Achievement Name
│     ├─ Description
│     ├─ Requirements
│     ├─ Unlock Date
│     ├─ Points Awarded
│     │
│     └─ Status: Locked/Unlocked
│
└─ [Refresh Button]
   ↓
   API: GET /achievements/user
   ↓
   AchievementController.fetchUserAchievements()
   ↓
   Update Display
```

### 5.2 Leaderboard Screen

```
DASHBOARD (PROFILE) → [Leaderboard Menu Item]
   ↓
LEADERBOARD SCREEN
├─ Timeframe Selector (RadioButton)
│  ├─ All Time (default)
│  ├─ Monthly
│  └─ Weekly
│
├─ Your Rank Card (gradient)
│  ├─ Your Rank #N
│  ├─ Your Points
│  └─ Your Achievement Count
│
├─ Global Rankings List
│  ├─ Medal Icons (top 3)
│  ├─ User Name
│  ├─ Achievement Count
│  └─ Points
│
└─ Load More (infinite scroll)
   ↓
   API: GET /leaderboard?timeframe={all|monthly|weekly}
   ↓
   AchievementController.fetchLeaderboard()
   ↓
   Update Rankings
```

---

## 6. Membership & Payments

### 6.1 Membership Management

```
DASHBOARD (PROFILE) → [Membership Menu Item]
   ↓
MEMBERSHIP SCREEN
├─ Current Membership Card
│  ├─ Tier Name
│  ├─ Expiry Date
│  │
│  └─ [Manage Subscription Button]
│     ↓
│     Confirm Cancel Dialog
│     │
│     └─ [Cancel Subscription]
│        ↓
│        API: DELETE /memberships/{id}
│        ↓
│        PaymentController.cancelMembership()
│        ↓
│        Update UI
│        ↓
│        Show: Success Message
│
├─ Billing Cycle Toggle (Monthly/Annual)
│
└─ Membership Tiers List
   ├─ Free Tier
   │  └─ [Current Plan]
   │
   ├─ Starter Tier
   │  ├─ Price
   │  ├─ Features List
   │  │
   │  └─ [Upgrade Button]
   │     ↓
   │     Upgrade Confirmation Dialog
   │     │
   │     └─ [Confirm]
   │        ↓
   │        API: POST /payments/membership
   │        ↓
   │        PaymentController.initiateMembershipPayment()
   │        ↓
   │        Open: Flutterwave Payment Gateway
   │        ↓
   │        (Redirect to Flutterwave URL)
   │        ↓
   │        User Completes Payment
   │        ↓
   │        Flutterwave Callback
   │        ↓
   │        Verify Payment
   │        ↓
   │        Update: User Membership
   │        ↓
   │        Show: Success Message
   │
   ├─ Pro Tier
   │  └─ [Similar to Starter]
   │
   └─ Premium Tier
      └─ [Similar to Starter]
```

---

## 7. User Profile & Settings

### 7.1 Profile View & Edit

```
DASHBOARD (PROFILE) → [Profile Tab or Profile Menu]
   ↓
PROFILE SCREEN
├─ Avatar Circle (Initials)
├─ User Name Display
├─ Email Display
│
├─ [Edit Button] (AppBar)
│  ↓
│  Enable Edit Mode
│  ├─ First Name (editable)
│  ├─ Last Name (editable)
│  ├─ Bio (editable)
│  │
│  └─ [Save Changes]
│     ↓
│     API: PUT /users/profile
│     ↓
│     AuthController.updateProfile()
│     ↓
│     Update: UI Display
│     ↓
│     Disable Edit Mode
│
├─ Account Information Section
│  ├─ Email
│  ├─ Role
│  ├─ Member Since Date
│  └─ Email Verified Status
│
├─ Settings Section
│  ├─ [Change Password]
│  │  ↓
│  │  Password Change Dialog
│  │  ├─ Current Password
│  │  ├─ New Password (8+ chars)
│  │  ├─ Confirm Password
│  │  │
│  │  └─ [Change Password]
│  │     ↓
│  │     API: POST /auth/change-password
│  │     ↓
│  │     AuthService.changePassword()
│  │     ↓
│  │     Show: Success Message
│  │
│  ├─ [Notifications] → Settings Screen
│  └─ [Privacy & Security] → Settings Screen
│
├─ Support Section
│  ├─ [Help & FAQ]
│  ├─ [Report a Problem]
│  └─ [Terms & Conditions]
│
├─ Danger Zone
│  └─ [Delete Account]
│     ↓
│     Delete Confirmation Dialog
│     │
│     └─ [Confirm]
│        ↓
│        API: DELETE /users/me
│        ↓
│        Logout
│        ↓
│        LOGIN SCREEN
│
└─ [Logout Button]
   ↓
   API: POST /auth/logout
   ↓
   AuthService.logout()
   ↓
   Clear: Secure Storage, Controllers
   ↓
   LOGIN SCREEN
```

---

## 8. Onboarding Setup (First Time Only)

```
AFTER SIGNUP SUCCESS
   ↓
ONBOARDING SCREEN
│
├─ STEP 1: WELCOME
│  ├─ Welcome Message
│  ├─ Benefits Summary
│  │
│  └─ [Next]
│
├─ STEP 2: INTERESTS SELECTION
│  ├─ Multi-select Chips (min 2)
│  ├─ Categories:
│  │  ├─ Technology
│  │  ├─ Business
│  │  ├─ Design
│  │  ├─ Science
│  │  ├─ Health
│  │  ├─ Finance
│  │  ├─ Marketing
│  │  └─ Development
│  │
│  └─ [Next] (requires min 2)
│
├─ STEP 3: LEARNING GOAL
│  ├─ Radio Button Selection (single choice)
│  ├─ Goals:
│  │  ├─ Career Growth
│  │  ├─ Personal Development
│  │  ├─ Skill Enhancement
│  │  ├─ Certification
│  │  └─ Learning for Fun
│  │
│  └─ [Next] (requires selection)
│
├─ STEP 4: NOTIFICATION PREFERENCES
│  ├─ Toggle: Course Updates
│  ├─ Toggle: Achievement Unlocked
│  ├─ Toggle: Leaderboard Updates
│  │
│  └─ [Next]
│
└─ STEP 5: COMPLETION
   ├─ Success Checkmark
   ├─ "All Set!" Message
   │
   └─ [Get Started]
      ↓
      Save: Preferences
      ↓
      DASHBOARD SCREEN
      │
      └─ Show: "Welcome, [First Name]!"
```

---

## 9. Navigation Tree (Complete Overview)

```
ROOT
├─ LOGIN (initial if not logged in)
│  ├─ [Create Account] → SIGNUP
│  │   └─ Success → ONBOARDING → DASHBOARD
│  └─ [Forgot Password] → FORGOT PASSWORD
│      └─ [Back] → LOGIN
│
├─ ONBOARDING (initial if first time after signup)
│  └─ Complete → DASHBOARD
│
└─ DASHBOARD (main app hub)
   ├─ TAB 1: HOME
   │  ├─ [Continue Learning] → COURSE DETAIL → (Enroll if needed) → LESSON
   │  └─ [Browse Courses] → COURSES LIST → COURSE DETAIL → LESSON
   │
   ├─ TAB 2: COURSES
   │  └─ COURSES LIST
   │     ├─ Search (reactive)
   │     ├─ Filter (reactive)
   │     └─ [Tap] → COURSE DETAIL → LESSON
   │
   ├─ TAB 3: ACHIEVEMENTS
   │  └─ ACHIEVEMENTS SCREEN
   │     └─ [Tap Badge] → Achievement Detail Modal
   │
   ├─ TAB 4: PROFILE (primary)
   │  ├─ Display Avatar & Basic Info
   │  └─ [Edit] → Edit Profile Mode
   │
   ├─ PROFILE (menu item)
   │  └─ [Profile Settings] → PROFILE (Edit)
   │
   ├─ LEADERBOARD (menu item)
   │  └─ LEADERBOARD SCREEN
   │     ├─ Timeframe Filter
   │     └─ Rankings List
   │
   ├─ MEMBERSHIP (menu item)
   │  └─ MEMBERSHIP SCREEN
   │     ├─ Current Membership
   │     ├─ Billing Cycle Toggle
   │     ├─ Tier Cards
   │     └─ [Upgrade] → Payment
   │
   ├─ SETTINGS (menu item)
   │  └─ PROFILE SCREEN (Settings)
   │
   └─ LOGOUT
      └─ LOGIN SCREEN
```

---

## 10. State Management & Reactivity

### 10.1 Data Flow

```
API/Backend
   ↓
Services (AuthService, CourseService, etc.)
   ↓
GetX Controller (observable state)
   ↓
Rx Variables (reactive properties):
   - authController.isLoggedIn
   - courseController.courses
   - achievementController.userAchievements
   - paymentController.userMembership
   ↓
Obx() Widgets (UI bindings)
   ↓
Automatic UI Updates
   (when Rx variables change)
```

### 10.2 Controller Initialization

```
main.dart
   ↓
setupServiceLocator()
   ├─ Register: ApiService
   ├─ Register: AuthService
   ├─ Register: CourseService
   ├─ Register: AchievementService
   ├─ Register: PaymentService
   ├─ Register: AuthController
   ├─ Register: CourseController
   ├─ Register: AchievementController
   └─ Register: PaymentController
   ↓
GetMaterialApp Initialized
   ├─ Home: GetPages with routing
   ├─ InitialRoute: /login or /dashboard
   └─ Theme: Material3
   ↓
AuthController.checkLoginStatus()
   └─ Load persisted token
   └─ Set isLoggedIn accordingly
```

---

## 11. API Request Examples

### 11.1 Authentication

```dart
// Login
POST /auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
Response:
{
  "user": { UserProfile object },
  "token": "jwt_token_here"
}

// Signup
POST /auth/signup
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "countryOfResidence": "Nigeria",
  "professionOrStudyArea": "Software Engineer",
  "reasonForJoining": "Career growth"
}
Response:
{
  "user": { UserProfile object },
  "token": "jwt_token_here"
}

// Refresh Token
POST /auth/refresh
Headers:
  Authorization: Bearer {token}
Response:
{
  "token": "new_jwt_token"
}
```

### 11.2 Courses

```dart
// Get All Courses
GET /courses?page=1&pageSize=10&categoryId=tech&search=flutter
Response:
[
  { Course object },
  { Course object }
]

// Enroll in Course
POST /courses/{courseId}/enroll
Response:
{
  "enrollment": { Enrollment object }
}

// Update Lesson Progress
PUT /lessons/{lessonId}/progress
{
  "status": "completed",
  "score": 85
}
Response:
{
  "progress": { LessonProgress object }
}

// Complete Course
POST /courses/{courseId}/complete
Response:
{
  "message": "Course completed",
  "points": 50,
  "achievements": ["achievement_id"]
}
```

### 11.3 Achievements & Leaderboard

```dart
// Get Leaderboard
GET /leaderboard?timeframe=all&page=1
Response:
[
  { Leaderboard object },
  { Leaderboard object }
]

// Get User Achievements
GET /achievements/user
Response:
[
  { UserAchievement object }
]

// Get User Rank
GET /leaderboard/user/rank
Response:
{
  "rank": 5,
  "points": 1250,
  "achievementCount": 12
}
```

### 11.4 Payments

```dart
// Get Membership Tiers
GET /memberships/tiers
Response:
[
  { MembershipTier object }
]

// Initiate Payment
POST /payments/initiatePayment
{
  "membershipsId": "tier_id",
  "amount": 9.99,
  "currency": "USD"
}
Response:
{
  "authorizationUrl": "https://checkout.flutterwave.com/...",
  "reference": "payment_reference"
}

// Verify Payment
POST /payments/verify
{
  "reference": "payment_reference"
}
Response:
{
  "status": "completed",
  "membership": { UserMembership object }
}
```

---

## 12. Error Handling & Recovery

### 12.1 API Errors

```
API Error Response
   ↓
ApiService Exception Handler
   ├─ 401 Unauthorized
   │  └─ Attempt Token Refresh
   │     ├─ Success: Retry Original Request
   │     └─ Fail: Logout, Redirect to Login
   │
   ├─ 400 Bad Request
   │  └─ Show: Specific Error Message
   │
   ├─ 404 Not Found
   │  └─ Show: "Resource not found"
   │
   ├─ 500 Server Error
   │  └─ Show: "Server error, try again"
   │
   └─ Network Error
      └─ Show: "Connection failed"
      └─ Offer: [Retry] button
```

### 12.2 UI Error States

```
Every Screen Has:
├─ Loading State
│  └─ Show: Spinner
│
├─ Error State
│  ├─ Show: Error Message
│  └─ Show: [Retry] button
│
└─ Empty State
   ├─ Show: Icon
   ├─ Show: Message
   └─ Show: [Action] button
```

---

## 13. Authentication State Lifecycle

```
App Start
   ↓
Load Persisted Token (Secure Storage)
   ↓
IF Token Exists:
   ├─ Try to Decode JWT
   ├─ Check Token Expiry
   ├─ If Expired:
   │  └─ Try to Refresh
   │     ├─ Success: Set New Token
   │     └─ Fail: Logout
   └─ If Valid:
      └─ Set isLoggedIn = true
      └─ Load User Profile
ELSE:
   └─ Show Login Screen (isLoggedIn = false)
```

---

## 14. Next Feature Development

### 14.1 Video Player Integration

```
LESSON SCREEN Enhancement
   ├─ IF lesson.lessonType == 'video':
   │  ├─ Display: VideoPlayer widget
   │  ├─ Show: Play/pause controls
   │  ├─ Track: Watch progress (%)
   │  ├─ Mark complete: On 80%+ watched
   │  └─ Offer: [Replay] button
   └─ Else: Show text/pdf content
```

### 14.2 Quiz Implementation

```
LESSON SCREEN Enhancement
   ├─ IF lesson.lessonType == 'quiz':
   │  ├─ Navigate: QUIZ SCREEN
   │  ├─ Display: Questions one-by-one
   │  ├─ Allow: Multiple attempts
   │  ├─ Show: Score & feedback
   │  ├─ Award: Points on pass
   │  └─ Track: Best score
```

### 14.3 Push Notifications

```
Firebase Messaging Setup
   ├─ On App Start:
   │  └─ Request FCM Token
   │  └─ Send to Backend
   ├─ On Notification Received:
   │  ├─ Show Local Notification
   │  ├─ Parse Notification Data
   │  └─ Navigate to Relevant Screen
   └─ Types:
      ├─ New Course Available
      ├─ Achievement Unlocked
      ├─ Leaderboard Rank Changed
      └─ Custom Announcements
```

---

## 15. Performance Considerations

### 15.1 Image Caching

```
Use: CachedNetworkImage (already in pubspec.yaml)
├─ Auto caches course cover images
├─ Shows placeholder while loading
└─ Prevents re-downloading on scroll
```

### 15.2 Pagination

```
Implemented in:
├─ Courses List (infinite scroll)
├─ Leaderboard (infinite scroll)
└─ Lessons List (if many lessons)

Strategy:
├─ Load 10 items per page
├─ Load more on scroll to end
└─ Show loading indicator
```

### 15.3 State Management

```
GetX Benefits:
├─ Minimal rebuilds (only Obx widgets)
├─ Reactive data binding
├─ Efficient memory usage
└─ Fast performance
```

---

## 16. Testing Scenarios

### 16.1 Happy Path (Normal User)

```
1. Launch App
2. Signup with valid data
3. Complete onboarding
4. Browse courses
5. Enroll in course
6. Complete lessons
7. View achievements
8. Check leaderboard
9. Upgrade membership
10. Edit profile
11. Logout
```

### 16.2 Edge Cases

```
1. Login with wrong password → Show error
2. Signup with existing email → Show error
3. Token expiry during use → Auto-refresh
4. Logout while in course → Show modal
5. Network disconnect → Show retry
6. Empty course list → Show empty state
7. No achievements yet → Show empty state
8. Payment failure → Show error & retry
```

---

## 17. Key Files Reference

| Screen | File | Lines | Status |
|--------|------|-------|--------|
| Login | `screens/auth/login_screen.dart` | 130 | ✅ |
| Signup | `screens/auth/signup_screen.dart` | 250 | ✅ |
| Forgot Password | `screens/auth/forgot_password_screen.dart` | 185 | ✅ |
| Dashboard | `screens/dashboard/dashboard_screen.dart` | 400 | ✅ |
| Courses List | `screens/courses/courses_list_screen.dart` | 135 | ✅ |
| Course Detail | `screens/courses/course_detail_screen.dart` | 220 | ✅ |
| Lesson | `screens/courses/lesson_screen.dart` | 120 | ✅ |
| Achievements | `screens/achievements/achievements_screen.dart` | 380 | ✅ |
| Leaderboard | `screens/leaderboard/leaderboard_screen.dart` | 220 | ✅ |
| Membership | `screens/payments/membership_screen.dart` | 350 | ✅ |
| Profile | `screens/profile/profile_screen.dart` | 380 | ✅ |
| Onboarding | `screens/onboarding/onboarding_screen.dart` | 420 | ✅ |

---

**Note**: All navigation flows assume user has internet connectivity and backend APIs are responding. Error handling is implemented for all failure scenarios.

Last Updated: [Current Implementation Phase]
