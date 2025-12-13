#!/bin/bash
# Deploy Firebase Cloud Functions with environment variables

echo "Deploying NCTB RAG API to Firebase Cloud Functions..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Error: Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "Please login to Firebase first:"
    echo "firebase login"
    exit 1
fi

# Navigate to functions directory
cd functions

# Install dependencies
echo "Installing dependencies..."
npm install

# Go back to root
cd ..

# Set environment variables (you'll need to update these with your actual keys)
echo "Setting environment variables..."
firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY_HERE"
firebase functions:config:set pinecone.key="YOUR_PINECONE_API_KEY_HERE"

echo ""
echo "IMPORTANT: Please update the API keys above with your actual keys before deploying!"
echo "You can set them using:"
echo "firebase functions:config:set openai.key=\"your_actual_openai_key\""
echo "firebase functions:config:set pinecone.key=\"your_actual_pinecone_key\""
echo ""

# Deploy functions
echo "Deploying functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo "Your RAG API is now available at:"
    echo "https://us-central1-ai-tutor-oshan.cloudfunctions.net/ragApi"
    echo ""
    echo "Next steps:"
    echo "1. Test the API endpoint"
    echo "2. Update your Flutter app to use the new URL"
    echo "3. Upload your textbooks using the /upload-textbook endpoint"
else
    echo "❌ Deployment failed. Please check the errors above."
fi
