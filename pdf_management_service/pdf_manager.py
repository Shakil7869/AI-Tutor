#!/usr/bin/env python3
"""
NCTB PDF Book Management Service
Handles upload, organization, and serving of PDF textbooks with chapter page ranges
"""

import os
import json
import fitz  # PyMuPDF
from flask import Flask, request, jsonify, render_template, send_file
from werkzeug.utils import secure_filename
import firebase_admin
from firebase_admin import credentials, storage
from PIL import Image
import io
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB max file size for large textbooks
app.config['UPLOAD_FOLDER'] = 'data/uploads'

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

# Initialize Firebase (optional - for cloud storage)
try:
    if os.path.exists('config/firebase_config.json'):
        cred = credentials.Certificate('config/firebase_config.json')
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'your-project-id.appspot.com'  # Replace with your bucket
        })
        FIREBASE_ENABLED = True
        logger.info("Firebase initialized successfully")
    else:
        FIREBASE_ENABLED = False
        logger.warning("Firebase config not found, using local storage only")
except Exception as e:
    FIREBASE_ENABLED = False
    logger.warning(f"Firebase initialization failed: {e}")

class PDFManager:
    def __init__(self):
        self.chapter_ranges_file = 'data/chapter_ranges.json'
        self.load_chapter_ranges()
    
    def load_chapter_ranges(self):
        """Load chapter page ranges from file"""
        try:
            if os.path.exists(self.chapter_ranges_file):
                with open(self.chapter_ranges_file, 'r', encoding='utf-8') as f:
                    self.chapter_ranges = json.load(f)
            else:
                self.chapter_ranges = {'class_9': {}, 'class_10': {}}
                self.save_chapter_ranges()
        except Exception as e:
            logger.error(f"Error loading chapter ranges: {e}")
            self.chapter_ranges = {'class_9': {}, 'class_10': {}}
    
    def save_chapter_ranges(self):
        """Save chapter page ranges to file"""
        try:
            with open(self.chapter_ranges_file, 'w', encoding='utf-8') as f:
                json.dump(self.chapter_ranges, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Error saving chapter ranges: {e}")
    
    def upload_pdf(self, file, class_level):
        """Upload and process PDF file"""
        try:
            filename = secure_filename(f"nctb_class_{class_level}_math.pdf")
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            
            # Save uploaded file
            file.save(filepath)
            
            # Analyze PDF
            doc = fitz.open(filepath)
            total_pages = doc.page_count
            doc.close()
            
            logger.info(f"PDF uploaded: {filename}, Pages: {total_pages}")
            
            # Upload to Firebase if enabled
            if FIREBASE_ENABLED:
                self.upload_to_firebase(filepath, filename)
            
            return {
                'success': True,
                'filename': filename,
                'total_pages': total_pages,
                'message': f'PDF uploaded successfully. Total pages: {total_pages}'
            }
        
        except Exception as e:
            logger.error(f"Error uploading PDF: {e}")
            return {'success': False, 'error': str(e)}
    
    def upload_to_firebase(self, filepath, filename):
        """Upload PDF to Firebase Storage"""
        try:
            bucket = storage.bucket()
            blob = bucket.blob(f"textbooks/{filename}")
            blob.upload_from_filename(filepath)
            logger.info(f"PDF uploaded to Firebase: {filename}")
        except Exception as e:
            logger.error(f"Firebase upload failed: {e}")
    
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
            
            # Open source PDF
            source_pdf = os.path.join(app.config['UPLOAD_FOLDER'], f"nctb_class_{class_level}_math.pdf")
            if not os.path.exists(source_pdf):
                return None
            
            doc = fitz.open(source_pdf)
            
            if format == 'pdf':
                # Create new PDF with only chapter pages
                new_doc = fitz.open()
                for page_num in range(start_page, min(end_page + 1, doc.page_count)):
                    new_doc.insert_pdf(doc, from_page=page_num, to_page=page_num)
                
                # Save chapter PDF
                output_path = os.path.join(app.config['UPLOAD_FOLDER'], f"chapter_{class_level}_{chapter_id}.pdf")
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
            
            source_pdf = os.path.join(app.config['UPLOAD_FOLDER'], f"nctb_class_{class_level}_math.pdf")
            if not os.path.exists(source_pdf):
                return None
            
            doc = fitz.open(source_pdf)
            
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

# Initialize PDF Manager
pdf_manager = PDFManager()

@app.route('/')
def index():
    """Main interface"""
    return render_template('upload.html', chapters=NCTB_CHAPTERS)

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
        return render_template('configure.html', 
                             chapters=NCTB_CHAPTERS,
                             current_ranges=pdf_manager.chapter_ranges)
    
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
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    # Ensure upload directory exists
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    
    # Run the application
    app.run(debug=True, host='0.0.0.0', port=5000)
