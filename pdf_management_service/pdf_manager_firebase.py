#!/usr/bin/env python3
"""
Firebase-enabled NCTB PDF Book Management Service
Handles upload, organization, and serving of PDF textbooks with Firebase Storage and Firestore
"""

import os
import shutil
import json
import fitz  # PyMuPDF
from flask import Flask, request, jsonify, render_template, send_file, redirect, url_for
from werkzeug.utils import secure_filename
import firebase_admin
from firebase_admin import credentials, storage, firestore
from PIL import Image
import io
import logging
from datetime import datetime
import tempfile
import urllib.parse

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB max file size for large textbooks
app.config['UPLOAD_FOLDER'] = 'data/uploads'
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# NCTB Chapter configuration
NCTB_CHAPTERS = {
    'real_numbers': {'bengali': 'বাস্তব সংখ্যা', 'english': 'Real Numbers', 'number': 1},
    'sets_functions': {'bengali': 'সেট ও ফাংশন', 'english': 'Sets and Functions', 'number': 2},
    'algebraic_expressions': {'bengali': 'বীজগাণিতিক রাশি', 'english': 'Algebraic Expressions', 'number': 3},
    'indices_logarithms': {'bengali': 'সূচক ও লগারিদম', 'english': 'Indices and Logarithms', 'number': 4},
    'linear_equations': {'bengali': 'এক চলকবিশিষ্ট সমীকরণ', 'english': 'Linear Equations in One Variable', 'number': 5},
    'lines_angles_triangles': {'bengali': 'রেখা, কোণ ও ত্রিভুজ', 'english': 'Lines, Angles and Triangles', 'number': 6},
    'practical_geometry': {'bengali': 'ব্যবহারিক জ্যামিতি', 'english': 'Practical Geometry', 'number': 7},
    'circles': {'bengali': 'বৃত্ত', 'english': 'Circles', 'number': 8},
    'trigonometric_ratios': {'bengali': 'ত্রিকোণমিতিক অনুপাত', 'english': 'Trigonometric Ratios', 'number': 9},
    'distance_height': {'bengali': 'দূরত্ব ও উচ্চতা', 'english': 'Distance and Height', 'number': 10},
    'algebraic_ratios': {'bengali': 'বীজগাণিতিক অনুপাত ও সমানুপাত', 'english': 'Algebraic Ratios and Proportions', 'number': 11},
    'simultaneous_equations': {'bengali': 'দুই চলকবিশিষ্ট সরল সহসমীকরণ', 'english': 'Simultaneous Linear Equations', 'number': 12},
    'finite_series': {'bengali': 'সসীম ধারা', 'english': 'Finite Series', 'number': 13},
    'ratio_similarity_symmetry': {'bengali': 'অনুপাত, সদৃশতা ও প্রতিসমতা', 'english': 'Ratio, Similarity and Symmetry', 'number': 14},
    'area_theorems': {'bengali': 'ক্ষেত্রফল সম্পর্কিত উপপাদ্য ও সম্পাদ্য', 'english': 'Area Related Theorems', 'number': 15},
    'mensuration': {'bengali': 'পরিমিতি', 'english': 'Mensuration', 'number': 16},
    'statistics': {'bengali': 'পরিসংখ্যান', 'english': 'Statistics', 'number': 17}
}

# Initialize Firebase
FIREBASE_ENABLED = False
STORAGE_BUCKET = None
DB = None

try:
    config_path = 'config/firebase_config.json'
    if os.path.exists(config_path):
        # Load service account to detect project_id
        with open(config_path, 'r', encoding='utf-8') as f:
            sa_data = json.load(f)
        project_id = sa_data.get('project_id')
        # Allow override via env var
        bucket_env = os.getenv('FIREBASE_STORAGE_BUCKET')
        bucket_name = bucket_env or (f"{project_id}.firebasestorage.app" if project_id else None)
        if not bucket_name:
            raise RuntimeError("Cannot determine Firebase Storage bucket. Set FIREBASE_STORAGE_BUCKET env or ensure project_id is present in service account JSON.")

        cred = credentials.Certificate(config_path)
        firebase_admin.initialize_app(cred, {
            'storageBucket': bucket_name
        })
        FIREBASE_ENABLED = True
        STORAGE_BUCKET = storage.bucket()
        DB = firestore.client()
        logger.info(f"Firebase initialized successfully (bucket: {bucket_name})")
    else:
        logger.warning("Firebase config not found at 'config/firebase_config.json'")
        logger.warning("Please add your Firebase service account key to enable cloud features")
