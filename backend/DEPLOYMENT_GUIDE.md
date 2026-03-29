# Backend Deployment to Render

This guide walks you through deploying the ImpactKnowledge backend to Render.

## Prerequisites

- GitHub account (recommended) or Render account
- PostgreSQL database already created on Render (from earlier setup)
- Backend code in `impactapp-backend/` directory

## Option A: Deploy via GitHub (Recommended)

### 1. Push backend code to GitHub

First, create a GitHub repository for the backend:

```bash
cd c:\DEV3\ImpactEdu\impactapp-backend
git init
git add .
git commit -m "Initial commit: ImpactKnowledge backend API"
git remote add origin https://github.com/Ukwun/impactapp-backend.git
git push -u origin main
```

### 2. Create Web Service on Render

1. Go to https://dashboard.render.com
2. Click **New +** → **Web Service**
3. Select **Build and deploy from a Git repository**
4. Find and select your `impactapp-backend` repository
5. Configure:
   - **Name**: `impactapp-backend`
   - **Region**: Choose closest to your users
   - **Branch**: `main`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free (for testing) or Paid (for production)

### 3. Add Environment Variables

In Render dashboard, under **Environment**:

```
DB_USER=impactapp_db_user
DB_PASSWORD=[Copy from your database password]
DB_HOST=dpg-d6mv5tp4tr6s738nigv0-a.oregon-postgres.render.com
DB_PORT=5432
DB_NAME=impactapp_db
PORT=3000
NODE_ENV=production
JWT_SECRET=[Generate a long random string]
FLUTTERWAVE_PUBLIC_KEY=[Optional for now]
FLUTTERWAVE_SECRET_KEY=[Optional for now]
```

To generate JWT_SECRET, run:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 4. Deploy

Click **Create Web Service** and Render will:
1. Clone your GitHub repo
2. Install dependencies
3. Start the server
4. Assign you a URL like: `https://impactapp-backend.onrender.com`

**Deployment takes 2-5 minutes.** Check the logs for any errors.

### 5. Verify Deployment

```bash
curl https://impactapp-backend.onrender.com/health
```

Should return:
```json
{"status":"ok","timestamp":"2024-03-29T..."}
```

## Option B: Deploy via File Upload (If no GitHub)

1. Zip the `impactapp-backend` folder
2. Go to https://dashboard.render.com → **New** → **Web Service**
3. Select **Deploy from repository** (but use their upload option)
4. Upload the ZIP file
5. Follow steps 3-5 above

## Option C: Deploy with Docker

If you want more control, create a `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

Then in Render, select **Docker** as runtime.

## Database Connection Issues?

If you get database connection errors:

1. **Check Render's internal database URL** (not the external one!)
   - In Render PostgreSQL dashboard, copy the **Internal Database URL**
   - It should be similar to your external URL

2. **Verify credentials**:
   ```
   postgres://[user]:[password]@[host]:[port]/[database]
   ```

3. **Check firewall rules**
   - Render Web Services can reach internal databases automatically
   - External connections need IP whitelisting

4. **Test connection locally**:
   ```bash
   npm run dev
   ```

## Monitoring & Logs

- **Logs**: Render dashboard → Your service → **Logs** tab
- **Redeploy**: Make changes → `git push` → Render auto-deploys
- **Environment**: Update variables → Automatic service restart

## What's the Backend URL?

After deployment, your API is at:
```
https://impactapp-backend.onrender.com/api
```

### Use this in Flutter app:

**Update `lib/config/app_config.dart`**:

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://impactapp-backend.onrender.com/api';
}
```

Then rebuild the APK:
```bash
flutter clean
flutter build apk --release
```

## Free Plan Limitations

Render's free tier:
- ✅ Good for testing
- ⚠️ Spins down after 15 minutes of inactivity
- ⚠️ ~0.5GB RAM, limited CPU
- ✅ Automatic redeploy on `git push`

**For production**, upgrade to **Standard** ($12/month+).

## Production Checklist

Before going live:

- [ ] Set `NODE_ENV=production`
- [ ] Use strong `JWT_SECRET`
- [ ] Set database password
- [ ] Configure Flutterwave keys (for payments)
- [ ] Set up error monitoring (Sentry, etc.)
- [ ] Add logging/analytics
- [ ] Test all endpoints thoroughly
- [ ] Set up database backups

## Next Steps

1. ✅ Deploy backend to Render
2. ✅ Copy the backend URL
3. ✅ Update `lib/config/app_config.dart` in Flutter
4. ✅ Rebuild APK with new API URL
5. ✅ Test signup/login with your client
6. ✅ Add test data (courses, achievements)
7. ✅ Configure Flutterwave for payments

---

Done! Your backend is now live! 🚀

For help: Check Render logs or contact support@render.com
