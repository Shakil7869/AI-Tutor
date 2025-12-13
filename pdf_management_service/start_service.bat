@echo off
REM NCTB PDF Management Service Startup Script for Windows

echo 🚀 Starting NCTB PDF Management Service...

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed. Please install Python 3.8 or higher.
    echo 🔗 Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Navigate to the PDF service directory
cd /d "%~dp0"

REM Run system test first
echo 🔧 Running system compatibility test...
python test_setup.py
if errorlevel 1 (
    echo ❌ System test failed. Please fix the issues above.
    pause
    exit /b 1
)

echo ✅ System test passed! Continuing with service startup...
echo.

REM Navigate to the PDF service directory
cd /d "%~dp0"

REM Check if virtual environment exists, if not create it
if not exist "venv" (
    echo 📦 Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate.bat

REM Install/upgrade requirements
echo 📥 Installing dependencies...
pip install --upgrade pip
pip install Flask Pillow Werkzeug
echo 📥 Installing PyMuPDF (PDF processing library)...
pip install PyMuPDF

REM Try to install Firebase dependencies (optional)
echo 📥 Installing optional Firebase dependencies...
pip install firebase-admin google-cloud-storage 2>nul || (
    echo ⚠️  Firebase dependencies failed to install - continuing without Firebase support
)

REM Check if Firebase config exists
if not exist "config\firebase_config.json" (
    echo ⚠️  Firebase configuration not found.
    echo 📝 Please add your Firebase service account key to config\firebase_config.json
    echo 💡 You can still use the service with local storage only.
)
 
REM Create necessary directories
if not exist "data" mkdir data
if not exist "data\uploads" mkdir data\uploads
if not exist "config" mkdir config

REM Set environment variables (optional)
set FLASK_ENV=development
set FLASK_DEBUG=1

REM Start the Firebase-enabled service
echo.
echo 🌟 Starting PDF Management Service with Firebase support on http://localhost:5000
echo 📚 Upload interface: http://localhost:5000/
echo ⚙️  Configuration: http://localhost:5000/configure
echo 📊 Service status: http://localhost:5000/status
echo 🔥 Firebase status: http://localhost:5000/firebase_status
echo.
echo � Service will use Firebase if configured, otherwise HTTP fallback
echo �🛑 Press Ctrl+C to stop the service
echo.

python pdf_manager_firebase.py

pause