except Exception as e:
    logger.error(f"Firebase initialization failed: {e}")
    logger.warning("Running in local-only mode")

class FirebasePDFManager:
    def __init__(self):
        self.firebase_enabled = FIREBASE_ENABLED
        self.storage_bucket = STORAGE_BUCKET
        self.db = DB
        self.chapter_ranges = {}
        self.load_chapter_ranges()
    
    def load_chapter_ranges(self):
        """Load chapter page ranges from Firestore or local backup"""
        if self.firebase_enabled and self.db:
            try:
                # Load from Firestore
                docs = self.db.collection('nctb_chapters').stream()
                ranges = {}
                for doc in docs:
                    data = doc.to_dict()
                    ranges[doc.id] = data.get('chapters', {})
                
                if ranges:
                    self.chapter_ranges = ranges
                    logger.info("Chapter ranges loaded from Firestore")
                    return
            except Exception as e:
                logger.error(f"Error loading from Firestore: {e}")
        
        # Fallback to local file
        local_file = 'data/chapter_ranges.json'
        try:
            if os.path.exists(local_file):
                with open(local_file, 'r', encoding='utf-8') as f:
                    self.chapter_ranges = json.load(f)
                logger.info("Chapter ranges loaded from local file")
            else:
                self.chapter_ranges = {'class_9': {}, 'class_10': {}}
                logger.info("Initialized empty chapter ranges")
        except Exception as e:
            logger.error(f"Error loading local chapter ranges: {e}")
            self.chapter_ranges = {'class_9': {}, 'class_10': {}}
    
    def save_chapter_ranges(self):
        """Save chapter page ranges to Firestore and local backup"""
        # Save to Firestore if enabled
        if self.firebase_enabled and self.db:
            try:
                for class_key, ranges in self.chapter_ranges.items():
                    doc_ref = self.db.collection('nctb_chapters').document(class_key)
                    doc_ref.set({
                        'chapters': ranges,
                        'updated_at': datetime.now(),
                        'class_level': class_key.replace('class_', '')
                    })
                logger.info("Chapter ranges saved to Firestore")
            except Exception as e:
                logger.error(f"Error saving to Firestore: {e}")
        
        # Always save local backup
        try:
            local_file = 'data/chapter_ranges.json'
            os.makedirs(os.path.dirname(local_file), exist_ok=True)
            with open(local_file, 'w', encoding='utf-8') as f:
                json.dump(self.chapter_ranges, f, indent=2, ensure_ascii=False)
            logger.info("Chapter ranges saved to local backup")
        except Exception as e:
            logger.error(f"Error saving local backup: {e}")
    
    def upload_pdf(self, file, class_level):
        """Upload PDF to Firebase Storage and process"""
        try:
            filename = secure_filename(f"nctb_class_{class_level}_math.pdf")
            
            # Save temporarily for processing
            with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
                file.save(temp_file.name)
                temp_filepath = temp_file.name
            
            # Analyze PDF
            doc = fitz.open(temp_filepath)
            total_pages = doc.page_count
            doc.close()
            
            # Upload to Firebase Storage if enabled
            download_url = None
            if self.firebase_enabled and self.storage_bucket:
                try:
                    blob = self.storage_bucket.blob(f"textbooks/{filename}")
                    blob.upload_from_filename(temp_filepath)
                    blob.make_public()
                    download_url = blob.public_url
                    logger.info(f"PDF uploaded to Firebase Storage: {filename}")
                    
                    # Save metadata to Firestore
                    self.db.collection('nctb_pdfs').document(f'class_{class_level}').set({
                        'filename': filename,
                        'total_pages': total_pages,
                        'download_url': download_url,
                        'uploaded_at': datetime.now(),
                        'class_level': class_level,
                        'file_size': os.path.getsize(temp_filepath)
                    })
                    
                except Exception as e:
                    logger.error(f"Firebase upload failed: {e}")
                    # Fall back to local storage
                    local_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                    os.makedirs(os.path.dirname(local_path), exist_ok=True)
                    # Use shutil.move for cross-drive compatibility on Windows
                    shutil.move(temp_filepath, local_path)
                    temp_filepath = local_path
            else:
                # Local storage fallback
                local_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                os.makedirs(os.path.dirname(local_path), exist_ok=True)
                # Use shutil.move for cross-drive compatibility on Windows
                shutil.move(temp_filepath, local_path)
            
            # Clean up temp file only if still in temp directory and exists
            try:
                if temp_filepath and os.path.exists(temp_filepath):
                    temp_dir = os.path.abspath(tempfile.gettempdir())
                    if os.path.abspath(temp_filepath).startswith(temp_dir):
                        os.unlink(temp_filepath)
            except Exception as cleanup_err:
                logger.warning(f"Temp cleanup skipped: {cleanup_err}")
            
            logger.info(f"PDF processed: {filename}, Pages: {total_pages}")
            
            return {
                'success': True,
                'filename': filename,
                'total_pages': total_pages,
                'download_url': download_url,
                'message': f'PDF uploaded successfully. Total pages: {total_pages}'
            }
        
        except Exception as e:
            logger.error(f"Error uploading PDF: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_pdf_source(self, class_level):
        """Get PDF source (Firebase URL or local path)"""
        filename = f"nctb_class_{class_level}_math.pdf"
        
        # Try Firebase first
        if self.firebase_enabled and self.db:
            try:
                doc = self.db.collection('nctb_pdfs').document(f'class_{class_level}').get()
                if doc.exists:
                    data = doc.to_dict()
                    download_url = data.get('download_url')
                    if download_url:
                        return download_url, 'firebase'
            except Exception as e:
                logger.error(f"Error getting Firebase PDF: {e}")
        
        # Fallback to local
        local_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        if os.path.exists(local_path):
            return local_path, 'local'
        
        return None, None
    
    def download_pdf_from_firebase(self, class_level):
        """Download PDF from Firebase to local cache"""
        if not self.firebase_enabled:
            return None
        
        try:
            filename = f"nctb_class_{class_level}_math.pdf"
            blob = self.storage_bucket.blob(f"textbooks/{filename}")
            
            # Download to local cache
            local_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            os.makedirs(os.path.dirname(local_path), exist_ok=True)
            blob.download_to_filename(local_path)
            
            logger.info(f"PDF downloaded from Firebase: {filename}")
            return local_path
        except Exception as e:
            logger.error(f"Error downloading from Firebase: {e}")
            return None
    
    def configure_chapters(self, class_level, chapter_ranges):
        """Configure page ranges for chapters"""
        try:
            class_key = f"class_{class_level}"
            self.chapter_ranges[class_key] = chapter_ranges
            self.save_chapter_ranges()
            
            logger.info(f"Chapter ranges configured for {class_key}")
            return {'success': True, 'message': 'Chapter ranges configured successfully'}
        
        except Exception as e:
            logger.error(f"Error configuring chapters: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_chapter_pdf(self, class_level, chapter_id, format='pdf'):
        """Extract specific chapter pages from PDF"""
        try:
            class_key = f"class_{class_level}"
            
            if class_key not in self.chapter_ranges or chapter_id not in self.chapter_ranges[class_key]:
                return None
            
            chapter_range = self.chapter_ranges[class_key][chapter_id]
            start_page = chapter_range['start'] - 1  # Convert to 0-based index
            end_page = chapter_range['end'] - 1
            
            # Get PDF source
            pdf_source, source_type = self.get_pdf_source(class_level)
            if not pdf_source:
                return None
            
            # Download from Firebase if needed
            if source_type == 'firebase':
                local_path = self.download_pdf_from_firebase(class_level)
                if not local_path:
                    return None
                pdf_source = local_path
            
            doc = fitz.open(pdf_source)
            
            if format == 'pdf':
                # Create new PDF with only chapter pages
                new_doc = fitz.open()
                for page_num in range(start_page, min(end_page + 1, doc.page_count)):
                    new_doc.insert_pdf(doc, from_page=page_num, to_page=page_num)
                
                # Save chapter PDF
                output_path = os.path.join(app.config['UPLOAD_FOLDER'], f"chapter_{class_level}_{chapter_id}.pdf")
                os.makedirs(os.path.dirname(output_path), exist_ok=True)
                new_doc.save(output_path)
                new_doc.close()
                doc.close()
                
                return output_path
            
            elif format == 'images':
                # Convert pages to images
                images = []
                for page_num in range(start_page, min(end_page + 1, doc.page_count)):
                    page = doc[page_num]
                    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))  # 2x zoom for better quality
                    img_data = pix.tobytes("png")
                    images.append(img_data)
                
                doc.close()
                return images
            
            doc.close()
            return None
        
        except Exception as e:
            logger.error(f"Error extracting chapter PDF: {e}")
            return None
    
    def extract_text(self, class_level, chapter_id, page_num=None):
        """Extract text from specific page or entire chapter"""
        try:
            class_key = f"class_{class_level}"
            
            if class_key not in self.chapter_ranges or chapter_id not in self.chapter_ranges[class_key]:
                return None
            
            chapter_range = self.chapter_ranges[class_key][chapter_id]
            start_page = chapter_range['start'] - 1
            end_page = chapter_range['end'] - 1
            
            # Get PDF source
            pdf_source, source_type = self.get_pdf_source(class_level)
            if not pdf_source:
                return None
            
            # Download from Firebase if needed
            if source_type == 'firebase':
                local_path = self.download_pdf_from_firebase(class_level)
                if not local_path:
                    return None
                pdf_source = local_path
            
            doc = fitz.open(pdf_source)
            
            if page_num is not None:
                # Extract text from specific page
                actual_page = start_page + page_num - 1
                if actual_page <= end_page and actual_page < doc.page_count:
                    page = doc[actual_page]
                    text = page.get_text()
                    doc.close()
                    return text
            else:
                # Extract text from entire chapter
                text = ""
                for page_num in range(start_page, min(end_page + 1, doc.page_count)):
                    page = doc[page_num]
                    text += page.get_text() + "\n"
                
                doc.close()
                return text
            
            doc.close()
            return None
        
        except Exception as e:
            logger.error(f"Error extracting text: {e}")
            return None

