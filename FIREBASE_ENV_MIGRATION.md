# Firebase Configuration Migration to Environment Variables

## Overview
Migrated Firebase service account credentials from `firebase_config.json` to the `.env` file for better security and configuration management.

## Changes Made

### 1. **Updated `.env` file**
   - Added all Firebase service account fields as environment variables:
     - `FIREBASE_PROJECT_ID`
     - `FIREBASE_PRIVATE_KEY_ID`
     - `FIREBASE_PRIVATE_KEY`
     - `FIREBASE_CLIENT_EMAIL`
     - `FIREBASE_CLIENT_ID`
     - `FIREBASE_AUTH_URI`
     - `FIREBASE_TOKEN_URI`
     - `FIREBASE_AUTH_PROVIDER_X509_CERT_URL`
     - `FIREBASE_CLIENT_X509_CERT_URL`

### 2. **Updated `.env.example`**
   - Provides a template for setting up Firebase credentials
   - All values marked with placeholders like `your_firebase_project_id`

### 3. **Deleted `firebase_config.json`**
   - Removed the hardcoded JSON file that contained sensitive credentials
   - Path: `pdf_management_service/config/firebase_config.json`

### 4. **Updated `.gitignore`**
   - Added `.env` file to gitignore to prevent accidental commits
   - Added `.env.local` and `.env.*.local` patterns for local overrides

### 5. **Created `firebase_config_loader.py`**
   - New utility script to load Firebase configuration from environment variables
   - Location: `pdf_management_service/firebase_config_loader.py`
   - Features:
     - Loads and validates Firebase config from `.env` file
     - Provides JSON serialization for use with Firebase libraries
     - Error handling for missing required credentials
     - Test functionality to verify configuration loading

## Usage

### For Python Backend (pdf_management_service)
```python
from firebase_config_loader import load_firebase_config_from_env

# Load configuration from .env
firebase_config = load_firebase_config_from_env()

# Use with Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials

cred = credentials.Certificate(firebase_config)
firebase_admin.initialize_app(cred)
```

### Testing Configuration
```bash
cd pdf_management_service
python firebase_config_loader.py
```

## Security Benefits
✅ Credentials no longer hardcoded in version control  
✅ Environment-based configuration allows different credentials per environment  
✅ `.env` files are listed in `.gitignore`  
✅ Easy credential rotation - just update `.env`  
✅ Follows 12-factor app methodology  

## Setup Instructions for New Environment

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Fill in your actual Firebase credentials:
   ```bash
   FIREBASE_PROJECT_ID=your_actual_project_id
   FIREBASE_PRIVATE_KEY_ID=your_actual_key_id
   # ... etc
   ```

3. The application will automatically load these values at runtime

## Notes
- The private key in `.env` uses escaped newlines (`\n`) which are automatically converted to actual newlines when loaded
- Never commit the actual `.env` file to version control
- Each developer/environment should have their own `.env` file with the appropriate credentials
