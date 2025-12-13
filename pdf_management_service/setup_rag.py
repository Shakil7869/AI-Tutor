#!/usr/bin/env python3
"""
Setup script for NCTB RAG Pipeline
Installs dependencies and sets up the environment
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def run_command(command, check=True):
    """Run a shell command"""
    print(f"Running: {command}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    return result

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("Error: Python 3.8 or higher is required")
        sys.exit(1)
    print(f"✓ Python {sys.version_info.major}.{sys.version_info.minor} detected")

def setup_virtual_environment():
    """Setup Python virtual environment"""
    venv_path = Path("venv")
    
    if venv_path.exists():
        print("✓ Virtual environment already exists")
        return
    
    print("Setting up virtual environment...")
    run_command(f"{sys.executable} -m venv venv")
    print("✓ Virtual environment created")

def install_dependencies():
    """Install Python dependencies"""
    print("Installing dependencies...")
    
    # Determine the correct pip path
    if os.name == 'nt':  # Windows
        pip_path = "venv\\Scripts\\pip"
        python_path = "venv\\Scripts\\python"
    else:  # Linux/Mac
        pip_path = "venv/bin/pip"
        python_path = "venv/bin/python"
    
    # Upgrade pip first
    run_command(f"{pip_path} install --upgrade pip")
    
    # Install dependencies
    run_command(f"{pip_path} install -r requirements_rag.txt")
    print("✓ Dependencies installed")

def setup_environment_file():
    """Setup environment variables file"""
    env_file = Path(".env")
    env_example = Path(".env.example")
    
    if env_file.exists():
        print("✓ .env file already exists")
        return
    
    if env_example.exists():
        shutil.copy(env_example, env_file)
        print("✓ Created .env file from .env.example")
        print("⚠️  Please edit .env file and add your API keys")
    else:
        # Create a basic .env file
        with open(env_file, 'w') as f:
            f.write("""# NCTB RAG Pipeline Environment Variables
# Replace with your actual API keys

OPENAI_API_KEY=your_openai_api_key_here
PINECONE_API_KEY=your_pinecone_api_key_here
FIREBASE_CREDENTIALS_PATH=path/to/your/firebase-credentials.json

# Optional configuration
API_HOST=0.0.0.0
API_PORT=5000
DEBUG_MODE=true
""")
        print("✓ Created .env file")
        print("⚠️  Please edit .env file and add your API keys")

def download_nltk_data():
    """Download required NLTK data"""
    print("Downloading NLTK data...")
    
    if os.name == 'nt':  # Windows
        python_path = "venv\\Scripts\\python"
    else:  # Linux/Mac
        python_path = "venv/bin/python"
    
    nltk_script = """
import nltk
try:
    nltk.data.find('tokenizers/punkt')
    print('✓ NLTK punkt tokenizer already downloaded')
except LookupError:
    print('Downloading NLTK punkt tokenizer...')
    nltk.download('punkt')
    print('✓ NLTK punkt tokenizer downloaded')
"""
    
    with open('temp_nltk_setup.py', 'w') as f:
        f.write(nltk_script)
    
    run_command(f"{python_path} temp_nltk_setup.py")
    os.remove('temp_nltk_setup.py')
    print("✓ NLTK data setup complete")

def create_directories():
    """Create necessary directories"""
    directories = [
        "data",
        "data/textbooks",
        "data/processed",
        "logs",
        "temp"
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
    
    print("✓ Created necessary directories")

def test_imports():
    """Test if all required packages can be imported"""
    print("Testing imports...")
    
    if os.name == 'nt':  # Windows
        python_path = "venv\\Scripts\\python"
    else:  # Linux/Mac
        python_path = "venv/bin/python"
    
    test_script = """
try:
    import openai
    import pinecone
    import fitz
    import flask
    import nltk
    import tiktoken
    print('✓ All required packages imported successfully')
except ImportError as e:
    print(f'✗ Import error: {e}')
    exit(1)
"""
    
    with open('temp_test_imports.py', 'w') as f:
        f.write(test_script)
    
    result = run_command(f"{python_path} temp_test_imports.py", check=False)
    os.remove('temp_test_imports.py')
    
    if result.returncode != 0:
        print("✗ Import test failed")
        sys.exit(1)

def print_next_steps():
    """Print instructions for next steps"""
    print("\n" + "="*60)
    print("🎉 NCTB RAG Pipeline Setup Complete!")
    print("="*60)
    print("\nNext Steps:")
    print("1. Edit the .env file and add your API keys:")
    print("   - OPENAI_API_KEY")
    print("   - PINECONE_API_KEY")
    print("   - FIREBASE_CREDENTIALS_PATH (optional)")
    print("\n2. To start the RAG API server:")
    
    if os.name == 'nt':  # Windows
        print("   venv\\Scripts\\python rag_api_server.py")
    else:  # Linux/Mac
        print("   venv/bin/python rag_api_server.py")
    
    print("\n3. Upload textbooks through the web interface:")
    print("   http://localhost:5000/admin/upload-form")
    print("\n4. Test the API:")
    print("   http://localhost:5000/")
    print("\n5. Integration with Flutter:")
    print("   Update the base URL in rag_service.dart if needed")
    print("\n📚 Ready to process NCTB textbooks!")

def main():
    """Main setup function"""
    print("🚀 Setting up NCTB RAG Pipeline...")
    print("="*40)
    
    # Check requirements
    check_python_version()
    
    # Setup environment
    setup_virtual_environment()
    install_dependencies()
    setup_environment_file()
    
    # Additional setup
    create_directories()
    download_nltk_data()
    test_imports()
    
    # Final instructions
    print_next_steps()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n❌ Setup interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Setup failed: {e}")
        sys.exit(1)
