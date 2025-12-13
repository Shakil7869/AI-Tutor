@echo off

rem Chapter PDF Management System Startup Script for Windows

echo 🚀 Starting Chapter PDF Management System...

rem Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is not installed. Please install Python 3.8 or higher.
    pause
    exit /b 1
)

rem Check if pip is installed
pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ pip is not installed. Please install pip.
    pause
    exit /b 1
)

rem Navigate to the PDF management service directory
cd pdf_management_service

rem Check if virtual environment exists, if not create it
if not exist "venv" (
    echo 📦 Creating virtual environment...
    python -m venv venv
)

rem Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate.bat

rem Install dependencies
echo 📚 Installing dependencies...
pip install -r requirements.txt

rem Check for environment variables
echo 🔍 Checking environment variables...

if "%PINECONE_API_KEY%"=="" (
    echo ⚠️  PINECONE_API_KEY not set. Please set it in your environment or .env file.
)

if "%OPENAI_API_KEY%"=="" (
    echo ⚠️  OPENAI_API_KEY not set. Please set it in your environment or .env file.
)

if "%FIREBASE_SERVICE_ACCOUNT_PATH%"=="" (
    echo ⚠️  FIREBASE_SERVICE_ACCOUNT_PATH not set. Please set it in your environment or .env file.
)

rem Create .env file if it doesn't exist
if not exist ".env" (
    echo 📝 Creating .env template...
    (
        echo # Pinecone Configuration
        echo PINECONE_API_KEY=your_pinecone_api_key_here
        echo PINECONE_ENVIRONMENT=your_pinecone_environment_here
        echo PINECONE_INDEX_NAME=chapter-pdfs
        echo.
        echo # OpenAI Configuration
        echo OPENAI_API_KEY=your_openai_api_key_here
        echo.
        echo # Firebase Configuration
        echo FIREBASE_SERVICE_ACCOUNT_PATH=path/to/your/firebase-service-account.json
        echo FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
        echo.
        echo # Flask Configuration
        echo FLASK_PORT=5000
        echo FLASK_DEBUG=False
    ) > .env
    echo 📝 .env file created. Please fill in your API keys and configuration.
)

rem Start the Flask service
echo 🌟 Starting Chapter PDF Management Service...
python chapter_pdf_manager.py

echo ✅ Chapter PDF Management Service is running on http://localhost:5000
echo 📖 API Documentation available at http://localhost:5000/docs
pause
