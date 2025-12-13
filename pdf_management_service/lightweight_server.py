#!/usr/bin/env python3
"""
Lightweight Chapter PDF Manager
Optimized version for better laptop performance
"""

import os
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify, render_template_string
import gc  # Garbage collection
from werkzeug.utils import secure_filename

# Setup minimal logging
logging.basicConfig(level=logging.WARNING)  # Reduced logging
logger = logging.getLogger(__name__)

# Lightweight Flask app
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # Reduced to 50MB
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'data', 'chapters')

# Create directories
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Simplified chapter definitions (only essential info)
CHAPTERS_SIMPLE = {
    'real_numbers': {'num': 1, 'name': 'Real Numbers', 'bn': 'বাস্তব সংখ্যা'},
    'sets_functions': {'num': 2, 'name': 'Sets and Functions', 'bn': 'সেট ও ফাংশন'},
    'algebraic_expressions': {'num': 3, 'name': 'Algebraic Expressions', 'bn': 'বীজগাণিতিক রাশি'},
    'indices_logarithms': {'num': 4, 'name': 'Indices and Logarithms', 'bn': 'সূচক ও লগারিদম'},
    'linear_equations': {'num': 5, 'name': 'Linear Equations', 'bn': 'এক চলকবিশিষ্ট সমীকরণ'},
    'trigonometry': {'num': 6, 'name': 'Trigonometry', 'bn': 'ত্রিকোণমিতি'},
    'statistics': {'num': 7, 'name': 'Statistics', 'bn': 'পরিসংখ্যান'},
    'geometry': {'num': 8, 'name': 'Geometry', 'bn': 'জ্যামিতি'}
}

