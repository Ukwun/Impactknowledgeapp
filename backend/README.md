# ImpactKnowledge Backend API

Node.js + Express backend API for the ImpactKnowledge Flutter mobile app.

## Features

- **Authentication**: JWT-based auth with refresh tokens
- **Courses**: Full CRUD operations, modules, lessons
- **Achievements**: User achievements and leaderboards  
- **Payments**: Stripe checkout for online payments plus offline bank-transfer instructions
- **PostgreSQL**: Persistent data storage

## Prerequisites

- Node.js 14+ 
- PostgreSQL (using Render's PostgreSQL)
- npm or yarn

## Installation

1. **Clone or download this backend**
   ```bash
   cd impactapp-backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   - Copy `.env.example` to `.env`
   - Update database credentials with your Render PostgreSQL details
  - Set `JWT_SECRET` and `JWT_REFRESH_SECRET` to long random strings
  - Add Stripe credentials and webhook secret
  - Add Cloudinary credentials for signed media uploads

4. **Run locally**
   ```bash
   npm run dev
   ```
   Server will start on http://localhost:3000

## API Endpoints

### Authentication
- `POST /api/auth/register` - Create new account
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user
- `POST /api/auth/refresh` - Refresh access token

### Courses
- `GET /api/courses` - List all courses (paginated, searchable)
- `GET /api/courses/:id` - Get course details
- `GET /api/courses/:courseId/modules` - Get course modules
- `GET /api/modules/:moduleId/lessons` - Get module lessons

### Enrollments
- `POST /api/enrollments` - Enroll in course
- `GET /api/enrollments` - Get user enrollments
- `GET /api/enrollments/:id` - Get enrollment details
- `PUT /api/enrollments/:id` - Update enrollment progress

### Achievements
- `GET /api/achievements` - List all achievements
- `GET /api/achievements/:id` - Get achievement details
- `GET /api/users/achievements` - Get user achievements
- `GET /api/users/points` - Get user points
- `GET /api/leaderboard` - Get leaderboard

### Payments
- `POST /api/payments/courses/initiate` - Initiate course payment
- `POST /api/payments/membership/initiate` - Initiate membership payment
- `POST /api/payments/verify` - Verify payment
- `GET /api/payments` - Get user payments

### Users
- `GET /api/users/me` - Get user profile
- `PUT /api/users/me` - Update user profile

## Database

The backend automatically creates all required tables on startup via the `initializeDatabase()` function in `src/database/index.js`.

### Tables
- `users` - User accounts
- `courses` - Course catalog
- `modules` - Course modules
- `lessons` - Module lessons
- `enrollments` - User course enrollments
- `achievements` - Achievement definitions
- `user_achievements` - User achievement progress
- `user_points` - User points tracking
- `membership_tiers` - Membership subscription tiers
- `payments` - Payment transaction records

## Deployment to Render

### 1. Create a Web Service on Render
- Go to https://dashboard.render.com
- Create new "Web Service"
- Connect your GitHub repository (or deploy from this folder manually)
- Select **Start Command**: `npm start`
- Add environment variables from `.env`

### 2. Deploy steps
- Push code to GitHub (recommended)
- On Render dashboard, click "Deploy"
- Set signed upload secrets in Render environment variables:
  - `CLOUDINARY_CLOUD_NAME`
  - `CLOUDINARY_API_KEY`
  - `CLOUDINARY_API_SECRET`
  - `JWT_REFRESH_SECRET`
- Monitor deployment logs

### 3. Get your API URL
Once deployed, you'll get a URL like:
```
https://impactapp-backend.onrender.com
```

Update your Flutter app's `lib/config/app_config.dart`:
```dart
class AppConfig {
  static const String apiBaseUrl = 'https://impactapp-backend.onrender.com/api';
}
```

## Testing

### Health Check
```bash
curl https://impactapp-backend.onrender.com/health
```

### Upload Readiness Check
```bash
curl -H "Authorization: Bearer <admin-token>" \
  https://impactapp-backend.onrender.com/api/system/upload-readiness
```

### Register User
```bash
curl -X POST https://your-api-url.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "full_name": "Test User"
  }'
```

### Login
```bash
curl -X POST https://your-api-url.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## Seed Data

Use the bundled production seed script to populate realistic launch data:

```bash
npm run seed:production
```

This seeds:
- role-based users
- membership tiers
- achievements
- courses, modules, lessons
- quizzes and answers
- assignments
- enrollments, analytics, and points
- support tickets and notifications
- parent/mentor relationships
- role resources, partners, and testimonials

## Environment Variables

See `.env.example` for all configuration options.

**Key variables:**
- `DB_HOST`, `DB_USER`, `DB_PASSWORD`: PostgreSQL connection
- `PORT`: Server port (default 3000)
- `JWT_SECRET`: Secret key for JWT signing
- `JWT_REFRESH_SECRET`: Secret key for refresh token rotation
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`: Signed upload configuration
- `NODE_ENV`: `development` or `production`

## Load Testing

Run the focused critical-flow harness against staging or a disposable environment:

```bash
npm run load:test:critical
```

Provide the required tokens and resource ids through environment variables in `.env` or your shell before running it.

The harness covers:
- auth refresh
- classroom activity creation
- classroom live session creation
- upload sign and upload complete
- enrollments listing
- payments lookup

## Error Handling

All endpoints return errors in this format:
```json
{
  "error": "Error message here"
}
```

HTTP Status Codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 409: Conflict
- 500: Server Error

## Next Steps

1. ✅ Deploy to Render
2. ✅ Update Flutter app API URL
3. ✅ Test signup/login flow
4. ✅ Run `npm run seed:production`
5. ✅ Configure Stripe checkout and webhook delivery
6. ✅ Add email notifications
7. ✅ Add admin endpoints for creating courses

## Support

For issues or questions, refer to:
- Flutter app: See `GITHUB_SYNC_AND_NEXT_STEPS.md`
- Database: Check `.env` configuration
- Logs: Monitor via Render dashboard

---

Built with ❤️ for ImpactKnowledge
