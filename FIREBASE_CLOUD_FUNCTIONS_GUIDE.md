# Firebase Cloud Functions RAG API Setup Guide

This guide will help you deploy the NCTB RAG API from localhost to Firebase Cloud Functions for production use.

## Prerequisites

1. **Firebase CLI** - Install globally:
   ```bash
   npm install -g firebase-tools
   ```

2. **Node.js 18+** - Required for Firebase Functions

3. **API Keys**:
   - OpenAI API Key
   - Pinecone API Key

## Step 1: Firebase Setup

1. **Login to Firebase**:
   ```bash
   firebase login
   ```

2. **Initialize Firebase (if not already done)**:
   ```bash
   firebase init
   ```
   Select:
   - Functions: Configure a Cloud Functions directory
   - Use existing project: `ai-tutor-oshan`

## Step 2: Install Dependencies

Navigate to the functions directory and install dependencies:
```bash
cd functions
npm install
cd ..
```

## Step 3: Set Environment Variables

Set your API keys as Firebase Functions configuration:

```bash
# Replace with your actual OpenAI API key
firebase functions:config:set openai.key="sk-your-openai-api-key-here"

# Replace with your actual Pinecone API key
firebase functions:config:set pinecone.key="pc-your-pinecone-api-key-here"
```

## Step 4: Deploy Functions

Deploy the RAG API to Firebase Cloud Functions:

```bash
firebase deploy --only functions
```

Or use the provided script:
```bash
# Windows
deploy_functions.bat

# Linux/Mac
chmod +x deploy_functions.sh
./deploy_functions.sh
```

## Step 5: Update Flutter App

The Flutter app is already updated to use the Cloud Function URL:
```
https://us-central1-ai-tutor-oshan.cloudfunctions.net/ragApi
```

## API Endpoints

Once deployed, your RAG API will be available at the following endpoints:

### Base URL
```
https://us-central1-ai-tutor-oshan.cloudfunctions.net/ragApi
```

### Available Endpoints

1. **Health Check**
   - `GET /`
   - Returns service status and initialization state

2. **Upload Textbook**
   - `POST /upload-textbook`
   - Upload and process PDF textbooks
   - Form data: `file`, `class_level`, `subject`, `chapter_name` (optional)

3. **Ask Question**
   - `POST /ask-question`
   - Get AI-powered answers using RAG
   - Body: `{ "question": "...", "class_level": "9", "subject": "Physics", "chapter": "Motion" }`

4. **Search Content**
   - `POST /search-content`
   - Search for relevant textbook chunks
   - Body: `{ "query": "...", "class_level": "9", "subject": "Physics", "top_k": 5 }`

5. **Generate Summary**
   - `POST /generate-summary`
   - Generate chapter summaries
   - Body: `{ "class_level": "9", "subject": "Physics", "chapter": "Motion" }`

6. **Generate Quiz**
   - `POST /generate-quiz`
   - Create quizzes from textbook content
   - Body: `{ "class_level": "9", "subject": "Physics", "chapter": "Motion", "mcq_count": 5, "short_count": 2 }`

7. **List Subjects**
   - `GET /list-subjects`
   - Get available subjects for each class

## Testing the Deployment

1. **Test Health Check**:
   ```bash
   curl https://us-central1-ai-tutor-oshan.cloudfunctions.net/ragApi
   ```

2. **Test in Flutter App**:
   - Run your Flutter app
   - Navigate to the class selection screen
   - Try uploading a PDF (admin feature)
   - Ask questions in the chat

## Advantages of Cloud Functions

1. **Scalability**: Automatically scales based on demand
2. **Cost-Effective**: Pay only for execution time
3. **Global**: Available worldwide with low latency
4. **Maintenance-Free**: No server management required
5. **Secure**: Built-in security and HTTPS

## Important Notes

1. **Cold Starts**: First request may take 10-30 seconds to warm up
2. **Timeout**: Functions have a 9-minute timeout limit
3. **Memory**: Configured for 2GB memory for AI operations
4. **Costs**: Monitor usage to avoid unexpected charges

## Monitoring and Logs

1. **View Logs**:
   ```bash
   firebase functions:log
   ```

2. **Firebase Console**:
   - Visit [Firebase Console](https://console.firebase.google.com)
   - Navigate to Functions section
   - Monitor performance and logs

## Troubleshooting

1. **Environment Variables**: Ensure API keys are set correctly
2. **CORS Issues**: The function includes CORS headers
3. **Timeout**: Large PDF uploads may timeout - consider chunking
4. **Memory**: Increase memory allocation if needed

## Migration from Localhost

The Flutter app automatically switches from `localhost:5000` to the Cloud Function URL. No additional changes needed in the app code.

## Security Considerations

1. API keys are stored securely in Firebase Functions config
2. All endpoints use HTTPS
3. Consider adding authentication for production use
4. Monitor API usage to prevent abuse

Your RAG API is now ready for production use with Firebase Cloud Functions!
