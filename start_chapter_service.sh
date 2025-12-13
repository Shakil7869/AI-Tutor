#!/bin/bash

# Chapter PDF Management System Startup Script

echo "🚀 Starting Chapter PDF Management System..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip3."
    exit 1
fi

# Navigate to the PDF management service directory
cd pdf_management_service

# Check if virtual environment exists, if not create it
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Check for environment variables
echo "🔍 Checking environment variables..."

if [ -z "$PINECONE_API_KEY" ]; then
    echo "⚠️  PINECONE_API_KEY not set. Please set it in your environment or .env file."
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY not set. Please set it in your environment or .env file."
fi

if [ -z "$FIREBASE_SERVICE_ACCOUNT_PATH" ]; then
    echo "⚠️  FIREBASE_SERVICE_ACCOUNT_PATH not set. Please set it in your environment or .env file."
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env template..."
    cat > .env << EOL
# Pinecone Configuration
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_ENVIRONMENT=your_pinecone_environment_here
PINECONE_INDEX_NAME=chapter-pdfs

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_PATH=path/to/your/firebase-service-account.json
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com

# Flask Configuration
FLASK_PORT=5000
FLASK_DEBUG=False
EOL
    echo "📝 .env file created. Please fill in your API keys and configuration."
fi

# Start the Flask service
echo "🌟 Starting Chapter PDF Management Service..."
python chapter_pdf_manager.py

echo "✅ Chapter PDF Management Service is running on http://localhost:5000"
echo "📖 API Documentation available at http://localhost:5000/docs"
