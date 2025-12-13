@echo off
REM Windows batch script to setup and start the RAG pipeline

echo Setting up NCTB RAG Pipeline for Windows...

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)

REM Run the setup script
echo Running setup script...
python setup_rag.py

if errorlevel 1 (
    echo Setup failed!
    pause
    exit /b 1
)

echo.
echo Setup complete! 
echo.
echo To start the RAG API server, run:
echo   start_rag_server.bat
echo.
echo Don't forget to edit the .env file with your API keys!
pause
