#!/bin/bash

# NCTB PDF Management Service Startup Script

echo "🚀 Starting NCTB PDF Management Service..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip."
    exit 1
fi

# Navigate to the PDF service directory
cd "$(dirname "$0")"

# Check if virtual environment exists, if not create it
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/upgrade requirements
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Check if Firebase config exists
if [ ! -f "config/firebase_config.json" ]; then
    echo "⚠️  Firebase configuration not found."
    echo "📝 Please add your Firebase service account key to config/firebase_config.json"
    echo "💡 You can still use the service with local storage only."
fi

# Create necessary directories
mkdir -p data/uploads
mkdir -p config

# Set environment variables (optional)
export FLASK_ENV=development
export FLASK_DEBUG=1

# Start the Firebase-enabled service
echo "🌟 Starting PDF Management Service with Firebase support on http://localhost:5000"
echo "📚 Upload interface: http://localhost:5000/"
echo "⚙️  Configuration: http://localhost:5000/configure"
echo "📊 Service status: http://localhost:5000/status"
echo "🔥 Firebase status: http://localhost:5000/firebase_status"
echo ""
echo "📖 Service will use Firebase if configured, otherwise HTTP fallback"
echo "🛑 Press Ctrl+C to stop the service"
echo ""

python pdf_manager_firebase.py