# Initialize Firebase PDF Manager
pdf_manager = FirebasePDFManager()

@app.route('/')
def index():
    """Main interface"""
    firebase_status = "✅ Connected" if FIREBASE_ENABLED else "❌ Not configured"
    return render_template('upload.html', 
                         chapters=NCTB_CHAPTERS,
                         firebase_status=firebase_status)

@app.route('/upload', methods=['POST'])
def upload_pdf():
    """Handle PDF upload"""
    if 'file' not in request.files:
        return jsonify({'success': False, 'error': 'No file selected'})
    
    file = request.files['file']
    class_level = request.form.get('class_level')
    
    if file.filename == '':
        return jsonify({'success': False, 'error': 'No file selected'})
    
    if not class_level or class_level not in ['9', '10']:
        return jsonify({'success': False, 'error': 'Invalid class level'})
    
    if file and file.filename.lower().endswith('.pdf'):
        result = pdf_manager.upload_pdf(file, class_level)
        return jsonify(result)
    
    return jsonify({'success': False, 'error': 'Please upload a PDF file'})

@app.route('/configure', methods=['GET', 'POST'])
def configure_chapters():
    """Configure chapter page ranges"""
    if request.method == 'GET':
        firebase_status = "✅ Connected" if FIREBASE_ENABLED else "❌ Not configured"
        return render_template('configure.html', 
                             chapters=NCTB_CHAPTERS,
                             current_ranges=pdf_manager.chapter_ranges,
                             firebase_status=firebase_status)
    
    elif request.method == 'POST':
        try:
            data = request.get_json()
            class_level = data.get('class_level')
            chapter_ranges = data.get('chapter_ranges')
            
            if not class_level or not chapter_ranges:
                return jsonify({'success': False, 'error': 'Missing required data'})
            
            result = pdf_manager.configure_chapters(class_level, chapter_ranges)
            return jsonify(result)
        
        except Exception as e:
            return jsonify({'success': False, 'error': str(e)})

