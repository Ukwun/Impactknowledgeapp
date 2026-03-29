# Authentication & Dashboard Fix Guide

## Issues Fixed

### ✅ Issue 1: Missing `getToken()` Method in ApiService
**Problem**: `DashboardService` was calling `apiService.getToken()` but the method was private (`_getToken()`), causing the token to be null.

**Fix**: Made `getToken()` public in `lib/services/api/api_service.dart`:
```dart
Future<String?> getToken() async {
  return await _secureStorage.read(key: AppConfig.tokenKey);
}
```

---

### ✅ Issue 2: Insufficient Debug Logging in Auth Middleware
**Problem**: Backend was returning HTTP 403 without clear indication of why token verification was failing.

**Fix**: Enhanced logging in `backend/src/middleware/auth.js`:
- Now logs token being verified
- Logs exact error messages
- Shows JWT_SECRET being used
- Provides detailed error responses

---

## Complete Setup & Testing Guide

### Step 1: Ensure Backend is Ready

```powershell
# Open PowerShell at project root
cd c:\DEV3\ImpactEdu\impactknowledge_app\backend

# Kill any existing Node processes
taskkill /F /IM node.exe 2>$null

# Install dependencies (if fresh)
npm install

# Start the server
npm start
```

**Expected output:**
```
Server running on port 3000
Database initialized successfully
⚠️  AUTH USING IN-MEMORY MOCK AUTHENTICATION
```

---

### Step 2: Test Backend Endpoint Health

From **another PowerShell** terminal:
```powershell
# Test health endpoint
curl http://localhost:3000/health

# Should respond with:
# {"status":"ok","timestamp":"2026-03-29T..."}
```

---

### Step 3: Test Login Endpoint

```powershell
# First, register a user
$body = @{
    email = "test@example.com"
    password = "Test123!"
    full_name = "Test User"
    role = "student"
} | ConvertTo-Json

curl -Method POST `
  -Uri http://localhost:3000/api/auth/register `
  -ContentType "application/json" `
  -Body $body

# Save the accessToken from response
```

---

### Step 4: Test Dashboard Endpoint

```powershell
# Replace YOUR_TOKEN with token from login response
$token = "YOUR_TOKEN_HERE"

curl -Uri http://localhost:3000/api/dashboard/student `
  -Headers @{
    "Authorization" = "Bearer $token"
  }

# Should return dashboard data with status 200
```

**If you get 403:**
- Check that the token string is copied completely
- Verify the token wasn't cut off at the beginning or end
- Ensure you're using Bearer format: `Bearer <token>`

---

### Step 5: Test Flutter App

**Ensure these settings are correct:**

#### File: `lib/config/app_config.dart`
```dart
static const String apiBaseUrl = 'http://192.168.70.160:3000/';
```

Update IP address if needed:
- **Emulator**: Use `http://10.0.2.2:3000/`
- **Physical Phone**: Use your machine's actual IP (find with `ipconfig`)
- **localhost**: `http://localhost:3000/` (only works if running on same device)

#### File: `backend/.env`
```
PORT=3000
NODE_ENV=development
JWT_SECRET=test-jwt-secret-key-for-local-testing-impactknowledge
```

---

### Step 6: Run Flutter App

```powershell
# Build and run on emulator
flutter build apk --release
flutter run -d emulator-5554

# Or on physical device
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n com.impactknowledge.impactknowledge_app/.MainActivity
```

---

## Testing Checklist

- [ ] Backend is running: `http://localhost:3000/health` returns 200
- [ ] User can register on landing screen
- [ ] User can login with registered credentials
- [ ] Dashboard loads after successful login
- [ ] Token is visible in console logs with `🔑` icon
- [ ] No HTTP 403 errors in backend logs

---

## Debugging Frontend Issues

### View Real-time Logs
```powershell
adb logcat | findstr "TOKEN\|AUTH\|DASHBOARD\|401\|403\|500"
```

### Check Stored Token
```powershell
adb shell "run-as com.impactknowledge.impactknowledge_app cat /data/data/com.impactknowledge.impactknowledge_app/files/flutter_secure_storage/secure_storage_data.json"
```

---

## Debugging Backend Issues

### Check JWT Secret
```powershell
# In backend directory
$env:JWT_SECRET
# or
Get-Content .env | findstr JWT_SECRET
```

### View Detailed Auth Logs
Backend now logs:
- ✅ Token received from client
- ✅ Token verification attempts
- ✅ Exact JWT error messages
- ✅ User ID after successful verification

---

## Common Issues & Solutions

### Issue: HTTP 403 on Dashboard Request
**Causes:**
- Token not being sent from Flutter (now fixed with public `getToken()`)
- Token is malformed or expired
- JWT_SECRET mismatch between creation and verification

**Solution:**
1. Check backend logs for token verification errors
2. Verify JWT_SECRET in `.env` matches what's used in code
3. Check token isn't truncated in requests

### Issue: Login Screen Shows No Error
**Cause:** Error messages aren't being properly displayed

**Solution:** Check Android logcat for detailed errors

### Issue: Backend Won't Start
**Cause:** Port 3000 already in use

**Solution:**
```powershell
# Kill node processes
taskkill /F /IM node.exe

# Or use specific port
$env:PORT=3001; npm start
```

---

## Next Steps

1. Start backend: `npm start` in `backend/` folder
2. Update `AppConfig.apiBaseUrl` if needed
3. Run Flutter app
4. Monitor backend logs for any `❌ Token verification failed` messages
5. Report any remaining errors with full logs
