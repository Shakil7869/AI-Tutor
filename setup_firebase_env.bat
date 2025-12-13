@echo off
REM Set Firebase Functions environment variables
REM Replace the placeholder values with your actual API keys

echo Setting up Firebase Functions environment variables...

REM Read API keys from .env file if it exists
if exist "pdf_management_service\.env" (
    echo Found .env file, reading API keys...
    
    REM You'll need to manually extract and set these
    echo Please run the following commands with your actual API keys:
    echo.
    echo firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY"
    echo firebase functions:config:set pinecone.key="YOUR_PINECONE_API_KEY"
    echo.
    echo Then run: firebase deploy --only functions
) else (
    echo .env file not found. Please set your API keys manually:
    echo.
    echo firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY"
    echo firebase functions:config:set pinecone.key="YOUR_PINECONE_API_KEY"
    echo.
)

pause
