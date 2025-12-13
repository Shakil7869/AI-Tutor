#!/usr/bin/env python3
"""
Chapter-wise PDF Management Service with Pinecone Integration
Handles individual chapter PDF uploads and creates vector embeddings for AI retrieval
"""

import os
import sys
import json
import logging
import tempfile
import shutil
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

# Firebase imports (optional)
try:
    import firebase_admin
    from firebase_admin import credentials, storage, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    print("⚠️ Firebase not available - continuing in local mode")

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
    },
    # Class 10 chapters (advanced versions)
    'real_numbers_advanced': {
        'id': 'real_numbers_advanced',
        'name': 'বাস্তব সংখ্যা (উন্নত)',
        'englishName': 'Real Numbers (Advanced)',
        'chapterNumber': '১ম অধ্যায়',
        'chapter_number': 1
    }
}

# Helper functions for chapter management
def get_chapters_for_class(class_level):
    """Get chapters available for a specific class level"""
    if class_level == 9:
        return {k: v for k, v in NCTB_CHAPTERS.items() if not 'advanced' in k}
    elif class_level == 10:
        return NCTB_CHAPTERS  # Class 10 can access all chapters including advanced
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
            return
            
        try:
            config_path = os.path.join(os.path.dirname(__file__), 'config', 'firebase_config.json')
            if os.path.exists(config_path):
                if not firebase_admin._apps:
                    cred = credentials.Certificate(config_path)
                    firebase_admin.initialize_app(cred, {
                        'storageBucket': 'ai-tutor-mvp.appspot.com'
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
        """Generate a V4 signed URL for uploading via HTTP PUT, avoiding IAM create permission.

        Returns tuple (url, headers, download_token) or (None, None, None) on failure.
        """
        try:
            if not self.firebase_initialized or not self.storage_bucket:
                logger.warning("Firebase not initialized; cannot generate signed URL")
                return None, None, None

            blob = self.storage_bucket.blob(firebase_path)

            headers = { 'Content-Type': content_type }
            # Add Firebase download token metadata so downloads work without public ACL
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

    def _upload_file_via_signed_url(self, local_path: str, firebase_path: str) -> tuple[bool, str | None]:
        """Upload a file to GCS using a V4 signed URL (HTTP PUT). Returns (success, firebase_download_url)."""
        try:
            url, headers, download_token = self._generate_signed_put_url(firebase_path)
            if not url:
                return False, None

            # Use urllib to avoid external dependencies
            import urllib.request
            logger.info(f"⬆️  Uploading via signed URL (PUT) to {firebase_path}")
            with open(local_path, 'rb') as f:
                data = f.read()
            req = urllib.request.Request(url, data=data, method='PUT')
            for k, v in headers.items():
                req.add_header(k, v)
            try:
                with urllib.request.urlopen(req) as resp:
                    status = resp.getcode()
                    if 200 <= status < 300:
                        # Build Firebase download URL using token metadata we set
                        path_escaped = url_quote(firebase_path, safe='')
                        public_url = (
                            f"https://firebasestorage.googleapis.com/v0/b/{self.storage_bucket.name}/o/{path_escaped}?alt=media&token={download_token}"
                        )
                        logger.info(f"✅ Signed URL upload succeeded with status {status}")
                        return True, public_url
                    else:
                        logger.warning(f"Signed URL upload returned status {status}")
                        return False, None
            except Exception as http_err:
                logger.warning(f"Signed URL upload failed: {http_err}")
                return False, None
        except Exception as e:
            logger.warning(f"Signed URL upload exception: {e}")
            return False, None
    
    def _initialize_pinecone(self):
        """Initialize Pinecone for vector storage"""
        try:
            # Get API key from environment variable
            # api_key = os.getenv('PINECONE_API_KEY')
            api_key = "pcsk_4MsQRi_7RTxjoGyVVALKNizgavCabr3UGYJZPj4cLibVmn1HKdQD8zqRS9RCaVJZqWbKoF"
            if not api_key:
                logger.error("❌ PINECONE_API_KEY environment variable not set")
                return
            
            self.pinecone_client = Pinecone(api_key=api_key)
            
            # Create or connect to index
            index_name = "nctb-math-chapters"
            if index_name not in self.pinecone_client.list_indexes().names():
                self.pinecone_client.create_index(
                    name=index_name,
                    dimension=1536,  # OpenAI embedding dimension
                    metric="cosine",
                    spec=ServerlessSpec(
                        cloud="aws",
                        region="us-east-1"
                    )
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
                logger.error("❌ OPENAI_API_KEY environment variable not set")
                return
            
            # Set the API key for older openai versions
            openai.api_key = api_key
            self.openai_client = True  # Just a flag to indicate it's initialized
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
    
    def create_embeddings(self, text_chunks, class_level, chapter_id):
        """Create embeddings for text chunks and store in Pinecone - optimized"""
        if not self.openai_client or not self.pinecone_client:
            logger.error("OpenAI or Pinecone not initialized")
            return False
        
        try:
            vectors = []
            batch_size = 10  # Process in smaller batches
            
            for i, chunk in enumerate(text_chunks):
                try:
                    # Create embedding using older API
                    response = openai.Embedding.create(
                        model="text-embedding-ada-002",
                        input=chunk[:1000]  # Limit input size
                    )
                    embedding = response['data'][0]['embedding']
                    
                    # Create unique ID for this chunk
                    chunk_id = f"{class_level}_{chapter_id}_chunk_{i}"
                    
                    # Prepare metadata with size limits
                    metadata = {
                        'class_level': class_level,
                        'chapter_id': chapter_id,
                        'chapter_name': NCTB_CHAPTERS.get(chapter_id, {}).get('englishName', chapter_id)[:100],
                        'bengali_name': NCTB_CHAPTERS.get(chapter_id, {}).get('name', chapter_id)[:100],
                        'chunk_index': i,
                        'text': chunk[:500],  # Reduced size for better performance
                        'upload_date': datetime.now().isoformat()
                    }
                    
                    vectors.append({
                        'id': chunk_id,
                        'values': embedding,
                        'metadata': metadata
                    })
                    
                    # Upload in batches to avoid memory issues
                    if len(vectors) >= batch_size:
                        self.index.upsert(vectors=vectors)
                        logger.info(f"📊 Uploaded batch of {len(vectors)} embeddings")
                        vectors = []  # Clear batch
                        
                except Exception as e:
                    logger.warning(f"Failed to create embedding for chunk {i}: {e}")
                    continue
            
            # Upload remaining vectors
            if vectors:
                self.index.upsert(vectors=vectors)
                logger.info(f"📊 Uploaded final batch of {len(vectors)} embeddings")
            
            logger.info(f"📊 Successfully created embeddings for {chapter_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error creating embeddings: {e}")
            return False
    
    def extract_text_chunks(self, pdf_path, chunk_size=800, overlap=50):
        """Extract text from PDF and split into chunks - optimized for performance"""
        try:
            doc = fitz.open(pdf_path)
            text_pages = []
            
            # Extract text page by page to manage memory
            for page_num in range(min(doc.page_count, 50)):  # Limit to 50 pages max
                page = doc[page_num]
                text = page.get_text()
                if text.strip():  # Only add non-empty pages
                    text_pages.append(text)
                
                # Clean up page immediately
                del page
            
            doc.close()
            
            # Join all pages
            full_text = "\n".join(text_pages)
            del text_pages  # Free memory
            
            # Split into smaller, more manageable chunks
            chunks = []
            words = full_text.split()
            
            current_chunk = []
            current_length = 0
            
            for word in words:
                if current_length + len(word) > chunk_size and current_chunk:
                    # Save current chunk
                    chunk_text = " ".join(current_chunk)
                    if len(chunk_text.strip()) > 50:  # Only keep meaningful chunks
                        chunks.append(chunk_text)
                    
                    # Start new chunk with overlap
                    overlap_words = current_chunk[-overlap//10:] if len(current_chunk) > overlap//10 else []
                    current_chunk = overlap_words + [word]
                    current_length = sum(len(w) for w in current_chunk)
                else:
                    current_chunk.append(word)
                    current_length += len(word) + 1
                
                # Limit total chunks to prevent memory issues
                if len(chunks) >= 100:
                    break
            
            # Add final chunk
            if current_chunk:
                chunk_text = " ".join(current_chunk)
                if len(chunk_text.strip()) > 50:
                    chunks.append(chunk_text)
            
            logger.info(f"📄 Extracted {len(chunks)} optimized text chunks from PDF")
            return chunks[:50]  # Limit to 50 chunks max
            
        except Exception as e:
            logger.error(f"Error extracting text: {e}")
            return []
    
    def calculate_file_hash(self, file_path):
        """Calculate SHA256 hash of file for duplicate detection"""
        try:
            hash_sha256 = hashlib.sha256()
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()
        except Exception as e:
            logger.error(f"Error calculating file hash: {e}")
            return None
    
    def check_chapter_exists_in_pinecone(self, class_level, chapter_id):
        """Check if chapter already exists in Pinecone"""
        try:
            if not self.index:
                return False
            
            # Query for any existing chunks for this chapter
            query_filter = {
                'class_level': {'$eq': class_level},
                'chapter_id': {'$eq': chapter_id}
            }
            
            # Try to find at least one chunk
            results = self.index.query(
                vector=[0.0] * 1536,  # Dummy vector for metadata query
                top_k=1,
                include_metadata=True,
                filter=query_filter
            )
            
            return len(results.matches) > 0
            
        except Exception as e:
            logger.warning(f"Error checking chapter existence: {e}")
            return False
    
    def delete_existing_chapter_chunks(self, class_level, chapter_id):
        """Delete existing chunks for a chapter from Pinecone"""
        try:
            if not self.index:
                return False
            
            # Find all chunk IDs for this chapter
            query_filter = {
                'class_level': {'$eq': class_level},
                'chapter_id': {'$eq': chapter_id}
            }
            
            # Get all chunk IDs (Pinecone has limits, so we may need pagination)
            all_ids = []
            
            # Query in batches to get all IDs
            for i in range(10):  # Max 10 batches (should be enough for most chapters)
                results = self.index.query(
                    vector=[0.0] * 1536,
                    top_k=100,
                    include_metadata=True,
                    filter=query_filter
                )
                
                if not results.matches:
                    break
                    
                batch_ids = [match.id for match in results.matches]
                all_ids.extend(batch_ids)
                
                # Delete this batch
                if batch_ids:
                    self.index.delete(ids=batch_ids)
                    logger.info(f"🗑️ Deleted {len(batch_ids)} chunks from batch {i+1}")
            
            if all_ids:
                logger.info(f"🗑️ Successfully deleted {len(all_ids)} existing chunks for {chapter_id}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error deleting existing chunks: {e}")
            return False

    def upload_chapter_pdf(self, file, class_level, chapter_id, force_reupload=False):
        """Upload and process a chapter PDF with duplicate detection"""
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
            
            # Save file temporarily to calculate hash
            filename = secure_filename(f"class_{class_level}_{chapter_id}.pdf")
            temp_path = os.path.join(tempfile.gettempdir(), f"temp_{filename}")
            file.save(temp_path)
            
            # Calculate file hash for duplicate detection
            file_hash = self.calculate_file_hash(temp_path)
            if not file_hash:
                os.remove(temp_path)
                return {'success': False, 'error': 'Failed to calculate file hash'}
            
            # Check if this exact file was already uploaded
            chapter_key = f"class_{class_level}"
            existing_metadata = self.chapter_metadata.get(chapter_key, {}).get(chapter_id, {})
            existing_hash = existing_metadata.get('file_hash')
            
            if existing_hash == file_hash and not force_reupload:
                os.remove(temp_path)
                chunks_count = existing_metadata.get('text_chunks_count', 0)
                logger.info(f"🔄 Identical PDF detected for {chapter_id} (hash: {file_hash[:8]}...)")
                logger.info(f"⏩ Skipping chunk processing - using existing {chunks_count} chunks")
                
                # Check if Firebase URL exists, if not, try to upload just the file
                firebase_url = existing_metadata.get('firebase_url')
                firebase_upload_success = bool(firebase_url)
                
                if not firebase_upload_success and self.firebase_initialized:
                    logger.info(f"🔄 Firebase URL missing - attempting Firebase upload for existing file")
                    try:
                        local_path = existing_metadata.get('local_path')
                        if local_path and os.path.exists(local_path):
                            firebase_path = f"chapters/class_{class_level}/{chapter_id}.pdf"
                            # Try Admin SDK first
                            try:
                                blob = self.storage_bucket.blob(firebase_path)
                                blob.upload_from_filename(local_path)
                                blob.make_public()
                                firebase_url = blob.public_url
                                firebase_upload_success = True
                            except Exception as admin_err:
                                if "storage.objects.create" in str(admin_err):
                                    logger.warning("🔑 No create permission via Admin SDK; trying signed URL upload")
                                    ok, public_url = self._upload_file_via_signed_url(local_path, firebase_path)
                                    if ok:
                                        firebase_url = public_url
                                        firebase_upload_success = True
                                    else:
                                        logger.warning("Signed URL upload failed for existing file")
                                else:
                                    logger.warning(f"Admin upload failed: {admin_err}")
                            
                            # Update metadata with Firebase URL
                            self.chapter_metadata[chapter_key][chapter_id]['firebase_url'] = firebase_url
                            self.chapter_metadata[chapter_key][chapter_id]['firebase_path'] = firebase_path
                            self._save_metadata()
                            
                            # Update Firestore with Firebase URL for existing file
                            if self.db and firebase_upload_success:
                                try:
                                    doc_id = f"{class_level}_{chapter_id}"
                                    self.db.collection('chapters').document(doc_id).update({
                                        'download_url': firebase_url,
                                        'firebase_path': firebase_path,
                                        'is_available': True
                                    })
                                    logger.info(f"💾 Firestore updated with Firebase URL for existing file: {doc_id}")
                                except Exception as firestore_error:
                                    logger.warning(f"⚠️ Failed to update Firestore: {firestore_error}")
                            
                            logger.info(f"🔥 ✅ Firebase upload completed for existing file!")
                    except Exception as e:
                        logger.warning(f"🔒 Firebase upload failed for existing file: {e}")
                
                return {
                    'success': True, 
                    'message': f'Identical PDF detected - no chunk update needed ({chunks_count} existing chunks)',
                    'duplicate_detected': True,
                    'file_hash': file_hash,
                    'existing_chunks': chunks_count,
                    'chunks_created': chunks_count,
                    'firebase_status': 'uploaded_for_students' if firebase_upload_success else 'local_only_no_student_access',
                    'firebase_url': firebase_url,
                    'student_download_ready': firebase_upload_success,
                    'chapter_info': NCTB_CHAPTERS[chapter_id],
                    'action': 'skipped_identical_file'
                }
            
            # Check if chapter exists in Pinecone (different file content)
            chapter_exists = self.check_chapter_exists_in_pinecone(class_level, chapter_id)
            if chapter_exists and not force_reupload:
                logger.info(f"🔄 Chapter {chapter_id} exists in Pinecone but with different content")
                
                # Check if we have existing metadata with different hash
                if existing_hash and existing_hash != file_hash:
                    logger.info(f"📝 File content changed - will update chunks")
                    logger.info(f"   Old hash: {existing_hash[:8]}...")
                    logger.info(f"   New hash: {file_hash[:8]}...")
                elif existing_hash == file_hash:
                    # Same file, chunks already exist - just handle Firebase if needed
                    os.remove(temp_path)
                    logger.info(f"⏩ Same file already processed - skipping chunk regeneration")
                    
                    firebase_url = existing_metadata.get('firebase_url')
                    firebase_upload_success = bool(firebase_url)
                    
                    return {
                        'success': True,
                        'message': f'Chapter already processed with same content - no updates needed',
                        'duplicate_detected': True,
                        'file_hash': file_hash,
                        'existing_chunks': existing_metadata.get('text_chunks_count', 0),
                        'chunks_created': existing_metadata.get('text_chunks_count', 0),
                        'firebase_status': 'uploaded_for_students' if firebase_upload_success else 'local_only_no_student_access',
                        'firebase_url': firebase_url,
                        'student_download_ready': firebase_upload_success,
                        'chapter_info': NCTB_CHAPTERS[chapter_id],
                        'action': 'skipped_same_content'
                    }
                    return {
                        'success': False,
                        'error': f'Chapter {chapter_id} already exists with different content. Use force_reupload=true to replace.',
                        'requires_confirmation': True,
                        'existing_hash': existing_hash,
                        'new_hash': file_hash
                    }
            
            # If we're replacing existing content, delete old chunks
            if chapter_exists or force_reupload:
                logger.info(f"🗑️ Replacing existing content for {chapter_id}")
                self.delete_existing_chapter_chunks(class_level, chapter_id)
            
            # Move file to final location (use shutil.move for cross-drive compatibility)
            local_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            try:
                shutil.move(temp_path, local_path)
            except Exception as move_error:
                # If move fails, copy and delete manually
                try:
                    shutil.copy2(temp_path, local_path)
                    os.remove(temp_path)
                except Exception as copy_error:
                    logger.error(f"Failed to move file: {move_error}, copy failed: {copy_error}")
                    return {'success': False, 'error': f'Failed to save file: {copy_error}'}
            
            # Extract text and create chunks (only if new/different content)
            logger.info(f"📄 Processing new/changed content - extracting text and creating chunks")
            text_chunks = self.extract_text_chunks(local_path)
            if not text_chunks:
                return {'success': False, 'error': 'Failed to extract text from PDF'}

            # Create embeddings (only for new/different content)
            logger.info(f"🧠 Creating embeddings for {len(text_chunks)} text chunks")
            if not self.create_embeddings(text_chunks, class_level, chapter_id):
                return {'success': False, 'error': 'Failed to create embeddings'}            # Upload to Firebase Storage (PRIMARY FOCUS)
            firebase_url = None
            firebase_path = None
            firebase_upload_success = False
            
            if self.firebase_initialized:
                try:
                    # Use Firebase path structure for student downloads
                    firebase_path = f"chapters/class_{class_level}/{chapter_id}.pdf"
                    # Upload PDF with progress logging
                    logger.info(f"🔄 Uploading to Firebase Storage: {firebase_path}")
                    try:
                        blob = self.storage_bucket.blob(firebase_path)
                        blob.upload_from_filename(local_path)
                        blob.make_public()
                        firebase_url = blob.public_url
                        firebase_upload_success = True
                        logger.info(f"🔥 ✅ Firebase upload successful via Admin SDK!")
                        logger.info(f"📱 Students can now download: {firebase_url}")
                    except Exception as admin_err:
                        if "storage.objects.create" in str(admin_err):
                            logger.warning("� No create permission via Admin SDK; trying signed URL upload")
                            ok, public_url = self._upload_file_via_signed_url(local_path, firebase_path)
                            if ok:
                                firebase_url = public_url
                                firebase_upload_success = True
                                logger.info("🔥 ✅ Firebase upload successful via Signed URL!")
                                logger.info(f"📱 Students can now download: {firebase_url}")
                            else:
                                logger.warning("⚠️ Signed URL upload failed")
                        else:
                            logger.warning(f"⚠️ Firebase upload failed: {admin_err}")
                    
                except Exception as e:
                    logger.warning(f"⚠️ Firebase upload exception: {e}")
                    logger.info(f"📁 File available locally via Python service as fallback")
                    firebase_upload_success = False
            else:
                logger.warning(f"⚠️ Firebase not initialized - PDF will be local only")
                logger.warning(f"📋 Students won't be able to download this chapter in the app")
            
            # Update metadata with hash
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
                'subject': 'Mathematics'  # Default subject
            }
            
            self._save_metadata()
            
            # Save chapter info to Firestore for student downloads
            if self.db and firebase_upload_success:
                try:
                    chapter_doc_data = {
                        'chapter_id': chapter_id,
                        'class_level': class_level,
                        'chapter_name': NCTB_CHAPTERS[chapter_id]['name'],
                        'english_name': NCTB_CHAPTERS[chapter_id]['englishName'],
                        'chapter_number': NCTB_CHAPTERS[chapter_id]['chapterNumber'],
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
                    
                    # Save to Firestore collection: chapters/{class_level}_{chapter_id}
                    doc_id = f"{class_level}_{chapter_id}"
                    self.db.collection('chapters').document(doc_id).set(chapter_doc_data)
                    logger.info(f"💾 Chapter info saved to Firestore: {doc_id}")
                    
                except Exception as firestore_error:
                    logger.warning(f"⚠️ Failed to save to Firestore: {firestore_error}")
                    # Continue without failing the upload
            
            logger.info(f"✅ Successfully processed chapter: {class_level}_{chapter_id}")
            
            # Create success message focused on student access
            if firebase_upload_success:
                message = f'✅ Chapter uploaded to Firebase! Students can now download and view offline'
                firebase_status = 'uploaded_for_students'
            else:
                message = f'⚠️ Chapter processed but Firebase upload failed - students cannot download this chapter yet'
                firebase_status = 'local_only_no_student_access'
            
            return {
                'success': True,
                'message': message,
                'chunks_created': len(text_chunks),
                'firebase_status': firebase_status,
                'firebase_url': firebase_url,
                'firebase_path': firebase_path,
                'student_download_ready': firebase_upload_success,
                'local_available': True,
                'chapter_info': NCTB_CHAPTERS[chapter_id],
                'student_instructions': 'Students can download this chapter in the Learn Mode screen' if firebase_upload_success else 'Fix Firebase permissions for student downloads'
            }
            
        except Exception as e:
            logger.error(f"Error uploading chapter PDF: {e}")
            # Clean up temp file if it still exists
            if 'temp_path' in locals() and os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                    logger.info(f"🧹 Cleaned up temp file: {temp_path}")
                except Exception as cleanup_error:
                    logger.warning(f"Failed to clean up temp file: {cleanup_error}")
            return {'success': False, 'error': str(e)}
    
    def get_chapter_pdf(self, class_level, chapter_id):
        """Get chapter PDF file path"""
        try:
            chapter_key = f"class_{class_level}"
            if chapter_key in self.chapter_metadata and chapter_id in self.chapter_metadata[chapter_key]:
                metadata = self.chapter_metadata[chapter_key][chapter_id]
                local_path = metadata['local_path']
                
                if os.path.exists(local_path):
                    return local_path
                
                # If local file doesn't exist, try to download from Firebase
                if self.firebase_initialized and metadata.get('firebase_url'):
                    try:
                        blob = self.storage_bucket.blob(f"chapters/{metadata['filename']}")
                        blob.download_to_filename(local_path)
                        return local_path
                    except Exception as e:
                        logger.error(f"Failed to download from Firebase: {e}")
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting chapter PDF: {e}")
            return None
    
    def search_chapter_content(self, query, class_level=None, chapter_id=None, top_k=5):
        """Search chapter content using vector similarity"""
        if not self.openai_client or not self.pinecone_client:
            return []
        
        try:
            # Create query embedding using older API
            response = openai.Embedding.create(
                model="text-embedding-ada-002",
                input=query
            )
            query_embedding = response['data'][0]['embedding']
            
            # Prepare filter
            filter_dict = {}
            if class_level:
                filter_dict['class_level'] = class_level
            if chapter_id:
                filter_dict['chapter_id'] = chapter_id
            
            # Search in Pinecone
            search_results = self.index.query(
                vector=query_embedding,
                top_k=top_k,
                include_metadata=True,
                filter=filter_dict if filter_dict else None
            )
            
            # Format results
            results = []
            for match in search_results['matches']:
                results.append({
                    'score': match['score'],
                    'text': match['metadata']['text'],
                    'class_level': match['metadata']['class_level'],
                    'chapter_id': match['metadata']['chapter_id'],
                    'chapter_name': match['metadata']['chapter_name'],
                    'bengali_name': match['metadata']['bengali_name']
                })
            
            return results
            
        except Exception as e:
            logger.error(f"Error searching content: {e}")
            return []
    
    def delete_chapter(self, class_level, chapter_id):
        """Delete chapter and its embeddings"""
        try:
            # Delete from Pinecone
            if self.pinecone_client:
                # Get all chunk IDs for this chapter
                chunk_ids = [f"{class_level}_{chapter_id}_chunk_{i}" for i in range(1000)]  # Max chunks
                self.index.delete(ids=chunk_ids)
            
            # Delete from Firebase
            if self.firebase_initialized:
                filename = f"class_{class_level}_{chapter_id}.pdf"
                blob = self.storage_bucket.blob(f"chapters/{filename}")
                blob.delete()
            
            # Delete local file
            chapter_key = f"class_{class_level}"
            if chapter_key in self.chapter_metadata and chapter_id in self.chapter_metadata[chapter_key]:
                metadata = self.chapter_metadata[chapter_key][chapter_id]
                local_path = metadata['local_path']
                if os.path.exists(local_path):
                    os.remove(local_path)
                
                # Remove from metadata
                del self.chapter_metadata[chapter_key][chapter_id]
                self._save_metadata()
            
            return {'success': True, 'message': 'Chapter deleted successfully'}
            
        except Exception as e:
            logger.error(f"Error deleting chapter: {e}")
            return {'success': False, 'error': str(e)}

# Initialize manager
pdf_manager = ChapterPDFManager()

# Flask routes
@app.route('/')
def index():
    """Main upload interface - optimized UI"""
    return render_template_string("""
<!DOCTYPE html>
<html>
<head>
    <title>NCTB Chapter PDF Manager</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 1.1em; }
        
        .content { padding: 30px; }
        .upload-section {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
            border: 2px dashed #dee2e6;
            transition: all 0.3s ease;
        }
        .upload-section:hover { border-color: #4facfe; }
        
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        .form-control:focus {
            outline: none;
            border-color: #4facfe;
        }
        
        .upload-btn {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            border: none;
            padding: 15px 30px;
            font-size: 16px;
            font-weight: 600;
            border-radius: 8px;
            cursor: pointer;
            transition: transform 0.2s;
            width: 100%;
        }
        .upload-btn:hover { transform: translateY(-2px); }
        .upload-btn:disabled {
            background: #6c757d;
            cursor: not-allowed;
            transform: none;
        }
        
        .status {
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
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
        .status.info {
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        .status.loading {
            background: #cce7ff;
            color: #004085;
            border: 1px solid #b3d7ff;
            display: flex;
            align-items: center;
        }
        
        .progress-bar {
            width: 100%;
            height: 6px;
            background: #e9ecef;
            border-radius: 3px;
            overflow: hidden;
            margin: 10px 0;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #4facfe, #00f2fe);
            width: 0%;
            transition: width 0.3s ease;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            border-left: 4px solid #4facfe;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #4facfe;
        }
        .stat-label {
            color: #6c757d;
            font-size: 0.9em;
            margin-top: 5px;
        }
        
        .chapter-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .chapter-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transition: transform 0.2s, box-shadow 0.2s;
            border-left: 4px solid #dee2e6;
        }
        .chapter-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        }
        .chapter-card.uploaded {
            border-left-color: #28a745;
            background: linear-gradient(135deg, #d4edda 0%, #f8f9fa 100%);
        }
        .chapter-card.missing {
            border-left-color: #dc3545;
        }
        
        .chapter-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
        }
        .chapter-subtitle {
            color: #6c757d;
            font-size: 0.9em;
            margin-bottom: 10px;
        }
        .chapter-status {
            font-weight: 600;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.8em;
            display: inline-block;
        }
        .status-uploaded {
            background: #d4edda;
            color: #155724;
        }
        .status-missing {
            background: #f8d7da;
            color: #721c24;
        }
        
        .refresh-btn {
            background: #6c757d;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            margin-left: 10px;
        }
        
        @media (max-width: 768px) {
            .content { padding: 20px; }
            .header { padding: 20px; }
            .header h1 { font-size: 2em; }
            .stats-grid { grid-template-columns: 1fr 1fr; }
            .chapter-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📚 NCTB Chapter Manager</h1>
            <p>Upload PDFs to Firebase for student downloads with AI text selection</p>
            <div id="firebaseStatus" style="margin-top: 10px; padding: 10px; border-radius: 8px; background: rgba(255,255,255,0.1);">
                <span id="statusText">🔄 Checking Firebase status...</span>
                <button onclick="testFirebaseUpload()" id="testBtn" style="margin-left: 10px; background: rgba(255,255,255,0.2); border: 1px solid rgba(255,255,255,0.3); color: white; padding: 5px 10px; border-radius: 4px; cursor: pointer;">
                    Test Upload
                </button>
            </div>
        </div>
        
        <div class="content">
            <div class="upload-section">
                <h2 style="margin-bottom: 20px; color: #333;">📤 Upload New Chapter</h2>
                <form id="uploadForm" enctype="multipart/form-data">
                    <div class="form-group">
                        <label>📖 Class Level</label>
                        <select class="form-control" id="classLevel" name="class_level" required>
                            <option value="">Select Class</option>
                            <option value="9">Class 9</option>
                            <option value="10">Class 10</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>📋 Chapter</label>
                        <select class="form-control" id="chapterId" name="chapter_id" required>
                            <option value="">Select Chapter</option>
                            {% for chapter_id, info in chapters.items() %}
                            <option value="{{ chapter_id }}">{{ info.chapterNumber }} {{ info.name }} ({{ info.englishName }})</option>
                            {% endfor %}
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>📄 PDF File</label>
                        <input type="file" class="form-control" name="file" accept=".pdf" required>
                        <small style="color: #666; margin-top: 5px; display: block;">
                            ✨ Duplicate files are automatically detected and skipped
                        </small>
                    </div>
                    
                    <div class="form-group">
                        <label style="display: flex; align-items: center; gap: 8px;">
                            <input type="checkbox" id="forceReupload" name="force_reupload" value="true">
                            🔄 Force re-upload (replace existing content)
                        </label>
                        <small style="color: #666; margin-top: 5px; display: block;">
                            Check this to replace existing chapter content, even if it already exists
                        </small>
                    </div>
                    
                    <button type="submit" class="upload-btn" id="uploadBtn">
                        <span id="uploadText">Upload Chapter</span>
                    </button>
                    
                    <div class="progress-bar" id="progressBar" style="display: none;">
                        <div class="progress-fill" id="progressFill"></div>
                    </div>
                </form>
                
                <div id="status" class="status"></div>
            </div>
            
            <div class="stats-grid" id="statsGrid">
                <!-- Will be populated by JavaScript -->
            </div>
            
            <div style="display: flex; justify-content: space-between; align-items: center; margin: 30px 0 20px 0;">
                <h2 style="color: #333;">📊 Chapter Status</h2>
                <button class="refresh-btn" onclick="updateChapterStatus()">🔄 Refresh</button>
            </div>
            
            <div class="chapter-grid" id="chapterGrid">
                <!-- Will be populated by JavaScript -->
            </div>
        </div>
    </div>
    
    <script>
        const chapters = {{ chapters | tojson }};
        let uploadInProgress = false;
        
        // Check Firebase status on load
        async function checkFirebaseStatus() {
            try {
                const response = await fetch('/firebase_status');
                const data = await response.json();
                const statusDiv = document.getElementById('firebaseStatus');
                const statusText = document.getElementById('statusText');
                
                if (data.connected && data.can_read !== false) {
                    statusText.innerHTML = '🔥 Firebase ready for student downloads';
                    statusDiv.style.background = 'rgba(40, 167, 69, 0.2)';
                } else {
                    statusText.innerHTML = '⚠️ Firebase permissions issue - students cannot download';
                    statusDiv.style.background = 'rgba(220, 53, 69, 0.2)';
                }
            } catch (error) {
                const statusText = document.getElementById('statusText');
                statusText.innerHTML = '❌ Firebase connection failed';
                document.getElementById('firebaseStatus').style.background = 'rgba(220, 53, 69, 0.2)';
            }
        }
        
        async function testFirebaseUpload() {
            const statusText = document.getElementById('statusText');
            const testBtn = document.getElementById('testBtn');
            
            statusText.innerHTML = '🔄 Testing Firebase upload...';
            testBtn.disabled = true;
            
            try {
                const response = await fetch('/firebase-test-upload', { method: 'POST' });
                const result = await response.json();
                
                if (result.success) {
                    statusText.innerHTML = '✅ Firebase ready! Students can download PDFs';
                    document.getElementById('firebaseStatus').style.background = 'rgba(40, 167, 69, 0.2)';
                } else {
                    statusText.innerHTML = '❌ Firebase permissions issue - check console logs';
                    document.getElementById('firebaseStatus').style.background = 'rgba(220, 53, 69, 0.2)';
                    
                    if (result.fix_instructions) {
                        console.log('Firebase Fix Instructions:', result.fix_instructions);
                        alert('Firebase permissions issue. Check browser console for fix instructions.');
                    }
                }
            } catch (error) {
                statusText.innerHTML = '❌ Firebase test failed';
                document.getElementById('firebaseStatus').style.background = 'rgba(220, 53, 69, 0.2)';
            }
            
            testBtn.disabled = false;
        }
        
        // Throttled update function
        let updateTimeout;
        function throttledUpdate() {
            clearTimeout(updateTimeout);
            updateTimeout = setTimeout(updateChapterStatus, 1000);
        }
        
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            if (uploadInProgress) return;
            
            uploadInProgress = true;
            const formData = new FormData(e.target);
            const statusDiv = document.getElementById('status');
            const uploadBtn = document.getElementById('uploadBtn');
            const uploadText = document.getElementById('uploadText');
            const progressBar = document.getElementById('progressBar');
            
            // Show progress
            statusDiv.className = 'status loading';
            statusDiv.style.display = 'block';
            statusDiv.innerHTML = '⏳ Processing chapter PDF...';
            uploadBtn.disabled = true;
            uploadText.textContent = 'Processing...';
            progressBar.style.display = 'block';
            
            // Simulate progress
            let progress = 0;
            const progressInterval = setInterval(() => {
                progress += Math.random() * 15;
                if (progress > 90) progress = 90;
                document.getElementById('progressFill').style.width = progress + '%';
            }, 500);
            
            try {
                const response = await fetch('/upload', {
                    method: 'POST',
                    body: formData
                });
                const result = await response.json();
                
                clearInterval(progressInterval);
                document.getElementById('progressFill').style.width = '100%';
                
                setTimeout(() => {
                    if (result.success) {
                        if (result.duplicate_detected) {
                            statusDiv.className = 'status info';
                            statusDiv.innerHTML = `🔄 ${result.message}<br>📄 File hash: ${result.file_hash.substring(0,8)}...`;
                        } else {
                            statusDiv.className = 'status success';
                            statusDiv.innerHTML = `✅ ${result.message}<br>📊 Chunks created: ${result.chunks_created || result.existing_chunks}`;
                        }
                        e.target.reset();
                        throttledUpdate();
                    } else {
                        statusDiv.className = 'status error';
                        if (result.requires_confirmation) {
                            statusDiv.innerHTML = `
                                ⚠️ ${result.error}<br>
                                <small>Existing hash: ${result.existing_hash ? result.existing_hash.substring(0,8) + '...' : 'unknown'}</small><br>
                                <small>New file hash: ${result.new_hash.substring(0,8)}...</small><br>
                                <button onclick="forceReupload()" style="margin-top: 10px; background: #ff6b6b; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;">
                                    🔄 Replace Existing Content
                                </button>
                            `;
                        } else {
                            statusDiv.innerHTML = `❌ Error: ${result.error}`;
                        }
                    }
                    
                    uploadBtn.disabled = false;
                    uploadText.textContent = 'Upload Chapter';
                    uploadInProgress = false;
                    progressBar.style.display = 'none';
                }, 500);
                
            } catch (error) {
                clearInterval(progressInterval);
                statusDiv.className = 'status error';
                statusDiv.innerHTML = `❌ Upload failed: ${error.message}`;
                uploadBtn.disabled = false;
                uploadText.textContent = 'Upload Chapter';
                uploadInProgress = false;
                progressBar.style.display = 'none';
            }
        });
        
        function forceReupload() {
            // Check the force reupload checkbox and trigger form submission
            const forceCheckbox = document.getElementById('forceReupload');
            const statusDiv = document.getElementById('status');
            
            forceCheckbox.checked = true;
            statusDiv.innerHTML = '🔄 Force re-upload enabled. Please submit the form again.';
            statusDiv.className = 'status info';
        }
        
        async function updateChapterStatus() {
            try {
                const response = await fetch('/status');
                const data = await response.json();
                
                // Update stats
                const uploaded = data.uploaded_chapters.length;
                const total = data.total_chapters;
                const statsHtml = `
                    <div class="stat-card">
                        <div class="stat-number">${uploaded}</div>
                        <div class="stat-label">Uploaded Chapters</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number">${total - uploaded}</div>
                        <div class="stat-label">Remaining Chapters</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number">${Math.round((uploaded/total)*100)}%</div>
                        <div class="stat-label">Completion Rate</div>
                    </div>
                `;
                document.getElementById('statsGrid').innerHTML = statsHtml;
                
                // Update chapter grid
                let gridHtml = '';
                for (const [chapterId, info] of Object.entries(chapters)) {
                    const uploaded = data.uploaded_chapters.includes(chapterId);
                    const cardClass = uploaded ? 'uploaded' : 'missing';
                    const statusClass = uploaded ? 'status-uploaded' : 'status-missing';
                    const statusText = uploaded ? '✅ Uploaded' : '⏳ Pending';
                    
                    // Add action buttons for uploaded chapters
                    const actionButtons = uploaded ? `
                        <div style="margin-top: 10px; display: flex; gap: 8px; flex-wrap: wrap;">
                            <button onclick="forceReuploadChapter('${chapterId}')" 
                                    style="background: #ff6b6b; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 12px;">
                                🔄 Force Re-upload
                            </button>
                            <button onclick="regenerateChunks('${chapterId}')" 
                                    style="background: #4ecdc4; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 12px;">
                                🧠 Regenerate Chunks
                            </button>
                            <button onclick="downloadChapter('${chapterId}')" 
                                    style="background: #45b7d1; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 12px;">
                                📥 Download
                            </button>
                        </div>
                    ` : '';
                    
                    gridHtml += `
                        <div class="chapter-card ${cardClass}" id="chapter-${chapterId}">
                            <div class="chapter-title">${info.chapterNumber || info.chapter_number + '. '} ${info.name}</div>
                            <div class="chapter-subtitle">${info.englishName}</div>
                            <span class="chapter-status ${statusClass}">${statusText}</span>
                            ${actionButtons}
                        </div>
                    `;
                }
                document.getElementById('chapterGrid').innerHTML = gridHtml;
                
            } catch (error) {
                console.error('Error updating status:', error);
            }
        }
        
        async function forceReuploadChapter(chapterId) {
            const classLevel = prompt('Enter class level (9 or 10):');
            if (!classLevel || !['9', '10'].includes(classLevel)) {
                alert('Please enter a valid class level (9 or 10)');
                return;
            }
            
            const fileInput = document.createElement('input');
            fileInput.type = 'file';
            fileInput.accept = '.pdf';
            fileInput.onchange = async (e) => {
                const file = e.target.files[0];
                if (!file) return;
                
                if (!confirm(`Are you sure you want to force re-upload ${chapterId} for Class ${classLevel}? This will replace all existing content and chunks.`)) {
                    return;
                }
                
                const formData = new FormData();
                formData.append('file', file);
                
                const statusDiv = document.getElementById('status');
                statusDiv.className = 'status loading';
                statusDiv.style.display = 'block';
                statusDiv.innerHTML = '🔄 Force re-uploading chapter...';
                
                try {
                    const response = await fetch(`/force-reupload/${classLevel}/${chapterId}`, {
                        method: 'POST',
                        body: formData
                    });
                    const result = await response.json();
                    
                    if (result.success) {
                        statusDiv.className = 'status success';
                        statusDiv.innerHTML = `✅ ${result.message}`;
                        throttledUpdate();
                    } else {
                        statusDiv.className = 'status error';
                        statusDiv.innerHTML = `❌ Error: ${result.error}`;
                    }
                } catch (error) {
                    statusDiv.className = 'status error';
                    statusDiv.innerHTML = `❌ Force re-upload failed: ${error.message}`;
                }
            };
            fileInput.click();
        }
        
        async function regenerateChunks(chapterId) {
            const classLevel = prompt('Enter class level (9 or 10):');
            if (!classLevel || !['9', '10'].includes(classLevel)) {
                alert('Please enter a valid class level (9 or 10)');
                return;
            }
            
            if (!confirm(`Regenerate chunks for ${chapterId} (Class ${classLevel})? This will delete existing embeddings and create new ones from the current PDF.`)) {
                return;
            }
            
            const statusDiv = document.getElementById('status');
            statusDiv.className = 'status loading';
            statusDiv.style.display = 'block';
            statusDiv.innerHTML = '🧠 Regenerating chunks and embeddings...';
            
            try {
                const response = await fetch(`/regenerate-chunks/${classLevel}/${chapterId}`, {
                    method: 'POST'
                });
                const result = await response.json();
                
                if (result.success) {
                    statusDiv.className = 'status success';
                    statusDiv.innerHTML = `✅ ${result.message}`;
                } else {
                    statusDiv.className = 'status error';
                    statusDiv.innerHTML = `❌ Error: ${result.error}`;
                }
            } catch (error) {
                statusDiv.className = 'status error';
                statusDiv.innerHTML = `❌ Chunk regeneration failed: ${error.message}`;
            }
        }
        
        async function downloadChapter(chapterId) {
            const classLevel = prompt('Enter class level (9 or 10):');
            if (!classLevel || !['9', '10'].includes(classLevel)) {
                alert('Please enter a valid class level (9 or 10)');
                return;
            }
            
            try {
                const url = `/pdf/${classLevel}/${chapterId}`;
                const link = document.createElement('a');
                link.href = url;
                link.download = `class_${classLevel}_${chapterId}.pdf`;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                
                const statusDiv = document.getElementById('status');
                statusDiv.className = 'status success';
                statusDiv.style.display = 'block';
                statusDiv.innerHTML = `📥 Downloading ${chapterId} for Class ${classLevel}...`;
            } catch (error) {
                const statusDiv = document.getElementById('status');
                statusDiv.className = 'status error';
                statusDiv.style.display = 'block';
                statusDiv.innerHTML = `❌ Download failed: ${error.message}`;
            }
        }
        
        // Initial load
        checkFirebaseStatus();
        updateChapterStatus();
    </script>
</body>
</html>
    """, chapters=dict(sorted(NCTB_CHAPTERS.items(), key=lambda x: x[1]['chapter_number'])))

@app.route('/upload', methods=['POST'])
def upload_chapter():
    """Upload chapter PDF with duplicate detection"""
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file provided'})
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No file selected'})
        
        class_level = int(request.form.get('class_level'))
        chapter_id = request.form.get('chapter_id')
        force_reupload = request.form.get('force_reupload', 'false').lower() == 'true'
        
        result = pdf_manager.upload_chapter_pdf(file, class_level, chapter_id, force_reupload)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Upload error: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/pdf/<int:class_level>/<chapter_id>')
def serve_chapter_pdf(class_level, chapter_id):
    """Serve chapter PDF file"""
    try:
        pdf_path = pdf_manager.get_chapter_pdf(class_level, chapter_id)
        if pdf_path and os.path.exists(pdf_path):
            return send_file(pdf_path, as_attachment=False, mimetype='application/pdf')
        else:
            return jsonify({'error': 'Chapter PDF not found'}), 404
    except Exception as e:
        logger.error(f"Error serving PDF: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/search', methods=['POST'])
def search_content():
    """Search chapter content"""
    try:
        data = request.get_json()
        query = data.get('query', '')
        class_level = data.get('class_level')
        chapter_id = data.get('chapter_id')
        top_k = data.get('top_k', 5)
        
        results = pdf_manager.search_chapter_content(query, class_level, chapter_id, top_k)
        return jsonify({'results': results})
        
    except Exception as e:
        logger.error(f"Search error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/chapters/<int:class_level>')
def get_class_chapters(class_level):
    """Get uploaded chapters for a class with full NCTB chapter information"""
    try:
        chapter_key = f"class_{class_level}"
        uploaded_chapters = pdf_manager.chapter_metadata.get(chapter_key, {})
        
        # Get available chapters for this class level
        available_chapters = get_chapters_for_class(class_level)
        
        # Build response with full chapter information
        chapters_info = {}
        for chapter_id, chapter_info in available_chapters.items():
            chapters_info[chapter_id] = {
                'id': chapter_info['id'],
                'name': chapter_info['name'],
                'englishName': chapter_info['englishName'],
                'chapterNumber': chapter_info['chapterNumber'],
                'chapter_number': chapter_info['chapter_number'],
                'status': 'uploaded' if chapter_id in uploaded_chapters else 'missing',
                'has_embeddings': pdf_manager.check_chapter_exists_in_pinecone(class_level, chapter_id),
                'firebase_available': uploaded_chapters.get(chapter_id, {}).get('firebase_url') is not None,
                'upload_date': uploaded_chapters.get(chapter_id, {}).get('upload_date'),
                'file_hash': uploaded_chapters.get(chapter_id, {}).get('file_hash')
            }
        
        return jsonify({
            'chapters': chapters_info,
            'total_available': len(available_chapters),
            'total_uploaded': len(uploaded_chapters)
        })
    except Exception as e:
        logger.error(f"Error getting chapters: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/chapter/<int:class_level>/<chapter_id>/status', methods=['GET'])
def get_chapter_status(class_level, chapter_id):
    """Get detailed status of a chapter including duplicate information"""
    try:
        chapter_key = f"class_{class_level}"
        metadata = pdf_manager.chapter_metadata.get(chapter_key, {}).get(chapter_id, {})
        
        if not metadata:
            return jsonify({'success': False, 'error': 'Chapter not found'}), 404
        
        # Check Pinecone status
        has_embeddings = pdf_manager.check_chapter_exists_in_pinecone(class_level, chapter_id)
        
        status = {
            'success': True,
            'chapter_id': chapter_id,
            'class_level': class_level,
            'file_hash': metadata.get('file_hash'),
            'upload_date': metadata.get('upload_date'),
            'text_chunks_count': metadata.get('text_chunks_count', 0),
            'has_embeddings': has_embeddings,
            'firebase_url': metadata.get('firebase_url'),
            'local_path_exists': os.path.exists(metadata.get('local_path', '')),
            'chapter_info': metadata.get('chapter_info', {})
        }
        
        return jsonify(status)
    except Exception as e:
        logger.error(f"Error getting chapter status: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/force-reupload/<int:class_level>/<chapter_id>', methods=['POST'])
def force_reupload_with_chunks(class_level, chapter_id):
    """Force re-upload a chapter with complete chunk regeneration"""
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file provided'})
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No file selected'})
        
        # Log the force re-upload action
        logger.info(f"🔄 Force re-upload initiated for Class {class_level} - {chapter_id}")
        
        # Delete existing embeddings first
        logger.info(f"🗑️ Deleting existing embeddings for {chapter_id}")
        pdf_manager.delete_existing_chapter_chunks(class_level, chapter_id)
        
        # Force reupload with new chunks
        result = pdf_manager.upload_chapter_pdf(file, class_level, chapter_id, force_reupload=True)
        
        if result.get('success'):
            result['action'] = 'force_reupload'
            result['message'] = f"✅ Force re-upload completed! Regenerated {result.get('chunks_created', 0)} new chunks"
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Force reupload error: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/regenerate-chunks/<int:class_level>/<chapter_id>', methods=['POST'])
def regenerate_chunks_only(class_level, chapter_id):
    """Regenerate only the embeddings/chunks for existing PDF"""
    try:
        # Check if PDF exists locally
        chapter_key = f"class_{class_level}"
        if chapter_key not in pdf_manager.chapter_metadata or chapter_id not in pdf_manager.chapter_metadata[chapter_key]:
            return jsonify({'success': False, 'error': 'Chapter PDF not found'})
        
        metadata = pdf_manager.chapter_metadata[chapter_key][chapter_id]
        local_path = metadata['local_path']
        
        if not os.path.exists(local_path):
            return jsonify({'success': False, 'error': 'PDF file not found on disk'})
        
        logger.info(f"🔄 Regenerating chunks for Class {class_level} - {chapter_id}")
        
        # Delete existing embeddings
        logger.info(f"🗑️ Deleting existing embeddings")
        pdf_manager.delete_existing_chapter_chunks(class_level, chapter_id)
        
        # Extract text and create new chunks
        text_chunks = pdf_manager.extract_text_chunks(local_path)
        if not text_chunks:
            return jsonify({'success': False, 'error': 'Failed to extract text from existing PDF'})
        
        # Create new embeddings
        if not pdf_manager.create_embeddings(text_chunks, class_level, chapter_id):
            return jsonify({'success': False, 'error': 'Failed to create new embeddings'})
        
        # Update metadata
        pdf_manager.chapter_metadata[chapter_key][chapter_id]['text_chunks_count'] = len(text_chunks)
        pdf_manager.chapter_metadata[chapter_key][chapter_id]['last_chunk_regeneration'] = datetime.now().isoformat()
        pdf_manager._save_metadata()
        
        logger.info(f"✅ Successfully regenerated {len(text_chunks)} chunks for {chapter_id}")
        
        return jsonify({
            'success': True,
            'message': f'Successfully regenerated {len(text_chunks)} chunks',
            'chunks_created': len(text_chunks),
            'action': 'regenerate_chunks'
        })
        
    except Exception as e:
        logger.error(f"Chunk regeneration error: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/chapter/<int:class_level>/<chapter_id>/force-reupload', methods=['POST'])
def force_reupload_chapter(class_level, chapter_id):
    """Force re-upload a chapter (delete existing and upload new)"""
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file provided'})
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No file selected'})
        
        # Force reupload
        result = pdf_manager.upload_chapter_pdf(file, class_level, chapter_id, force_reupload=True)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Force reupload error: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/delete/<int:class_level>/<chapter_id>', methods=['DELETE'])
def delete_chapter(class_level, chapter_id):
    """Delete chapter"""
    try:
        result = pdf_manager.delete_chapter(class_level, chapter_id)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Delete error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/chapter/<int:class_level>/<chapter_id>/firebase_url', methods=['GET'])
def get_chapter_firebase_url(class_level, chapter_id):
    """Get Firebase URL for a specific chapter"""
    try:
        chapter_key = f"class_{class_level}"
        if chapter_key in pdf_manager.chapter_metadata and chapter_id in pdf_manager.chapter_metadata[chapter_key]:
            metadata = pdf_manager.chapter_metadata[chapter_key][chapter_id]
            firebase_url = metadata.get('firebase_url')
            firebase_path = metadata.get('firebase_path')
            
            if firebase_url:
                return jsonify({
                    'success': True,
                    'firebase_url': firebase_url,
                    'firebase_path': firebase_path,
                    'chapter_info': metadata.get('chapter_info', {}),
                    'upload_date': metadata.get('upload_date')
                })
            else:
                return jsonify({
                    'success': False,
                    'error': 'Chapter not uploaded to Firebase'
                }), 404
        else:
            return jsonify({
                'success': False,
                'error': 'Chapter not found'
            }), 404
    except Exception as e:
        logger.error(f"Error getting Firebase URL: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/chapters/firebase_list', methods=['GET'])
def list_firebase_chapters():
    """List all chapters available in Firebase"""
    try:
        firebase_chapters = []
        
        for class_level, chapters in pdf_manager.chapter_metadata.items():
            for chapter_id, metadata in chapters.items():
                if metadata.get('firebase_url'):
                    firebase_chapters.append({
                        'class_level': metadata.get('class_level'),
                        'chapter_id': chapter_id,
                        'chapter_name': metadata.get('chapter_info', {}).get('englishName', chapter_id),
                        'bengali_name': metadata.get('chapter_info', {}).get('name', ''),
                        'firebase_url': metadata.get('firebase_url'),
                        'firebase_path': metadata.get('firebase_path'),
                        'upload_date': metadata.get('upload_date'),
                        'subject': metadata.get('subject', 'Mathematics')
                    })
        
        return jsonify({
            'success': True,
            'chapters': firebase_chapters,
            'total_count': len(firebase_chapters)
        })
    except Exception as e:
        logger.error(f"Error listing Firebase chapters: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/chapters/available/<int:class_level>', methods=['GET'])
def get_available_chapters(class_level):
    """Get available chapters for a class level from Firestore"""
    try:
        if not pdf_manager.db:
            return jsonify({
                'success': False,
                'error': 'Firestore not initialized'
            }), 500
        
        # Query Firestore for available chapters
        chapters_ref = pdf_manager.db.collection('chapters')
        query = chapters_ref.where('class_level', '==', class_level).where('is_available', '==', True)
        docs = query.stream()
        
        available_chapters = []
        for doc in docs:
            chapter_data = doc.to_dict()
            available_chapters.append({
                'id': chapter_data['chapter_id'],
                'name': chapter_data['chapter_name'],
                'englishName': chapter_data['english_name'],
                'chapterNumber': chapter_data['chapter_number'],
                'downloadUrl': chapter_data['download_url'],
                'filename': chapter_data['filename'],
                'subject': chapter_data.get('subject', 'Mathematics'),
                'uploadDate': chapter_data['upload_date'].isoformat() if hasattr(chapter_data['upload_date'], 'isoformat') else str(chapter_data['upload_date']),
                'fileSizeBytes': chapter_data.get('file_size_bytes', 0),
                'textChunksCount': chapter_data.get('text_chunks_count', 0),
                'isAvailable': True
            })
        
        # Sort by chapter number
        available_chapters.sort(key=lambda x: NCTB_CHAPTERS.get(x['id'], {}).get('chapter_number', 999))
        
        return jsonify({
            'success': True,
            'classLevel': class_level,
            'totalChapters': len(available_chapters),
            'chapters': available_chapters
        })
        
    except Exception as e:
        logger.error(f"Error getting available chapters: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/chapter/<int:class_level>/<chapter_id>/download_info', methods=['GET'])
def get_chapter_download_info(class_level, chapter_id):
    """Get download information for a specific chapter"""
    try:
        if not pdf_manager.db:
            return jsonify({
                'success': False,
                'error': 'Firestore not initialized'
            }), 500
        
        doc_id = f"{class_level}_{chapter_id}"
        doc_ref = pdf_manager.db.collection('chapters').document(doc_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return jsonify({
                'success': False,
                'error': 'Chapter not found',
                'available': False
            }), 404
        
        chapter_data = doc.to_dict()
        
        return jsonify({
            'success': True,
            'available': chapter_data.get('is_available', False),
            'chapterId': chapter_data['chapter_id'],
            'classLevel': chapter_data['class_level'],
            'chapterName': chapter_data['chapter_name'],
            'englishName': chapter_data['english_name'],
            'downloadUrl': chapter_data.get('download_url'),
            'filename': chapter_data['filename'],
            'fileSizeBytes': chapter_data.get('file_size_bytes', 0),
            'uploadDate': chapter_data['upload_date'].isoformat() if hasattr(chapter_data['upload_date'], 'isoformat') else str(chapter_data['upload_date'])
        })
        
    except Exception as e:
        logger.error(f"Error getting chapter download info: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/chapters/structure', methods=['GET'])
def get_chapter_structure():
    """Get the complete NCTB chapter structure"""
    try:
        class_9_chapters = get_chapters_for_class(9)
        class_10_chapters = get_chapters_for_class(10)
        
        return jsonify({
            'success': True,
            'nctb_curriculum': {
                'class_9': {
                    'total_chapters': len(class_9_chapters),
                    'chapters': [
                        {
                            'id': chapter_id,
                            'name': info['name'],
                            'englishName': info['englishName'],
                            'chapterNumber': info['chapterNumber']
                        }
                        for chapter_id, info in class_9_chapters.items()
                    ]
                },
                'class_10': {
                    'total_chapters': len(class_10_chapters),
                    'chapters': [
                        {
                            'id': chapter_id,
                            'name': info['name'],
                            'englishName': info['englishName'],
                            'chapterNumber': info['chapterNumber']
                        }
                        for chapter_id, info in class_10_chapters.items()
                    ]
                }
            }
        })
    except Exception as e:
        logger.error(f"Error getting chapter structure: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/status')
def get_status():
    """Get service status"""
    try:
        uploaded_chapters = []
        for class_data in pdf_manager.chapter_metadata.values():
            uploaded_chapters.extend(class_data.keys())
        
        return jsonify({
            'status': 'running',
            'firebase_enabled': pdf_manager.firebase_initialized,
            'pinecone_enabled': pdf_manager.pinecone_client is not None,
            'openai_enabled': pdf_manager.openai_client is not None,
            'uploaded_chapters': uploaded_chapters,
            'total_chapters': len(NCTB_CHAPTERS),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Status error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/status', methods=['GET'])
def api_status():
    """API status endpoint for testing"""
    return jsonify({
        "success": True,
        "message": "Chapter PDF manager is running",
        "endpoints": [
            "/upload_chapter_pdf",
            "/search_chapter_content", 
            "/download_chapter_pdf/<chapter_id>",
            "/check_chapter_availability",
            "/pinecone_status",
            "/test_openai"
        ]
    })

@app.route('/pinecone_status', methods=['GET'])
def pinecone_status():
    """Get Pinecone connection status"""
    try:
        if not pdf_manager.pinecone_client:
            return jsonify({
                "success": False,
                "connected": False,
                "error": "Pinecone not initialized"
            })
        
        # Lightweight status check
        return jsonify({
            "success": True,
            "connected": True,
            "index_name": "nctb-math-chapters",
            "status": "connected"
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "connected": False,
            "error": str(e)
        })

@app.route('/firebase-test-upload', methods=['POST'])
def test_firebase_upload():
    """Test Firebase upload with a small file"""
    try:
        if not pdf_manager.firebase_initialized:
            return jsonify({
                'success': False,
                'error': 'Firebase not initialized',
                'fix_instructions': 'Check Firebase configuration file'
            })
        
        # Create a small test file
        test_content = b"Test Firebase upload for AI Tutor PDF system"
        test_path = "test/firebase_upload_test.txt"
        
        try:
            # Try to upload test file
            blob = pdf_manager.storage_bucket.blob(test_path)
            blob.upload_from_string(test_content, content_type='text/plain')
            blob.make_public()
            
            # Clean up test file
            blob.delete()
            
            return jsonify({
                'success': True,
                'message': 'Firebase upload test successful! Ready for student PDF downloads',
                'permissions_status': 'working',
                'student_ready': True
            })
            
        except Exception as e:
            if "storage.objects.create" in str(e):
                return jsonify({
                    'success': False,
                    'error': 'Insufficient Firebase permissions',
                    'fix_instructions': {
                        'step1': 'Go to Google Cloud Console → IAM & Admin → IAM',
                        'step2': 'Find service account: firebase-adminsdk-fbsvc@ai-tutor-oshan.iam.gserviceaccount.com',
                        'step3': 'Click "Edit" and add role: Storage Object Creator',
                        'step4': 'Add another role: Storage Object Viewer',
                        'step5': 'Save and wait 5-10 minutes'
                    },
                    'console_url': 'https://console.cloud.google.com/iam-admin/iam',
                    'student_ready': False
                })
            else:
                return jsonify({
                    'success': False,
                    'error': str(e),
                    'student_ready': False
                })
                
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'student_ready': False
        })
def firebase_status():
    """Get Firebase connection status and permissions info"""
    try:
        if not pdf_manager.firebase_initialized:
            return jsonify({
                "success": False,
                "connected": False,
                "error": "Firebase not initialized",
                "fix_instructions": "Check Firebase configuration and credentials"
            })
        
        # Test Firebase Storage permissions
        try:
            # Try to access the bucket without uploading
            bucket = pdf_manager.storage_bucket
            bucket_name = bucket.name
            
            # Check if we can list objects (basic permission test)
            try:
                list(bucket.list_blobs(max_results=1))
                can_read = True
            except Exception:
                can_read = False
            
            # Check service account email
            service_account_email = "firebase-adminsdk-fbsvc@ai-tutor-oshan.iam.gserviceaccount.com"
            
            return jsonify({
                "success": True,
                "connected": True,
                "bucket_name": bucket_name,
                "can_read": can_read,
                "service_account": service_account_email,
                "required_roles": [
                    "Storage Object Creator",
                    "Storage Object Viewer"
                ],
                "fix_instructions": {
                    "step1": "Go to Google Cloud Console → IAM & Admin → IAM",
                    "step2": f"Find service account: {service_account_email}",
                    "step3": "Add role: Storage Object Creator",
                    "step4": "Add role: Storage Object Viewer",
                    "step5": "Save and wait 5-10 minutes for propagation"
                },
                "console_url": "https://console.cloud.google.com/iam-admin/iam"
            })
            
        except Exception as storage_error:
            return jsonify({
                "success": False,
                "connected": True,
                "firebase_initialized": True,
                "storage_error": str(storage_error),
                "likely_cause": "Insufficient permissions",
                "fix_instructions": {
                    "issue": "Service account lacks Storage permissions",
                    "solution": "Add 'Storage Object Creator' role in Google Cloud Console IAM"
                }
            })
            
    except Exception as e:
        return jsonify({
            "success": False,
            "connected": False,
            "error": str(e)
        })

@app.route('/test_openai', methods=['POST'])
def test_openai():
    """Test OpenAI embedding creation"""
    try:
        if not pdf_manager.openai_client:
            return jsonify({
                "success": False,
                "error": "OpenAI not initialized"
            })
        
        data = request.get_json()
        text = data.get('text', 'Test embedding')
        
        # Create a test embedding
        response = openai.Embedding.create(
            model="text-embedding-ada-002",
            input=text
        )
        
        embedding = response['data'][0]['embedding']
        
        return jsonify({
            "success": True,
            "embedding_length": len(embedding),
            "model": "text-embedding-ada-002",
            "text_length": len(text)
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        })

if __name__ == '__main__':
    print("🚀 Starting Optimized Chapter PDF Manager...")
    print("📚 Upload individual chapter PDFs for vector search")
    print("🔗 Access the web interface at: http://localhost:5001")
    print("\n⚡ Performance Optimizations:")
    print("  - Limited to 50 pages per PDF")
    print("  - Maximum 50 text chunks per chapter")
    print("  - Batch processing for embeddings")
    print("  - Memory-efficient text extraction")
    print("\n🔧 Environment Variables:")
    print("  - PINECONE_API_KEY: Your Pinecone API key")
    print("  - OPENAI_API_KEY: Your OpenAI API key")
    print("\n📋 Quick Start:")
    print("  1. Upload chapter PDFs via web interface")
    print("  2. PDFs will be processed efficiently")
    print("  3. Use search functionality in your Flutter app")
    
    # Run with optimized settings
    app.run(
        host='0.0.0.0', 
        port=5001, 
        debug=False,  # Disable debug for better performance
        threaded=True,  # Enable threading
        use_reloader=False  # Disable auto-reloader
    )
