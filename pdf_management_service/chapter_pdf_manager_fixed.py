#!/usr/bin/env python3
"""
Chapter-wise PDF Management Service with Firebase Storage & Firestore Integration
Handles individual chapter PDF uploads, stores in Firebase Storage, and saves URLs in Firestore
"""

import os
import sys
import json
import logging
import tempfile
import shutil
import requests
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, render_template_string, send_file
from werkzeug.utils import secure_filename
import fitz  # PyMuPDF
from pinecone import Pinecone, ServerlessSpec
import openai
from pathlib import Path
import hashlib
import uuid
from urllib.parse import quote as url_quote

# Firebase imports
try:
    import firebase_admin
    from firebase_admin import credentials, storage, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    print("⚠️ Firebase not available - install firebase-admin")

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flask app setup
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB max file size
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'data', 'chapters')

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# NCTB Chapter definitions - matching Flutter nctb_curriculum.dart
NCTB_CHAPTERS = {
    # Class 9 chapters
    'real_numbers': {
        'id': 'real_numbers',
        'name': 'বাস্তব সংখ্যা',
        'englishName': 'Real Numbers',
        'chapterNumber': '১ম অধ্যায়',
        'chapter_number': 1
    },
    'sets_functions': {
        'id': 'sets_functions',
        'name': 'সেট ও ফাংশন',
        'englishName': 'Sets and Functions',
        'chapterNumber': '২য় অধ্যায়',
        'chapter_number': 2
    },
    'algebraic_expressions': {
        'id': 'algebraic_expressions',
        'name': 'বীজগাণিতিক রাশি',
        'englishName': 'Algebraic Expressions',
        'chapterNumber': '৩য় অধ্যায়',
        'chapter_number': 3
    },
    'indices_logarithms': {
        'id': 'indices_logarithms',
        'name': 'সূচক ও লগারিদম',
        'englishName': 'Indices and Logarithms',
        'chapterNumber': '৪র্থ অধ্যায়',
        'chapter_number': 4
    },
    'linear_equations': {
        'id': 'linear_equations',
        'name': 'এক চলকবিশিষ্ট সমীকরণ',
        'englishName': 'Linear Equations in One Variable',
        'chapterNumber': '৫ম অধ্যায়',
        'chapter_number': 5
    },
    'lines_angles_triangles': {
        'id': 'lines_angles_triangles',
        'name': 'রেখা, কোণ ও ত্রিভুজ',
        'englishName': 'Lines, Angles and Triangles',
        'chapterNumber': '৬ষ্ঠ অধ্যায়',
        'chapter_number': 6
    },
    'practical_geometry': {
        'id': 'practical_geometry',
        'name': 'ব্যবহারিক জ্যামিতি',
        'englishName': 'Practical Geometry',
        'chapterNumber': '৭ম অধ্যায়',
        'chapter_number': 7
    },
    'circles': {
        'id': 'circles',
        'name': 'বৃত্ত',
        'englishName': 'Circles',
        'chapterNumber': '৮ম অধ্যায়',
        'chapter_number': 8
    },
    'trigonometric_ratios': {
        'id': 'trigonometric_ratios',
        'name': 'ত্রিকোণমিতিক অনুপাত',
        'englishName': 'Trigonometric Ratios',
        'chapterNumber': '৯ম অধ্যায়',
        'chapter_number': 9
    },
    'distance_height': {
        'id': 'distance_height',
        'name': 'দূরত্ব ও উচ্চতা',
        'englishName': 'Distance and Height',
        'chapterNumber': '১০ম অধ্যায়',
        'chapter_number': 10
    },
    'algebraic_ratios': {
        'id': 'algebraic_ratios',
        'name': 'বীজগাণিতিক অনুপাত ও সমানুপাত',
        'englishName': 'Algebraic Ratios and Proportions',
        'chapterNumber': '১১শ অধ্যায়',
        'chapter_number': 11
    },
    'simultaneous_equations': {
        'id': 'simultaneous_equations',
        'name': 'দুই চলকবিশিষ্ট সরল সহসমীকরণ',
        'englishName': 'Simultaneous Linear Equations in Two Variables',
        'chapterNumber': '১২শ অধ্যায়',
        'chapter_number': 12
    },
    'finite_series': {
        'id': 'finite_series',
        'name': 'সসীম ধারা',
        'englishName': 'Finite Series',
        'chapterNumber': '১৩শ অধ্যায়',
        'chapter_number': 13
    },
    'ratio_similarity_symmetry': {
        'id': 'ratio_similarity_symmetry',
        'name': 'অনুপাত, সদৃশতা ও প্রতিসমতা',
        'englishName': 'Ratio, Similarity and Symmetry',
        'chapterNumber': '১৪শ অধ্যায়',
        'chapter_number': 14
    },
    'area_theorems': {
        'id': 'area_theorems',
        'name': 'ক্ষেত্রফল সম্পর্কিত উপপাদ্য ও সম্পাদ্য',
        'englishName': 'Area Related Theorems and Constructions',
        'chapterNumber': '১৫শ অধ্যায়',
        'chapter_number': 15
    },
    'mensuration': {
        'id': 'mensuration',
        'name': 'পরিমিতি',
        'englishName': 'Mensuration',
        'chapterNumber': '১৬শ অধ্যায়',
        'chapter_number': 16
    },
    'statistics': {
        'id': 'statistics',
        'name': 'পরিসংখ্যান',
        'englishName': 'Statistics',
        'chapterNumber': '১৭শ অধ্যায়',
        'chapter_number': 17
    }
}