@app.route('/pdf/<class_level>/<chapter_id>')
def get_chapter_pdf(class_level, chapter_id):
    """Serve chapter PDF"""
    try:
        pdf_path = pdf_manager.get_chapter_pdf(class_level, chapter_id)
        if pdf_path and os.path.exists(pdf_path):
            return send_file(pdf_path, as_attachment=False, mimetype='application/pdf')
        else:
            return jsonify({'error': 'Chapter PDF not found'}), 404
    
    except Exception as e:
        logger.error(f"Error serving PDF: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/images/<class_level>/<chapter_id>')
def get_chapter_images(class_level, chapter_id):
    """Get chapter pages as images"""
    try:
        images = pdf_manager.get_chapter_pdf(class_level, chapter_id, format='images')
        if images:
            # Return first image for now, extend to handle multiple images
            return send_file(io.BytesIO(images[0]), mimetype='image/png')
        else:
            return jsonify({'error': 'Chapter images not found'}), 404
    
    except Exception as e:
        logger.error(f"Error serving images: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/text/<class_level>/<chapter_id>')
@app.route('/text/<class_level>/<chapter_id>/<int:page_num>')
def get_chapter_text(class_level, chapter_id, page_num=None):
    """Extract text from chapter or specific page"""
    try:
        text = pdf_manager.extract_text(class_level, chapter_id, page_num)
        if text:
            return jsonify({'text': text})
        else:
            return jsonify({'error': 'Text not found'}), 404
    
    except Exception as e:
        logger.error(f"Error extracting text: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/chapters/<class_level>')
def get_chapters(class_level):
    """Get configured chapters for a class"""
    try:
        class_key = f"class_{class_level}"
        if class_key in pdf_manager.chapter_ranges:
            chapters = pdf_manager.chapter_ranges[class_key]
            # Add chapter metadata
            for chapter_id, range_data in chapters.items():
                if chapter_id in NCTB_CHAPTERS:
                    range_data.update(NCTB_CHAPTERS[chapter_id])
            
            return jsonify({'chapters': chapters})
        else:
            return jsonify({'chapters': {}})
    
    except Exception as e:
        logger.error(f"Error getting chapters: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/status')
def status():
    """Service status"""
    return jsonify({
        'status': 'running',
        'firebase_enabled': FIREBASE_ENABLED,
        'storage_available': STORAGE_BUCKET is not None,
        'firestore_available': DB is not None,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/firebase_status')
def firebase_status():
    """Detailed Firebase status"""
    info = {
        'firebase_available': FIREBASE_ENABLED,
        'storage_bucket': None,
        'firestore': None,
    }
    try:
        if FIREBASE_ENABLED and STORAGE_BUCKET is not None:
            info['storage_bucket'] = {
                'name': STORAGE_BUCKET.name,
            }
        if FIREBASE_ENABLED and DB is not None:
            # Light probe: list collections names
            collections = [c.id for c in DB.collections()]
            info['firestore'] = {
                'collections': collections,
            }
    except Exception as e:
        info['error'] = str(e)
    return jsonify(info)

@app.route('/firebase-setup')
def firebase_setup():
    """Firebase setup guide"""
    return render_template('firebase_setup.html')

if __name__ == '__main__':
    # Ensure upload directory exists
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    
    # Show startup info
    if FIREBASE_ENABLED:
        logger.info("🔥 Firebase enabled - using cloud storage and database")
    else:
        logger.info("📁 Local mode - add Firebase config to enable cloud features")
    
    # Run the application
    app.run(debug=True, host='0.0.0.0', port=5000)
