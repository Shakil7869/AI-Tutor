@echo off
REM Complete deployment script for Firebase Cloud Functions

echo 🚀 NCTB RAG API - Firebase Cloud Functions Deployment
echo ===================================================

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Error: Firebase CLI not found. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Error: Node.js not found. Please install Node.js first.
    pause
    exit /b 1
)

REM Check if user is logged in
firebase projects:list >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Please login to Firebase first:
    echo firebase login
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist "pdf_management_service\.env" (
    echo ❌ Error: .env file not found in pdf_management_service directory
    echo Please create the .env file with your API keys first.
    echo See .env.example for reference.
    pause
    exit /b 1
)

echo ✅ Prerequisites checked successfully!
echo.

REM Step 1: Install functions dependencies
echo 📦 Step 1: Installing dependencies...
cd functions
npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)
cd ..
echo ✅ Dependencies installed successfully!
echo.

REM Step 2: Set environment variables from .env file
echo 🔧 Step 2: Setting up environment variables...
node setup_firebase_config.js
if %errorlevel% neq 0 (
    echo ❌ Failed to set environment variables
    pause
    exit /b 1
)
echo ✅ Environment variables configured!
echo.

REM Step 3: Deploy functions
echo 🚀 Step 3: Deploying functions to Firebase...
firebase deploy --only functions
if %errorlevel% neq 0 (
    echo ❌ Deployment failed. Please check the errors above.
    pause
    exit /b 1
)

echo.
echo 🎉 DEPLOYMENT SUCCESSFUL! 🎉
echo ================================
echo.
echo Your RAG API is now live at:
echo 🌐 https://us-central1-ai-tutor-oshan.cloudfunctions.net/ragApi
echo.
echo 📋 Next Steps:
echo 1. Test the API health check:
echo    curl https://us-central1-ai-tutor-oshan.cloudfunctions.net/ragApi
echo.
echo 2. Your Flutter app is already configured to use this URL
echo.
echo 3. You can now:
echo    - Upload textbooks via the admin panel
echo    - Use the RAG chat feature
echo    - Generate summaries and quizzes
echo.
echo 📊 Monitor your functions:
echo    - Firebase Console: https://console.firebase.google.com
echo    - View logs: firebase functions:log
echo.

pause
