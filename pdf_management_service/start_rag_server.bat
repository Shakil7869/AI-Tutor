@echo off
REM Windows batch script to start the RAG API server

echo Starting NCTB RAG API Server...

REM Check if virtual environment exists
if not exist "venv" (
    echo Error: Virtual environment not found!
    echo Please run setup_rag.bat first
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist ".env" (
    echo Error: .env file not found!
    echo Please create .env file with your API keys
    pause
    exit /b 1
)

REM Activate virtual environment and start server
echo Activating virtual environment...
call venv\Scripts\activate

echo Starting RAG API server on http://localhost:5000
echo Press Ctrl+C to stop the server
echo.

python rag_api_server.py

echo.
echo Server stopped.
pause
