#!/usr/bin/env python3
"""
Firestore Integration for NCTB PDF Manager
Optional cloud database integration for chapter configuration
"""

import os
import json
from firebase_admin import firestore
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class FirestoreManager:
    """Manage chapter ranges and configuration in Firestore"""
    
    def __init__(self, firebase_enabled=False):
        self.firebase_enabled = firebase_enabled
        self.db = None
        if firebase_enabled:
            try:
                self.db = firestore.client()
                logger.info("Firestore client initialized")
            except Exception as e:
                logger.error(f"Firestore initialization failed: {e}")
                self.firebase_enabled = False
    
    def save_chapter_ranges(self, class_level, chapter_ranges):
        """Save chapter ranges to Firestore"""
        if not self.firebase_enabled:
            return False
        
        try:
            doc_ref = self.db.collection('nctb_chapters').document(f'class_{class_level}')
            doc_ref.set({
                'chapters': chapter_ranges,
                'updated_at': datetime.now(),
                'class_level': class_level
            })
            logger.info(f"Chapter ranges saved to Firestore for class {class_level}")
            return True
        except Exception as e:
            logger.error(f"Error saving to Firestore: {e}")
            return False
    
    def load_chapter_ranges(self, class_level):
        """Load chapter ranges from Firestore"""
        if not self.firebase_enabled:
            return None
        
        try:
            doc_ref = self.db.collection('nctb_chapters').document(f'class_{class_level}')
            doc = doc_ref.get()
            if doc.exists:
                data = doc.to_dict()
                return data.get('chapters', {})
            return {}
        except Exception as e:
            logger.error(f"Error loading from Firestore: {e}")
            return None
    
    def get_all_chapters(self):
        """Get all chapter configurations from Firestore"""
        if not self.firebase_enabled:
            return {}
        
        try:
            chapters_ref = self.db.collection('nctb_chapters')
            docs = chapters_ref.stream()
            
            all_chapters = {}
            for doc in docs:
                data = doc.to_dict()
                all_chapters[doc.id] = data.get('chapters', {})
            
            return all_chapters
        except Exception as e:
            logger.error(f"Error getting all chapters from Firestore: {e}")
            return {}
    
    def save_pdf_metadata(self, class_level, filename, total_pages, file_size=None):
        """Save PDF metadata to Firestore"""
        if not self.firebase_enabled:
            return False
        
        try:
            doc_ref = self.db.collection('nctb_pdfs').document(f'class_{class_level}')
            doc_ref.set({
                'filename': filename,
                'total_pages': total_pages,
                'file_size': file_size,
                'uploaded_at': datetime.now(),
                'class_level': class_level
            })
            logger.info(f"PDF metadata saved to Firestore: {filename}")
            return True
        except Exception as e:
            logger.error(f"Error saving PDF metadata to Firestore: {e}")
            return False
    
    def get_pdf_metadata(self, class_level):
        """Get PDF metadata from Firestore"""
        if not self.firebase_enabled:
            return None
        
        try:
            doc_ref = self.db.collection('nctb_pdfs').document(f'class_{class_level}')
            doc = doc_ref.get()
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            logger.error(f"Error getting PDF metadata from Firestore: {e}")
            return None


class HybridStorageManager:
    """Hybrid storage manager - uses both local files and Firestore"""
    
    def __init__(self, use_firestore=False):
        self.use_firestore = use_firestore
        self.firestore_manager = FirestoreManager(use_firestore) if use_firestore else None
        self.local_file = 'data/chapter_ranges.json'
    
    def save_chapter_ranges(self, chapter_ranges):
        """Save to both local and Firestore"""
        # Always save locally
        try:
            with open(self.local_file, 'w', encoding='utf-8') as f:
                json.dump(chapter_ranges, f, indent=2, ensure_ascii=False)
            logger.info("Chapter ranges saved locally")
        except Exception as e:
            logger.error(f"Error saving locally: {e}")
        
        # Also save to Firestore if enabled
        if self.use_firestore and self.firestore_manager:
            for class_key, ranges in chapter_ranges.items():
                class_level = class_key.replace('class_', '')
                self.firestore_manager.save_chapter_ranges(class_level, ranges)
    
    def load_chapter_ranges(self):
        """Load from local first, fallback to Firestore"""
        # Try local first
        if os.path.exists(self.local_file):
            try:
                with open(self.local_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Error loading local file: {e}")
        
        # Fallback to Firestore if local fails
        if self.use_firestore and self.firestore_manager:
            try:
                all_chapters = self.firestore_manager.get_all_chapters()
                if all_chapters:
                    # Save locally as backup
                    with open(self.local_file, 'w', encoding='utf-8') as f:
                        json.dump(all_chapters, f, indent=2, ensure_ascii=False)
                    return all_chapters
            except Exception as e:
                logger.error(f"Error loading from Firestore: {e}")
        
        # Default empty structure
        return {'class_9': {}, 'class_10': {}}


# Usage example:
"""
# In pdf_manager.py, replace PDFManager.__init__ with:

def __init__(self, use_firestore=False):
    self.storage_manager = HybridStorageManager(use_firestore)
    self.chapter_ranges = self.storage_manager.load_chapter_ranges()

def save_chapter_ranges(self):
    self.storage_manager.save_chapter_ranges(self.chapter_ranges)
"""
