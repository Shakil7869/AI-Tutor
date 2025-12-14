"""
Firebase Configuration Loader

Loads Firebase service account credentials from environment variables.
This replaces the need for a hardcoded JSON file.
"""

import os
import json
from typing import Dict, Any
from dotenv import load_dotenv


def load_firebase_config_from_env() -> Dict[str, Any]:
    """
    Load Firebase configuration from environment variables.
    
    Returns:
        Dictionary containing Firebase service account credentials
        
    Raises:
        ValueError: If required Firebase environment variables are missing
    """
    load_dotenv()
    
    required_keys = [
        'FIREBASE_PROJECT_ID',
        'FIREBASE_PRIVATE_KEY_ID',
        'FIREBASE_PRIVATE_KEY',
        'FIREBASE_CLIENT_EMAIL',
        'FIREBASE_CLIENT_ID',
    ]
    
    # Check if all required keys are present
    missing_keys = [key for key in required_keys if not os.getenv(key)]
    if missing_keys:
        raise ValueError(
            f"Missing Firebase configuration. Required environment variables: {', '.join(missing_keys)}"
        )
    
    # Reconstruct the private key (handle escaped newlines)
    private_key = os.getenv('FIREBASE_PRIVATE_KEY', '')
    # Replace literal \n with actual newlines
    private_key = private_key.replace('\\n', '\n')
    
    config = {
        'type': 'service_account',
        'project_id': os.getenv('FIREBASE_PROJECT_ID'),
        'private_key_id': os.getenv('FIREBASE_PRIVATE_KEY_ID'),
        'private_key': private_key,
        'client_email': os.getenv('FIREBASE_CLIENT_EMAIL'),
        'client_id': os.getenv('FIREBASE_CLIENT_ID'),
        'auth_uri': os.getenv('FIREBASE_AUTH_URI', 'https://accounts.google.com/o/oauth2/auth'),
        'token_uri': os.getenv('FIREBASE_TOKEN_URI', 'https://oauth2.googleapis.com/token'),
        'auth_provider_x509_cert_url': os.getenv(
            'FIREBASE_AUTH_PROVIDER_X509_CERT_URL',
            'https://www.googleapis.com/oauth2/v1/certs'
        ),
        'client_x509_cert_url': os.getenv('FIREBASE_CLIENT_X509_CERT_URL'),
        'universe_domain': os.getenv('FIREBASE_UNIVERSE_DOMAIN', 'googleapis.com'),
    }
    
    return config


def get_firebase_config_json() -> str:
    """
    Get Firebase configuration as JSON string.
    
    Returns:
        JSON string of Firebase configuration
    """
    config = load_firebase_config_from_env()
    return json.dumps(config, indent=2)


if __name__ == '__main__':
    # Test loading and print the configuration
    try:
        config = load_firebase_config_from_env()
        print("Firebase configuration loaded successfully!")
        print(json.dumps({k: v if k != 'private_key' else '***' for k, v in config.items()}, indent=2))
    except ValueError as e:
        print(f"Error loading Firebase configuration: {e}")
