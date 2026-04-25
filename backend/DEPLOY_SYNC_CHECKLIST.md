# Backend-Only Deployment & Migration Checklist

This checklist syncs production with the new realistic role dashboards, relationship workflows, and behavior-driven notifications.

## 1) Pre-Deploy Gate

- Confirm branch includes:
  - `src/routes/dashboard.js`
  - `src/routes/relationships.js`
  - `src/routes/notifications.js`
  - `src/routes/search.js`
  - `src/routes/public.js`
  - `src/routes/events.js` (attendance notification placement fix)
  - `src/routes/courses.js`
  - `src/routes/assignments.js`
  - `src/routes/moderation.js`
  - `src/routes/payments.js`
  - `src/database/index.js`
  - `scripts/verify-nonlearner-dashboards.js`
- Confirm `server.js` mounts:
  - `/api/relationships`
  - `/api/notifications`
  - `/api/search`
  - `/api/public`
  - `/api/role-resources`

## 2) Render Service Config

Current Render config is in `render.yaml` and uses:
- Service: `impactapp-backend`
- Root dir: `backend`
- Build command: `npm install`
- Start command: `npm start`
- DB source: `DATABASE_URL` from managed Render DB

Required env vars:
- `DATABASE_URL` (already from Render DB)
- `JWT_SECRET` (set in Render dashboard)
- `NODE_ENV=production`
- `FIREBASE_SERVER_KEY` (required for push delivery; optional for in-app only)
- Optional hardening: `FILE_DOWNLOAD_SECRET`

## 3) Migration Strategy

The app uses startup DDL (`initializeDatabase`) instead of migration files.

On deploy startup, verify successful creation/backfill for:
- Parent/mentor links:
  - `parent_child_links`
  - `mentor_mentee_links`
- Role realism support:
  - `role_resources`
  - `notifications`
  - `payment_refunds`
  - `platform_partners`
  - `testimonials`
- Backfills:
  - `lessons.content_body`
  - `lessons.is_published`

Render logs should include:
- `Database tables initialized successfully`
- `Database initialized successfully`

## 4) Contract Verification (Post-Deploy)

Run from workspace root:

```powershell
$env:VERIFY_BASE_URL='https://impactapp-backend.onrender.com'; npm --prefix backend run verify:dashboards
```

Expected role contracts:
- `parent`: `childrenLinked`, `avgProgress`, `attendanceRate`, `unreadMessages`
- `facilitator` and `instructor`: `activeClasses`, `pendingReviews`, `atRiskLearners`, `unreadMessages`
- `school_admin`: `totalStudents`, `totalFacilitators`, `completionRate`, `openAlerts`
- `mentor`: `totalMentees`, `upcomingSessions`, `completedSessions`, `avgMenteeGrowth`
- `circle_member`: `connections`, `postsThisMonth`, `roundtables`, `profileReach`
- `uni_member`: `ventureStage`, `teamMembers`, `mentorSessions`, `openOpportunities`
- `admin`: `totalUsers`, `activeCourses`, `completionRate`, `openAlerts`

## 5) Behavioral Notification Coverage Audit

Smoke-check these actions in production:
- Course publish/unpublish and announcements
- Assignment created and graded
- Moderation escalation + resolution notifications
- Payment verification success notifications
- Event create/update/delete/register/unregister/attendance notifications
- Admin role/deactivate/reactivate notifications

## 6) Regression Guardrails

- Run syntax checks before deploy:

```powershell
node -c backend/src/routes/auth.js; node -c backend/src/routes/events.js; node -c backend/src/routes/dashboard.js
```

- Validate health:

```powershell
Invoke-WebRequest https://impactapp-backend.onrender.com/health
```

- Validate one authenticated dashboard per role after verifier completes.

## 7) Rollback Trigger

Rollback immediately if any of these occur:
- `verify:dashboards` < 8/8
- Authentication failures on `/api/auth/register` or `/api/auth/login`
- Route errors on `/api/dashboard/*` or `/api/relationships/*`
- Startup DB initialization errors

## 8) Reality-Quality Acceptance

The backend is considered production-realistic only when:
- Non-learner role dashboards return live summary keys from real tables.
- Parent/mentor workflows are persisted in dedicated domain tables.
- High-signal user actions generate in-app notifications and push where configured.
- Verification script and role API outputs align with frontend dashboard contracts.