class LightweightPDFManager:
    def __init__(self):
        self.metadata_file = os.path.join(os.path.dirname(__file__), 'data', 'simple_metadata.json')
        self.chapter_metadata = self._load_metadata()
    
    def _load_metadata(self):
        """Load metadata efficiently"""
        try:
            if os.path.exists(self.metadata_file):
                with open(self.metadata_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
        except:
            pass
        return {}
    
    def _save_metadata(self):
        """Save metadata efficiently"""
        try:
            os.makedirs(os.path.dirname(self.metadata_file), exist_ok=True)
            with open(self.metadata_file, 'w', encoding='utf-8') as f:
                json.dump(self.chapter_metadata, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Save error: {e}")
    
    def simple_upload(self, file, class_level, chapter_id):
        """Simplified upload without heavy processing"""
        try:
            # Quick validation
            if chapter_id not in CHAPTERS_SIMPLE:
                return {'success': False, 'error': 'Invalid chapter'}
            
            if class_level not in [9, 10]:
                return {'success': False, 'error': 'Invalid class'}
            
            # Save file quickly
            filename = secure_filename(f"class_{class_level}_{chapter_id}.pdf")
            local_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(local_path)
            
            # Update metadata (minimal)
            chapter_key = f"class_{class_level}"
            if chapter_key not in self.chapter_metadata:
                self.chapter_metadata[chapter_key] = {}
            
            self.chapter_metadata[chapter_key][chapter_id] = {
                'filename': filename,
                'local_path': local_path,
                'upload_date': datetime.now().isoformat(),
                'chapter_info': CHAPTERS_SIMPLE[chapter_id]
            }
            
            self._save_metadata()
            
            # Force garbage collection to free memory
            gc.collect()
            
            return {
                'success': True,
                'message': 'Chapter uploaded successfully',
                'note': 'AI processing will be done when needed'
            }
            
        except Exception as e:
            logger.error(f"Upload error: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_uploaded_chapters(self):
        """Get list of uploaded chapters"""
        uploaded = []
        for class_data in self.chapter_metadata.values():
            uploaded.extend(class_data.keys())
        return uploaded

# Initialize lightweight manager
pdf_manager = LightweightPDFManager()

@app.route('/')
def index():
    """Lightweight UI"""
    return render_template_string("""
<!DOCTYPE html>
<html>
<head>
    <title>📚 Lightweight PDF Manager</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 25px;
            text-align: center;
        }
        .content { padding: 25px; }
        
        .upload-box {
            border: 2px dashed #ddd;
            border-radius: 8px;
            padding: 25px;
            text-align: center;
            margin-bottom: 25px;
            transition: border-color 0.3s;
        }
        .upload-box:hover { border-color: #667eea; }
        
        .form-group {
            margin-bottom: 15px;
            text-align: left;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 600;
        }
        .form-control {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 16px;
        }
        .form-control:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .btn {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 16px;
            width: 100%;
            margin-top: 10px;
        }
        .btn:hover { opacity: 0.9; }
        .btn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        
        .status {
            padding: 12px;
            border-radius: 6px;
            margin-top: 15px;
            display: none;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .stats {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin: 20px 0;
        }
        .stat {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
        }
        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            font-size: 14px;
            color: #666;
        }
        
        .chapters {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 10px;
            margin-top: 20px;
        }
        .chapter {
            padding: 12px;
            border-radius: 6px;
            text-align: center;
            font-size: 14px;
        }
        .chapter.uploaded {
            background: #d4edda;
            color: #155724;
        }
        .chapter.missing {
            background: #f8d7da;
            color: #721c24;
        }
        
        .note {
            background: #e7f3ff;
            border: 1px solid #b3d7ff;
            color: #004085;
            padding: 15px;
            border-radius: 6px;
            margin-top: 20px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📚 Lightweight PDF Manager</h1>
            <p>Fast & Simple Chapter Upload</p>
        </div>
        
        <div class="content">
            <div class="upload-box">
                <h3>📤 Upload Chapter PDF</h3>
                <form id="uploadForm" enctype="multipart/form-data">
                    <div class="form-group">
                        <label>Class Level</label>
                        <select class="form-control" name="class_level" required>
                            <option value="">Select Class</option>
                            <option value="9">Class 9</option>
                            <option value="10">Class 10</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Chapter</label>
                        <select class="form-control" name="chapter_id" required>
                            <option value="">Select Chapter</option>
                            {% for chapter_id, info in chapters.items() %}
                            <option value="{{ chapter_id }}">{{ info.num }}. {{ info.name }}</option>
                            {% endfor %}
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>PDF File</label>
                        <input type="file" class="form-control" name="file" accept=".pdf" required>
                    </div>
                    
                    <button type="submit" class="btn">Upload</button>
                </form>
                
                <div id="status" class="status"></div>
            </div>
            
            <div class="stats" id="stats">
                <!-- Will be populated -->
            </div>
            
            <h3>📊 Chapter Status</h3>
            <div class="chapters" id="chapters">
                <!-- Will be populated -->
            </div>
            
            <div class="note">
                💡 <strong>Note:</strong> This is a lightweight version designed for better performance. 
                AI processing (embeddings) will be done on-demand when searching content.
            </div>
        </div>
    </div>
    
    <script>
        const chapters = {{ chapters | tojson }};
        
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const formData = new FormData(e.target);
            const status = document.getElementById('status');
            const btn = e.target.querySelector('button');
            
            btn.disabled = true;
            btn.textContent = 'Uploading...';
            status.style.display = 'block';
            status.className = 'status';
            status.textContent = 'Processing...';
            
            try {
                const response = await fetch('/upload', {
                    method: 'POST',
                    body: formData
                });
                const result = await response.json();
                
                if (result.success) {
                    status.className = 'status success';
                    status.textContent = result.message;
                    e.target.reset();
                    updateStatus();
                } else {
                    status.className = 'status error';
                    status.textContent = result.error;
                }
            } catch (error) {
                status.className = 'status error';
                status.textContent = 'Upload failed: ' + error.message;
            }
            
            btn.disabled = false;
            btn.textContent = 'Upload';
        });
        
        async function updateStatus() {
            try {
                const response = await fetch('/status');
                const data = await response.json();
                
                // Update stats
                const uploaded = data.uploaded_chapters.length;
                const total = Object.keys(chapters).length;
                document.getElementById('stats').innerHTML = `
                    <div class="stat">
                        <div class="stat-number">${uploaded}</div>
                        <div class="stat-label">Uploaded</div>
                    </div>
                    <div class="stat">
                        <div class="stat-number">${total - uploaded}</div>
                        <div class="stat-label">Remaining</div>
                    </div>
                `;
                
                // Update chapters
                let html = '';
                for (const [id, info] of Object.entries(chapters)) {
                    const uploaded = data.uploaded_chapters.includes(id);
                    const cls = uploaded ? 'uploaded' : 'missing';
                    const icon = uploaded ? '✅' : '⏳';
                    html += `<div class="chapter ${cls}">${icon} ${info.num}. ${info.name}</div>`;
                }
                document.getElementById('chapters').innerHTML = html;
                
            } catch (error) {
                console.error('Status update failed:', error);
            }
        }
        
        updateStatus();
    </script>
</body>
</html>
    """, chapters=CHAPTERS_SIMPLE)

@app.route('/upload', methods=['POST'])
def upload_chapter():
    """Lightweight upload"""
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file provided'})
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No file selected'})
        
        class_level = int(request.form.get('class_level'))
        chapter_id = request.form.get('chapter_id')
        
        result = pdf_manager.simple_upload(file, class_level, chapter_id)
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/status')
def get_status():
    """Get upload status"""
    try:
        uploaded_chapters = pdf_manager.get_uploaded_chapters()
        
        return jsonify({
            'uploaded_chapters': uploaded_chapters,
            'total_chapters': len(CHAPTERS_SIMPLE),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/chapters/<int:class_level>')
def get_chapters(class_level):
    """Get chapters for a class"""
    try:
        chapter_key = f"class_{class_level}"
        chapters = pdf_manager.chapter_metadata.get(chapter_key, {})
        return jsonify({'chapters': chapters})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("⚡ Starting Lightweight PDF Manager")
    print("🔗 Access: http://localhost:5002")
    print("📝 Features:")
    print("  - Fast file uploads")
    print("  - Minimal memory usage")
    print("  - Simple interface")
    print("  - AI processing on-demand")
    
    # Run with minimal resources
    app.run(
        host='127.0.0.1',  # Local only for security
        port=5002,         # Different port
        debug=False,       # No debug
        threaded=False,    # Single thread for simplicity
        use_reloader=False # No auto-reload
    )