# Helper functions for chapter management
def get_chapters_for_class(class_level):
    """Get chapters available for a specific class level"""
    if class_level == 9:
        return {k: v for k, v in NCTB_CHAPTERS.items() if not 'advanced' in k}
    elif class_level == 10:
        return NCTB_CHAPTERS  # Class 10 can access all chapters
    else:
        return {}

def is_valid_chapter_for_class(chapter_id, class_level):
    """Check if a chapter is valid for the given class level"""
    valid_chapters = get_chapters_for_class(class_level)
    return chapter_id in valid_chapters

class ChapterPDFManager:
    def __init__(self):
        self.firebase_initialized = False
        self.storage_bucket = None
        self.db = None
        self.pinecone_client = None
        self.openai_client = None
        
        # Initialize services
        self._initialize_firebase()
        self._initialize_pinecone()
        self._initialize_openai()
        
        # Load existing metadata
        self.metadata_file = os.path.join(os.path.dirname(__file__), 'data', 'chapter_metadata.json')
        self.chapter_metadata = self._load_metadata()
    
    def _initialize_firebase(self):
        """Initialize Firebase services"""
        if not FIREBASE_AVAILABLE:
            logger.warning("⚠️ Firebase SDK not available - install firebase-admin")
            return
            
        try:
            config_path = os.path.join(os.path.dirname(__file__), 'config', 'firebase_config.json')
            if os.path.exists(config_path):
                if not firebase_admin._apps:
                    cred = credentials.Certificate(config_path)
                    firebase_admin.initialize_app(cred, {
                        'storageBucket': 'ai-tutor-oshan.firebasestorage.app'  # Correct bucket name
                    })
                
                self.storage_bucket = storage.bucket()
                self.db = firestore.client()
                self.firebase_initialized = True
                logger.info("🔥 Firebase initialized successfully")
            else:
                logger.warning("⚠️ Firebase config not found, continuing in local mode")
        except Exception as e:
            logger.error(f"Firebase initialization failed: {e}")

    def _generate_signed_put_url(self, firebase_path: str, content_type: str = 'application/pdf', expires_minutes: int = 30):
        """Generate a V4 signed URL for uploading via HTTP PUT"""
        try:
            if not self.firebase_initialized or not self.storage_bucket:
                logger.warning("Firebase not initialized; cannot generate signed URL")
                return None, None, None

            blob = self.storage_bucket.blob(firebase_path)

            headers = {'Content-Type': content_type}
            # Add Firebase download token metadata
            download_token = str(uuid.uuid4())
            headers['x-goog-meta-firebaseStorageDownloadTokens'] = download_token

            url = blob.generate_signed_url(
                version='v4',
                expiration=timedelta(minutes=expires_minutes),
                method='PUT',
                content_type=content_type,
                headers=headers
            )
            return url, headers, download_token
        except Exception as e:
            logger.warning(f"Failed to generate signed PUT URL: {e}")
            return None, None, None

    def _upload_file_via_signed_url(self, local_path: str, firebase_path: str):
        """Upload a file to Firebase Storage using signed URL"""
        try:
            url, headers, download_token = self._generate_signed_put_url(firebase_path)
            if not url:
                return False, None

            logger.info(f"⬆️ Uploading via signed URL to {firebase_path}")
            
            # Upload using requests
            with open(local_path, 'rb') as f:
                response = requests.put(url, data=f, headers=headers)
            
            if response.status_code in [200, 201]:
                # Build Firebase download URL
                path_escaped = url_quote(firebase_path, safe='')
                public_url = (
                    f"https://firebasestorage.googleapis.com/v0/b/{self.storage_bucket.name}/o/{path_escaped}?alt=media&token={download_token}"
                )
                logger.info(f"✅ Signed URL upload succeeded")
                return True, public_url
            else:
                logger.warning(f"Signed URL upload failed with status {response.status_code}")
                return False, None
                
        except Exception as e:
            logger.warning(f"Signed URL upload exception: {e}")
            return False, None
    
    def _initialize_pinecone(self):
        """Initialize Pinecone for vector storage"""
        try:
            api_key = os.getenv('PINECONE_API_KEY') or "pcsk_4MsQRi_7RTxjoGyVVALKNizgavCabr3UGYJZPj4cLibVmn1HKdQD8zqRS9RCaVJZqWbKoF"
            if not api_key:
                logger.error("❌ PINECONE_API_KEY not set")
                return
            
            self.pinecone_client = Pinecone(api_key=api_key)
            
            # Create or connect to index
            index_name = "nctb-math-chapters"
            if index_name not in self.pinecone_client.list_indexes().names():
                self.pinecone_client.create_index(
                    name=index_name,
                    dimension=1536,
                    metric="cosine",
                    spec=ServerlessSpec(cloud="aws", region="us-east-1")
                )
                logger.info(f"📊 Created Pinecone index: {index_name}")
            
            self.index = self.pinecone_client.Index(index_name)
            logger.info("📊 Pinecone initialized successfully")
            
        except Exception as e:
            logger.error(f"Pinecone initialization failed: {e}")
    
    def _initialize_openai(self):
        """Initialize OpenAI for embeddings"""
        try:
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                logger.error("❌ OPENAI_API_KEY not set")
                return
            
            openai.api_key = api_key
            self.openai_client = True
            logger.info("🤖 OpenAI initialized successfully")
            
        except Exception as e:
            logger.error(f"OpenAI initialization failed: {e}")
    
    def _load_metadata(self):
        """Load existing chapter metadata"""
        try:
            if os.path.exists(self.metadata_file):
                with open(self.metadata_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
        except Exception as e:
            logger.error(f"Error loading metadata: {e}")
        return {}
    
    def _save_metadata(self):
        """Save chapter metadata to file"""
        try:
            os.makedirs(os.path.dirname(self.metadata_file), exist_ok=True)
            with open(self.metadata_file, 'w', encoding='utf-8') as f:
                json.dump(self.chapter_metadata, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Error saving metadata: {e}")
    
    def extract_text_chunks(self, pdf_path, chunk_size=800, overlap=50):
        """Extract text from PDF and split into chunks"""
        try:
            doc = fitz.open(pdf_path)
            full_text = ""
            
            # Limit pages for performance
            max_pages = min(50, doc.page_count)
            
            for page_num in range(max_pages):
                page = doc[page_num]
                text = page.get_text()
                full_text += text + "\n\n"
            
            doc.close()
            
            if not full_text.strip():
                logger.warning("No text extracted from PDF")
                return []
            
            # Split into chunks
            words = full_text.split()
            chunks = []
            current_chunk = []
            current_size = 0
            
            for word in words:
                current_chunk.append(word)
                current_size += len(word) + 1
                
                if current_size >= chunk_size:
                    chunks.append(' '.join(current_chunk))
                    # Overlap
                    overlap_words = current_chunk[-overlap:] if len(current_chunk) > overlap else current_chunk
                    current_chunk = overlap_words
                    current_size = sum(len(w) + 1 for w in current_chunk)
            
            # Add remaining chunk
            if current_chunk:
                chunks.append(' '.join(current_chunk))
            
            # Limit chunks for performance
            max_chunks = 50
            if len(chunks) > max_chunks:
                chunks = chunks[:max_chunks]
                logger.info(f"⚡ Limited to {max_chunks} chunks for performance")
            
            logger.info(f"📄 Extracted {len(chunks)} text chunks from {max_pages} pages")
            return chunks
            
        except Exception as e:
            logger.error(f"Error extracting text: {e}")
            return []
    
    def create_embeddings(self, text_chunks, class_level, chapter_id):
        """Create embeddings for text chunks and store in Pinecone"""
        if not self.openai_client or not self.pinecone_client:
            logger.warning("OpenAI or Pinecone not initialized")
            return False
        
        try:
            vectors = []
            
            for i, chunk in enumerate(text_chunks):
                # Create embedding
                response = openai.Embedding.create(
                    input=chunk,
                    model="text-embedding-ada-002"
                )
                embedding = response['data'][0]['embedding']
                
                # Create vector ID
                vector_id = f"class_{class_level}_{chapter_id}_chunk_{i}"
                
                vectors.append({
                    'id': vector_id,
                    'values': embedding,
                    'metadata': {
                        'class_level': class_level,
                        'chapter_id': chapter_id,
                        'chunk_index': i,
                        'text': chunk[:1000],  # Store first 1000 chars
                        'chapter_name': NCTB_CHAPTERS[chapter_id]['name'],
                        'english_name': NCTB_CHAPTERS[chapter_id]['englishName']
                    }
                })
            
            # Batch upsert to Pinecone
            self.index.upsert(vectors=vectors)
            logger.info(f"🧠 Created {len(vectors)} embeddings for {chapter_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error creating embeddings: {e}")
            return False
    
    def calculate_file_hash(self, file_path):
        """Calculate SHA256 hash of file"""
        try:
            hash_sha256 = hashlib.sha256()
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()
        except Exception as e:
            logger.error(f"Error calculating hash: {e}")
            return None

    def upload_chapter_pdf(self, file, class_level, chapter_id, force_reupload=False):
        """Upload and process a chapter PDF with Firebase Storage integration"""
        try:
            # Validate inputs
            if not is_valid_chapter_for_class(chapter_id, class_level):
                valid_chapters = list(get_chapters_for_class(class_level).keys())
                return {
                    'success': False, 
                    'error': f'Invalid chapter ID: {chapter_id} for Class {class_level}',
                    'valid_chapters': valid_chapters
                }
            
            if class_level not in [9, 10]:
                return {'success': False, 'error': f'Invalid class level: {class_level}. Supported: 9, 10'}
            
            # Save file temporarily
            filename = secure_filename(f"class_{class_level}_{chapter_id}.pdf")
            temp_path = os.path.join(tempfile.gettempdir(), f"temp_{filename}")
            file.save(temp_path)
            
            # Calculate file hash for duplicate detection
            file_hash = self.calculate_file_hash(temp_path)
            if not file_hash:
                os.remove(temp_path)
                return {'success': False, 'error': 'Failed to calculate file hash'}
            
            # Check for duplicates
            chapter_key = f"class_{class_level}"
            existing_metadata = self.chapter_metadata.get(chapter_key, {}).get(chapter_id, {})
            existing_hash = existing_metadata.get('file_hash')
            existing_firebase_url = existing_metadata.get('firebase_url')
            
            # Only skip if identical file AND Firebase upload was successful AND not forcing reupload
            if (existing_hash == file_hash and 
                not force_reupload and 
                existing_firebase_url and 
                existing_firebase_url.strip()):
                
                os.remove(temp_path)
                logger.info(f"🔄 Identical PDF detected for {chapter_id} with successful Firebase URL")
                return {
                    'success': True, 
                    'message': 'Identical PDF detected with successful Firebase upload - no processing needed',
                    'duplicate_detected': True,
                    'existing_firebase_url': existing_firebase_url,
                    'chapter_info': NCTB_CHAPTERS[chapter_id]
                }
            
            # If identical file but no Firebase URL, or force reupload, continue processing
            if existing_hash == file_hash and not existing_firebase_url:
                logger.info(f"🔄 Identical PDF detected for {chapter_id} but no Firebase URL - proceeding with upload")
            elif force_reupload:
                logger.info(f"🔄 Force reupload requested for {chapter_id}")
            else:
                logger.info(f"📄 Processing new PDF for {chapter_id}")
            
            # Move file to final location
            local_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            try:
                shutil.move(temp_path, local_path)
            except Exception:
                shutil.copy2(temp_path, local_path)
                os.remove(temp_path)
            
            # Extract text and create chunks
            logger.info(f"📄 Processing content - extracting text and creating chunks")
            text_chunks = self.extract_text_chunks(local_path)
            if not text_chunks:
                return {'success': False, 'error': 'Failed to extract text from PDF'}

            # Create embeddings
            logger.info(f"🧠 Creating embeddings for {len(text_chunks)} text chunks")
            if not self.create_embeddings(text_chunks, class_level, chapter_id):
                logger.warning("Failed to create embeddings, but continuing with upload")

            # FIREBASE UPLOAD - THE MAIN FEATURE
            firebase_url = None
            firebase_path = None
            firebase_upload_success = False
            
            if self.firebase_initialized:
                try:
                    firebase_path = f"chapters/class_{class_level}/{chapter_id}.pdf"
                    logger.info(f"🔄 Starting Firebase upload to: {firebase_path}")
                    
                    # Try Admin SDK first
                    try:
                        logger.info("🔥 Attempting upload via Firebase Admin SDK...")
                        blob = self.storage_bucket.blob(firebase_path)
                        blob.upload_from_filename(local_path)
                        blob.make_public()
                        firebase_url = blob.public_url
                        firebase_upload_success = True
                        logger.info(f"🔥 ✅ Firebase upload successful via Admin SDK!")
                        logger.info(f"📱 Students can download from: {firebase_url}")
                        
                    except Exception as admin_err:
                        logger.warning(f"🔥 ❌ Admin SDK upload failed: {admin_err}")
                        if "storage.objects.create" in str(admin_err):
                            logger.info("🔑 Trying signed URL method due to permission issue...")
                            success, public_url = self._upload_file_via_signed_url(local_path, firebase_path)
                            if success:
                                firebase_url = public_url
                                firebase_upload_success = True
                                logger.info("🔥 ✅ Firebase upload successful via Signed URL!")
                                logger.info(f"📱 Students can download from: {firebase_url}")
                            else:
                                logger.error("🔥 ❌ Signed URL upload also failed")
                        else:
                            logger.error(f"🔥 ❌ Firebase upload failed with unexpected error: {admin_err}")
                    
                except Exception as e:
                    logger.error(f"🔥 ❌ Firebase upload exception: {e}")
                    firebase_upload_success = False
            else:
                logger.warning(f"🔥 ⚠️ Firebase not initialized - PDF will be local only")
                logger.warning("📱 Students will NOT be able to download this PDF")
            
            # Update local metadata
            if chapter_key not in self.chapter_metadata:
                self.chapter_metadata[chapter_key] = {}
            
            self.chapter_metadata[chapter_key][chapter_id] = {
                'filename': filename,
                'local_path': local_path,
                'firebase_url': firebase_url,
                'firebase_path': firebase_path,
                'file_hash': file_hash,
                'upload_date': datetime.now().isoformat(),
                'text_chunks_count': len(text_chunks),
                'chapter_info': NCTB_CHAPTERS[chapter_id],
                'class_level': class_level,
                'subject': 'Mathematics'
            }
            
            self._save_metadata()
            
            # SAVE TO FIRESTORE - FOR STUDENT ACCESS
            if self.db and firebase_upload_success:
                try:
                    chapter_doc_data = {
                        'chapter_id': chapter_id,
                        'class_level': class_level,
                        'chapter_name': NCTB_CHAPTERS[chapter_id]['name'],
                        'english_name': NCTB_CHAPTERS[chapter_id]['englishName'],
                        'chapter_number': NCTB_CHAPTERS[chapter_id]['chapterNumber'],
                        'displayTitle': f"{NCTB_CHAPTERS[chapter_id]['chapterNumber']} {NCTB_CHAPTERS[chapter_id]['name']}",
                        'displaySubtitle': NCTB_CHAPTERS[chapter_id]['englishName'],
                        'download_url': firebase_url,
                        'firebase_path': firebase_path,
                        'filename': filename,
                        'subject': 'Mathematics',
                        'upload_date': datetime.now(),
                        'file_size_bytes': os.path.getsize(local_path) if os.path.exists(local_path) else 0,
                        'text_chunks_count': len(text_chunks),
                        'is_available': True,
                        'file_hash': file_hash
                    }
                    
                    # Save to Firestore
                    doc_id = f"{class_level}_{chapter_id}"
                    self.db.collection('chapters').document(doc_id).set(chapter_doc_data)
                    logger.info(f"💾 Chapter info saved to Firestore: {doc_id}")
                    logger.info(f"📱 Students can now download from: {firebase_url}")
                    
                except Exception as firestore_error:
                    logger.warning(f"⚠️ Failed to save to Firestore: {firestore_error}")
            
            logger.info(f"✅ Successfully processed chapter: {class_level}_{chapter_id}")
            
            # Return success response
            if firebase_upload_success:
                message = f'✅ Chapter uploaded to Firebase Storage and URL saved to Firestore! Students can now download.'
                firebase_status = 'uploaded_for_students'
            else:
                message = f'⚠️ Chapter processed but Firebase upload failed - students cannot download yet'
                firebase_status = 'local_only_no_student_access'
            
            return {
                'success': True,
                'message': message,
                'chunks_created': len(text_chunks),
                'firebase_status': firebase_status,
                'firebase_url': firebase_url,
                'firebase_path': firebase_path,
                'student_download_ready': firebase_upload_success,
                'firestore_saved': self.db is not None and firebase_upload_success,
                'local_available': True,
                'chapter_info': NCTB_CHAPTERS[chapter_id],
                'student_instructions': 'Students can download this chapter in the app' if firebase_upload_success else 'Fix Firebase permissions for student downloads'
            }
            
        except Exception as e:
            logger.error(f"Error uploading chapter: {e}")
            return {'success': False, 'error': str(e)}

    def get_chapter_download_info(self, class_level, chapter_id):
        """Get chapter download information for students"""
        try:
            if self.db:
                doc_id = f"{class_level}_{chapter_id}"
                doc = self.db.collection('chapters').document(doc_id).get()
                if doc.exists:
                    data = doc.to_dict()
                    return {
                        'success': True,
                        'chapter_info': data,
                        'download_ready': data.get('is_available', False),
                        'download_url': data.get('download_url'),
                        'file_size': data.get('file_size_bytes', 0)
                    }
            
            # Fallback to local metadata
            chapter_key = f"class_{class_level}"
            metadata = self.chapter_metadata.get(chapter_key, {}).get(chapter_id, {})
            if metadata:
                return {
                    'success': True,
                    'chapter_info': metadata,
                    'download_ready': bool(metadata.get('firebase_url')),
                    'download_url': metadata.get('firebase_url'),
                    'file_size': 0
                }
            
            return {'success': False, 'error': 'Chapter not found'}
            
        except Exception as e:
            logger.error(f"Error getting download info: {e}")
            return {'success': False, 'error': str(e)}

# Initialize manager
pdf_manager = ChapterPDFManager()

# HTML Template for web interface
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chapter PDF Manager - Firebase Storage</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .upload-section { background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        select, input[type="file"] { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 5px; }
        button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }
        button:hover { background: #0056b3; }
        .chapters-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
        .chapter-card { background: white; border: 1px solid #ddd; border-radius: 10px; padding: 15px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .chapter-title { font-size: 16px; font-weight: bold; color: #333; margin-bottom: 5px; }
        .chapter-subtitle { font-size: 14px; color: #666; margin-bottom: 10px; }
        .status-badge { padding: 3px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }
        .status-available { background: #d4edda; color: #155724; }
        .status-local { background: #fff3cd; color: #856404; }
        .status-missing { background: #f8d7da; color: #721c24; }
        .firebase-indicator { margin-top: 10px; }
        .firebase-available { color: #28a745; }
        .firebase-local { color: #ffc107; }
        .action-buttons { margin-top: 10px; }
        .btn-sm { padding: 5px 10px; font-size: 12px; margin-right: 5px; }
        .btn-danger { background: #dc3545; }
        .btn-warning { background: #ffc107; color: #212529; }
        .btn-success { background: #28a745; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📚 Chapter PDF Manager</h1>
        <p>Upload PDFs to Firebase Storage & Save URLs to Firestore for Student Access</p>
    </div>

    <div class="upload-section">
        <h2>Upload Chapter PDF</h2>
        <form method="post" enctype="multipart/form-data" action="/upload">
            <div class="form-group">
                <label for="class_level">Class Level:</label>
                <select name="class_level" required>
                    <option value="">Select Class</option>
                    <option value="9">Class 9</option>
                    <option value="10">Class 10</option>
                </select>
            </div>
            
            <div class="form-group">
                <label for="chapter_id">Chapter:</label>
                <select name="chapter_id" required>
                    <option value="">Select Chapter</option>
                    {% for chapter in chapters %}
                    <option value="{{ chapter.id }}">{{ chapter.chapterNumber }} {{ chapter.name }} ({{ chapter.englishName }})</option>
                    {% endfor %}
                </select>
            </div>
            
            <div class="form-group">
                <label for="pdf_file">PDF File:</label>
                <input type="file" name="pdf_file" accept=".pdf" required>
            </div>
            
            <div class="form-group" style="background: #fff3cd; padding: 15px; border-radius: 5px; border: 1px solid #ffeaa7;">
                <label style="font-size: 16px; color: #856404;">
                    <input type="checkbox" name="force_reupload" style="transform: scale(1.2); margin-right: 10px;"> 
                    <strong>Force Re-upload</strong> (Check this if upload was blocked by "identical PDF detected")
                </label>
                <div style="font-size: 12px; color: #856404; margin-top: 5px;">
                    ⚠️ This will replace existing content and re-upload to Firebase even if the file is identical
                </div>
            </div>
            
            <button type="submit">Upload to Firebase Storage</button>
        </form>
    </div>

    <div class="chapters-section">
        <h2>Available Chapters</h2>
        <div class="chapters-grid">
            {% for chapter in chapters %}
            <div class="chapter-card">
                <div class="chapter-title">{{ chapter.chapterNumber }} {{ chapter.name }}</div>
                <div class="chapter-subtitle">{{ chapter.englishName }}</div>
                
                {% if chapter.get('status') %}
                <span class="status-badge status-{{ chapter.status }}">
                    {{ chapter.status_text }}
                </span>
                
                <div class="firebase-indicator">
                    {% if chapter.firebase_url %}
                    <span class="firebase-available">🔥 Firebase: Available for students</span>
                    {% else %}
                    <span class="firebase-local">📁 Local: Students cannot download</span>
                    {% endif %}
                </div>
                
                <div class="action-buttons">
                    {% if chapter.firebase_url %}
                    <a href="{{ chapter.firebase_url }}" target="_blank" class="btn-sm btn-success">Download</a>
                    {% endif %}
                    <button class="btn-sm btn-warning" onclick="forceReupload('{{ chapter.class_level }}', '{{ chapter.id }}')">Re-upload</button>
                    <button class="btn-sm btn-danger" onclick="clearMetadata('{{ chapter.class_level }}', '{{ chapter.id }}')">Clear & Fresh Upload</button>
                </div>
                {% else %}
                <span class="status-badge status-missing">Not uploaded</span>
                {% endif %}
            </div>
            {% endfor %}
        </div>
    </div>

    <script>
        function forceReupload(classLevel, chapterId) {
            if (confirm('Re-upload this chapter? This will replace existing content.')) {
                window.location.href = `/force-reupload/${classLevel}/${chapterId}`;
            }
        }
        
        function clearMetadata(classLevel, chapterId) {
            if (confirm('Clear all metadata for this chapter? This will allow fresh upload but remove existing records.')) {
                fetch(`/clear_metadata/${classLevel}/${chapterId}`, {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    alert(data.message);
                    if (data.success) {
                        location.reload();
                    }
                })
                .catch(error => {
                    alert('Error: ' + error);
                });
            }
        }
    </script>
</body>
</html>
"""

# Flask routes
@app.route('/')
def index():
    """Main upload interface"""
    chapters = list(NCTB_CHAPTERS.values())
    
    # Add status information for each chapter
    for chapter in chapters:
        for class_level in [9, 10]:
            chapter_key = f"class_{class_level}"
            metadata = pdf_manager.chapter_metadata.get(chapter_key, {}).get(chapter['id'], {})
            if metadata:
                chapter['status'] = 'available' if metadata.get('firebase_url') else 'local'
                chapter['status_text'] = 'Available for Students' if metadata.get('firebase_url') else 'Local Only'
                chapter['firebase_url'] = metadata.get('firebase_url')
                chapter['class_level'] = class_level
                break
        else:
            chapter['status'] = 'missing'
            chapter['status_text'] = 'Not Uploaded'
    
    # Sort chapters by chapter_number
    chapters.sort(key=lambda x: x['chapter_number'])
    
    return render_template_string(HTML_TEMPLATE, chapters=chapters)

@app.route('/upload', methods=['POST'])
def upload_chapter():
    """Handle chapter upload"""
    try:
        class_level = int(request.form['class_level'])
        chapter_id = request.form['chapter_id']
        force_reupload = 'force_reupload' in request.form
        
        if 'pdf_file' not in request.files:
            return jsonify({'success': False, 'error': 'No PDF file uploaded'})
        
        file = request.files['pdf_file']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No file selected'})
        
        result = pdf_manager.upload_chapter_pdf(file, class_level, chapter_id, force_reupload)
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/chapter/<int:class_level>/<chapter_id>/download_info', methods=['GET'])
def get_chapter_download_info(class_level, chapter_id):
    """Get chapter download information for Flutter app"""
    result = pdf_manager.get_chapter_download_info(class_level, chapter_id)
    return jsonify(result)

@app.route('/api/chapters/available/<int:class_level>', methods=['GET'])
def get_available_chapters(class_level):
    """Get available chapters for a class level"""
    try:
        chapters = []
        valid_chapters = get_chapters_for_class(class_level)
        
        for chapter_id, chapter_info in valid_chapters.items():
            # Check if chapter is uploaded
            chapter_key = f"class_{class_level}"
            metadata = pdf_manager.chapter_metadata.get(chapter_key, {}).get(chapter_id, {})
            
            # Get from Firestore if available
            chapter_data = {
                'chapter_id': chapter_id,
                'class_level': class_level,
                'chapter_name': chapter_info['name'],
                'english_name': chapter_info['englishName'],
                'chapter_number': chapter_info['chapterNumber'],
                'displayTitle': f"{chapter_info['chapterNumber']} {chapter_info['name']}",
                'displaySubtitle': chapter_info['englishName'],
                'is_available': bool(metadata.get('firebase_url')),
                'download_url': metadata.get('firebase_url'),
                'file_size_bytes': 0
            }
            
            # Try to get updated info from Firestore
            if pdf_manager.db:
                try:
                    doc_id = f"{class_level}_{chapter_id}"
                    doc = pdf_manager.db.collection('chapters').document(doc_id).get()
                    if doc.exists:
                        firestore_data = doc.to_dict()
                        chapter_data.update(firestore_data)
                except Exception:
                    pass  # Use metadata fallback
            
            chapters.append(chapter_data)
        
        return jsonify({
            'success': True,
            'chapters': chapters,
            'class_level': class_level
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/clear_metadata/<int:class_level>/<chapter_id>', methods=['POST'])
def clear_chapter_metadata(class_level, chapter_id):
    """Clear metadata for a specific chapter to force fresh upload"""
    try:
        chapter_key = f"class_{class_level}"
        if chapter_key in pdf_manager.chapter_metadata and chapter_id in pdf_manager.chapter_metadata[chapter_key]:
            del pdf_manager.chapter_metadata[chapter_key][chapter_id]
            pdf_manager._save_metadata()
            
            # Also delete from Firestore
            if pdf_manager.db:
                doc_id = f"{class_level}_{chapter_id}"
                pdf_manager.db.collection('chapters').document(doc_id).delete()
            
            return jsonify({
                'success': True, 
                'message': f'Metadata cleared for {chapter_id}. You can now upload fresh.'
            })
        else:
            return jsonify({
                'success': False, 
                'message': f'No metadata found for {chapter_id}'
            })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/status')
def get_status():
    """Get system status"""
    return jsonify({
        'firebase_initialized': pdf_manager.firebase_initialized,
        'pinecone_initialized': pdf_manager.pinecone_client is not None,
        'openai_initialized': pdf_manager.openai_client is not None,
        'storage_bucket': pdf_manager.storage_bucket.name if pdf_manager.storage_bucket else None,
        'firestore_available': pdf_manager.db is not None,
        'total_chapters': len(pdf_manager.chapter_metadata)
    })

if __name__ == '__main__':
    print("🚀 Starting Chapter PDF Manager with Firebase Integration...")
    print("📚 Upload chapter PDFs to Firebase Storage")
    print("💾 URLs automatically saved to Firestore")
    print("📱 Students can download via Flutter app")
    print("🔗 Access the web interface at: http://localhost:5001")
    print(f"\n🔥 Firebase Status: {'✅ Initialized' if pdf_manager.firebase_initialized else '❌ Not Available'}")
    print(f"💾 Firestore Status: {'✅ Connected' if pdf_manager.db else '❌ Not Available'}")
    print(f"📊 Pinecone Status: {'✅ Connected' if pdf_manager.pinecone_client else '❌ Not Available'}")
    
    app.run(
        host='0.0.0.0', 
        port=5001, 
        debug=False,
        threaded=True
    )
