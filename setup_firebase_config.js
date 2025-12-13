const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Read .env file from pdf_management_service
const envPath = path.join(__dirname, 'pdf_management_service', '.env');

if (!fs.existsSync(envPath)) {
  console.error('❌ .env file not found at:', envPath);
  console.log('Please create the .env file with your API keys first.');
  process.exit(1);
}

const envContent = fs.readFileSync(envPath, 'utf8');
const envVars = {};

// Parse .env file
envContent.split('\n').forEach(line => {
  line = line.trim();
  if (line && !line.startsWith('#')) {
    const [key, value] = line.split('=');
    if (key && value) {
      envVars[key.trim()] = value.trim();
    }
  }
});

console.log('🔧 Setting up Firebase Functions environment variables...');

try {
  // Set OpenAI API key
  if (envVars.OPENAI_API_KEY) {
    console.log('Setting OpenAI API key...');
    execSync(`firebase functions:config:set openai.key="${envVars.OPENAI_API_KEY}"`, { stdio: 'inherit' });
  } else {
    console.warn('⚠️  OpenAI API key not found in .env file');
  }

  // Set Pinecone API key
  if (envVars.PINECONE_API_KEY) {
    console.log('Setting Pinecone API key...');
    execSync(`firebase functions:config:set pinecone.key="${envVars.PINECONE_API_KEY}"`, { stdio: 'inherit' });
  } else {
    console.warn('⚠️  Pinecone API key not found in .env file');
  }

  console.log('✅ Environment variables set successfully!');
  console.log('\nNow you can deploy the functions:');
  console.log('firebase deploy --only functions');

} catch (error) {
  console.error('❌ Error setting environment variables:', error.message);
  console.log('\nMake sure you are logged in to Firebase:');
  console.log('firebase login');
  process.exit(1);
}
