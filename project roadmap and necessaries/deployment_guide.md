# 🚀 Complete Deployment Guide: EduVision

This guide will walk you through deploying your **Spring Boot Backend** to **Render** and your **Flutter Web Frontend** to **Vercel**.

---

## Part 1: Deploying the Backend to Render

Render is an excellent cloud provider that can automatically build and run Java/Spring Boot applications directly from your GitHub repository.

### Step 1: Push Your Code to GitHub
Ensure your entire `EduVision` project is pushed to a GitHub repository.

### Step 2: Create a Render Web Service
1. Go to [Render.com](https://render.com/) and create a free account (or log in).
2. Click on the **New** button and select **Web Service**.
3. Connect your GitHub account and select your `EduVision` repository.

### Step 3: Configure the Web Service
Fill out the configuration details as follows:
- **Name**: `eduvision-backend` (or any name you prefer)
- **Region**: Choose the region closest to you.
- **Branch**: `main` (or whichever branch you are using).
- **Root Directory**: `eduvisionbackend` *(⚠️ Very Important! This tells Render where the backend code lives)*.
- **Environment**: `Java` (Render will automatically detect this via Maven).
- **Build Command**: `./mvnw clean package -DskipTests`
- **Start Command**: `java -jar target/eduvisionbackend-0.0.1-SNAPSHOT.jar`

### Step 4: Add Environment Variables
Scroll down to the **Environment Variables** section and add the following keys. These match the placeholders we set up in `application.properties`:

| Key | Value (Example) |
| :--- | :--- |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres?sslmode=require&prepareThreshold=0` |
| `SPRING_DATASOURCE_USERNAME` | `postgres.gbokmjcsddiekdbaaiij` |
| `SPRING_DATASOURCE_PASSWORD` | `nehal@1458112` |
| `JWT_SECRET` | *(Provide a long, random 64-character secret string here)* |
| `GEMINI_API_KEY` | `AQ.Ab8RN6JdXs0ARf...` (Your Gemini API Key) |
| `SUPABASE_URL` | `https://gbokmjcsddiekdbaaiij.supabase.co` |
| `SUPABASE_KEY` | `eyJhbGciOiJIUzI1Ni...` (Your Supabase Service Key) |
| `PORT` | `8080` |

### Step 5: Deploy!
1. Click **Create Web Service**.
2. Render will now download your code, build it using Maven, and start the Spring Boot server.
3. Wait for the logs to say `Started EduvisionbackendApplication in X seconds`.
4. **Copy your Render URL**: It will look something like `https://eduvision-backend.onrender.com`. You will need this for the frontend!

---

## Part 2: Deploying the Frontend to Vercel

Vercel is primarily designed for JavaScript frameworks, so it doesn't have Flutter pre-installed on its build servers. The most reliable and fastest way to deploy a Flutter Web app to Vercel is to build it locally and deploy the compiled files using the Vercel CLI.

### Step 1: Install Vercel CLI
You need Node.js installed on your computer. Open your terminal and run:
```bash
npm install -g vercel
```

### Step 2: Build the Flutter Web App Locally
Open your terminal, navigate to the **root** of your Flutter project (where `pubspec.yaml` is located), and build the web app. 

> [!IMPORTANT]
> You MUST replace the URL in the command below with your actual **Render backend URL** obtained from Part 1. Do not add `/api` at the end; just the base domain.

Run this command:
```bash
flutter build web --release --dart-define=API_BASE_URL=https://eduvision-backend.onrender.com
```
*This command injects your Render URL into the `AppConfig.apiBaseUrl` we created earlier, compiling the app so it points to production.*

### Step 3: Deploy the `build/web` folder to Vercel
Once the build is complete, navigate into the generated web folder:
```bash
cd build\web
```

Now, initialize the Vercel deployment:
```bash
vercel
```

Follow the interactive prompts in the terminal:
1. **Set up and deploy?** -> Press `Y`
2. **Which scope do you want to deploy to?** -> Press `Enter` (Select your personal account).
3. **Link to existing project?** -> Press `N`.
4. **What's your project's name?** -> `eduvision-frontend` (or any name).
5. **In which directory is your code located?** -> Press `Enter` (default `./`).
6. **Want to modify these settings?** -> Press `N`.

Vercel will now upload your compiled web files.

### Step 4: Finalize Production Deployment
The first `vercel` command creates a "Preview" deployment. To deploy it to your final, permanent production URL, run:
```bash
vercel --prod
```

### 🎉 You're Done!
Vercel will provide you with a production URL (e.g., `https://eduvision-frontend.vercel.app`). 

Open that URL in your browser, and you should see your fully functioning EduVision app communicating seamlessly with your Spring Boot backend on Render!
