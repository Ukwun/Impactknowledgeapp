# Firebase Integration - Step-by-Step Guide
**Status**: Getting your crash monitoring & analytics ready
**Estimated Time**: 3-5 hours
**Date**: March 29, 2026

---

## 🔥 STEP 1: CREATE FIREBASE PROJECTS (15 minutes)

### 1.1 Create Android Firebase Project

1. **Go to Firebase Console**
   - URL: https://firebase.google.com/
   - Click "Go to console" (top right)
   - Sign in with your Google account

2. **Create New Project**
   - Click "+ Create a project"
   - Project name: `ImpactKnowledge-Android`
   - Click "Continue"

3. **Enable Google Analytics** (Optional but recommended)
   - Keep enabled
   - Select your account
   - Click "Create project"
   - Wait 2-3 minutes for creation

4. **Add Android App to Firebase**
   - Click "Android" icon (or "Add app" if already in project)
   - Android package name: `com.impactknowledge.impactknowledge_app`
   - App nickname: `ImpactKnowledge Android`
   - Click "Register app"

5. **Download Configuration File**
   - You'll see download button for `google-services.json`
   - ✅ **DOWNLOAD NOW** - You'll need this in next step
   - Save to your Downloads folder

### 1.2 Create iOS Firebase Project (Optional - only if doing iOS)

If you're only doing Android now, **skip this**. Can do iOS later.

---

## 📁 STEP 2: ADD CONFIGURATION FILE TO PROJECT (5 minutes)

### 2.1 Place google-services.json in Android Directory

1. **Locate the downloaded file**
   - Find `google-services.json` in your Downloads folder

2. **Move to correct location**
   - Copy the file
   - Navigate to: `c:\DEV3\ImpactEdu\impactknowledge_app\android\app\`
   - Paste the file here

**Verify**:
```
c:\DEV3\ImpactEdu\impactknowledge_app\
├── android/
│   ├── app/
│   │   ├── google-services.json  ✅ (This file you just added)
│   │   ├── build.gradle.kts
│   │   └── src/
│   ├── build.gradle.kts
│   └── settings.gradle.kts
└── lib/
```

---

## ⚙️ STEP 3: UPDATE BUILD CONFIGURATION FILES (10 minutes)

These changes enable Firebase in your Android build.

### 3.1 Update android/build.gradle.kts (Project Level)

**Location**: `c:\DEV3\ImpactEdu\impactknowledge_app\android\build.gradle.kts`

Add Google Play Services plugin to the `plugins` block:

```kotlin
// ADD THIS LINE to plugins block
id("com.google.gms.google-services") version "4.3.15"
```

### 3.2 Update android/app/build.gradle.kts (App Level)

**Location**: `c:\DEV3\ImpactEdu\impactknowledge_app\android\app\build.gradle.kts`

Make these changes:

1. **Add plugin** (at the top with other plugins):
```kotlin
apply plugin: 'com.google.gms.google-services'
```

2. **Add Firebase credentials to dependencies** (in `dependencies {}` block):
```kotlin
// Firebase
implementation(platform("com.google.firebase:firebase-bom:32.7.4"))
implementation("com.google.firebase:firebase-analytics")
implementation("com.google.firebase:firebase-crashlytics")
implementation("com.google.firebase:firebase-messaging")
```

---

## 🎯 STEP 4: UPDATE PUBSPEC.YAML (5 minutes)

Check your dependencies are there. They already should be installed.

**Location**: `c:\DEV3\ImpactEdu\impactknowledge_app\pubspec.yaml`

Verify these are present (they should be):
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_analytics: ^10.7.0
  firebase_messaging: ^14.6.0
```

If any are missing, add them:
```bash
flutter pub add firebase_core firebase_analytics firebase_messaging
```

---

## 💻 STEP 5: INITIALIZE FIREBASE IN CODE (15 minutes)

Update your `lib/main.dart` file to initialize Firebase.

**Location**: `c:\DEV3\ImpactEdu\impactknowledge_app\lib\main.dart`

Replace the entire `main()` function and update imports.

---

## 📊 STEP 6: ADD ANALYTICS EVENTS (1-2 hours)

Add tracking to important user actions:
- User signup
- User login
- Course enrollment
- Achievement unlock
- Payment completion

---

## ✅ STEP 7: BUILD & TEST (1 hour)

Build the APK and test:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🎯 EXPECTED RESULTS

After completing Firebase integration:

✅ **In Firebase Console**:
- See real-time user counts
- View crash reports
- Track custom events
- See user flows

✅ **In Your App**:
- No crashes without reporting
- Analytics data sent to Firebase
- Improved debugging

✅ **In Google Play Store** (later):
- Lower rejection rate (has analytics)
- Better app rating (fewer hidden bugs)
- Better user insights

---

## 📱 NEXT STEPS AFTER FIREBASE

1. **Build APK** (30 mins)
   ```bash
   flutter build apk --release
   ```

2. **Transfer to Client's Device** (15 mins)
   - Use Google Drive
   - Or USB cable
   - Or Upload to Firebase App Distribution

3. **Install on Client Device** (5 mins)
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Test Everything** (1-2 hours)
   - All screens
   - All features
   - Monitor for crashes in Firebase

---

**START NOW** → Follow the step-by-step guide below!

