# Quick Verification Checklist

## Backend Setup ✅ VERIFY

- [ ] **Backend running**: 
  ```powershell
  curl http://localhost:3000/health
  ```
  Should return: `{"status":"ok","timestamp":"...", ...}`

- [ ] **JWT_SECRET configured**:
  ```powershell
  cd backend
  Get-Content .env | findstr JWT_SECRET
  ```
  Should show: `JWT_SECRET=test-jwt-secret-key-for-local-testing-impactknowledge`

- [ ] **Database initialization** (check backend logs):
  ```
  ✅ Database initialized successfully
  ⚠️  AUTH USING IN-MEMORY MOCK AUTHENTICATION
  ```

---

## Frontend Code ✅ VERIFY

- [ ] **`getToken()` is public** (in `lib/services/api/api_service.dart`):
  ```dart
  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConfig.tokenKey);
  }
  ```
  Should NOT have underscore prefix (not `_getToken`)

- [ ] **API Base URL set correctly** (in `lib/config/app_config.dart`):
  - Emulator: `http://10.0.2.2:3000/`
  - Physical phone: `http://YOUR_IP:3000/`
  - Local: `http://192.168.70.160:3000/` (if that's your machine IP)

---

## Test User Registration ✅ TEST

- [ ] **Register endpoint works**:
  ```powershell
  $body = @{
      email = "test123@example.com"
      password = "TestPass123!"
      full_name = "John Smith"
      role = "student"
  } | ConvertTo-Json

  curl -Method POST `
    -Uri http://localhost:3000/api/auth/register `
    -ContentType "application/json" `
    -Body $body
  ```

  Expected backend logs:
  ```
  === REGISTER === { email: 'test123@example.com', ... }
  ✅ User registered: test123@example.com (ID: 1)
  ✅ REGISTER SUCCESS: New user created with ID: 1
  🔑 TOKEN ISSUED: Access token starts with: eyJhbGc...
  ```

  Expected response:
  ```json
  {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "user": {
      "id": "1",
      "email": "test123@example.com",
      "full_name": "John Smith",
      "role": "student",
      ...
    }
  }
  ```

---

## Test Dashboard Access ✅ TEST

- [ ] **Dashboard endpoint works with token**:
  ```powershell
  # REPLACE with your actual token from previous step
  $token = "eyJ..."

  curl -Uri http://localhost:3000/api/dashboard/student `
    -Headers @{ "Authorization" = "Bearer $token" }
  ```

  Expected backend logs:
  ```
  🔑 TOKEN to verify: eyJ...
  ✅ Token verified successfully: { id: '1' }
  ```

  Expected response (status 200):
  ```json
  {
    "totalStudents": 245,
    "totalFacilitators": 18,
    "totalCoursesActive": 12,
    ...
  }
  ```

---

## Test Flutter App ✅ TEST

- [ ] **App starts without errors**:
  ```powershell
  flutter run -d emulator-5554
  ```
  Should show landing screen without any errors

- [ ] **"Get Started" button works**:
  - Tap "Get Started" button
  - Login screen should appear
  - No error messages

- [ ] **Login with test user**:
  - Email: `test123@example.com`
  - Password: `TestPass123!`
  - Tap "Login"
  - Dashboard should load immediately
  - No HTTP 403 errors

- [ ] **Dashboard displays data**:
  - Total Users: 245
  - Active Courses: 12
  - Completion: 68%
  - Critical Alerts: 5

---

## Troubleshooting ⚠️ IF ISSUES

### Issue: Backend won't start
```powershell
# Kill existing node processes
taskkill /F /IM node.exe

# Check node is installed
node --version

# Try again
cd backend
npm install
npm start
```

### Issue: HTTP 403 on dashboard request
```powershell
# 1. Check backend logs for token error
# Should see "Token verification failed:" with specific error

# 2. Verify JWT_SECRET
Get-Content backend/.env | findstr JWT_SECRET

# 3. Test token directly
$token = "YOUR_TOKEN"
curl -Uri http://localhost:3000/api/dashboard/student `
  -Headers @{ "Authorization" = "Bearer $token" }
```

### Issue: Login screen shows no error but nothing happens
```powershell
# Check Android logs
adb logcat | findstr "LOGIN\|TOKEN\|AUTH\|403\|401"

# Or check full error
adb logcat | head -100
```

### Issue: "Connection refused"
```powershell
# Verify backend is running
curl http://localhost:3000/health

# Check API base URL is correct
# Should be 10.0.2.2:3000 for emulator
# or YOUR_IP:3000 for physical device
```

---

## After Verification ✅ SUCCESS

Once all tests pass:

1. ✅ Backend is running with proper logging
2. ✅ User registration works
3. ✅ Authentication tokens are created
4. ✅ Dashboard endpoint returns data
5. ✅ Flutter app can login
6. ✅ Dashboard loads successfully

You're ready to:
- Test other roles (parent, facilitator, admin, etc.)
- Add more features
- Deploy to production

---

## Files Modified (Review These)

1. **`lib/services/api/api_service.dart`**
   - Search for: `Future<String?> getToken()`
   - Should be PUBLIC, not `_getToken()`

2. **`backend/src/middleware/auth.js`**
   - Search for: `console.log('🔑 TOKEN to verify`
   - Should have detailed logging

3. **`backend/src/routes/auth.js`**
   - Search for: `📋 REGISTER SUCCESS`
   - Should have success logging

---

## Still Having Issues?

1. Share backend log output (from `npm start`)
2. Share Flutter error messages (from `adb logcat`)
3. Share response from test requests (POST /register, GET /dashboard)
4. Confirm IP address in `AppConfig.apiBaseUrl` is correct

With this information, the issue can be diagnosed quickly!
