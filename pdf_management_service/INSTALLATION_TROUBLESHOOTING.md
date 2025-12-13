# 🔧 PDF Service Installation Troubleshooting

## 🚨 PyMuPDF Installation Issues

If you encounter the error `ModuleNotFoundError: No module named 'fitz'`, here are the solutions:

### Solution 1: Manual Installation (Recommended)
```bash
# Upgrade pip first
python -m pip install --upgrade pip

# Install dependencies one by one
pip install Flask
pip install PyMuPDF
pip install Pillow
pip install Werkzeug

# Optional Firebase dependencies (skip if not using Firebase)
pip install firebase-admin
pip install google-cloud-storage
```

### Solution 2: Alternative Package Names
If PyMuPDF fails, try these alternatives:
```bash
# Try different PyMuPDF installation methods
pip install --upgrade PyMuPDF
pip install PyMuPDF==1.24.13
pip install fitz
```

### Solution 3: Use Minimal Requirements
```bash
# Use the minimal requirements file
pip install -r requirements_minimal.txt
```

### Solution 4: System-Specific Installation

**Windows:**
```cmd
# Use Windows-specific packages
pip install --upgrade pip setuptools wheel
pip install PyMuPDF --only-binary=all
```

**Linux/Mac:**
```bash
# Install system dependencies first
sudo apt-get install python3-dev  # Ubuntu/Debian
# OR
brew install python3              # macOS

pip install PyMuPDF
```

## 🧪 Test Your Installation

Run the test script to verify everything works:
```bash
python test_setup.py
```

## 🔄 Alternative: Docker Installation

If you continue having issues, use Docker:

1. Create `Dockerfile`:
```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements_minimal.txt .
RUN pip install -r requirements_minimal.txt

COPY . .
EXPOSE 5000

CMD ["python", "pdf_manager.py"]
```

2. Build and run:
```bash
docker build -t pdf-service .
docker run -p 5000:5000 pdf-service
```

## 📝 Common Issues and Solutions

### Issue: "No module named 'fitz'"
**Solution:** PyMuPDF is not installed properly
```bash
pip install --force-reinstall PyMuPDF
```

### Issue: "Microsoft Visual C++ 14.0 is required"
**Solution:** Install Visual Studio Build Tools (Windows)
- Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
- OR use pre-compiled wheels: `pip install --only-binary=all PyMuPDF`

### Issue: Firebase dependencies fail
**Solution:** Skip Firebase for now
```python
# In pdf_manager.py, set:
FIREBASE_ENABLED = False
```

## ✅ Verification Steps

1. **Test Python imports:**
```python
import flask
import fitz  # PyMuPDF
import PIL   # Pillow
print("All imports successful!")
```

2. **Test PDF processing:**
```python
import fitz
doc = fitz.open()  # Create empty PDF
print(f"PyMuPDF version: {fitz.version}")
```

3. **Test Flask app:**
```bash
python test_setup.py
```

## 🎯 Quick Fix for Your Current Error

**Immediate solution:**
```cmd
cd pdf_management_service
pip install --upgrade pip
pip install PyMuPDF==1.24.13
python pdf_manager.py
```

If that fails, try:
```cmd
pip install PyMuPDF --no-cache-dir --force-reinstall
```

## 🔗 Useful Links

- [PyMuPDF Documentation](https://pymupdf.readthedocs.io/)
- [Python Package Index - PyMuPDF](https://pypi.org/project/PyMuPDF/)
- [Flask Documentation](https://flask.palletsprojects.com/)

---

**If you're still having issues, let me know your Python version and operating system for more specific help!** 🚀
