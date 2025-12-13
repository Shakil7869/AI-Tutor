#!/usr/bin/env python3
"""
RAG Pipeline for NCTB Textbooks - Classes 9-12
Handles PDF processing, chunking, embeddings, and vector storage
"""

import os
import sys
import json
import logging
import re
import hashlib
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
import fitz  # PyMuPDF
import openai
from pinecone import Pinecone, ServerlessSpec
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
import nltk
from nltk.tokenize import sent_tokenize
import tiktoken
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Download required NLTK data
try:
    nltk.data.find('tokenizers/punkt')
except LookupError:
    nltk.download('punkt')

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class ChunkMetadata:
    """Metadata for text chunks"""
    class_level: str
    subject: str
    chapter: str
    chunk_id: str
    chapter_number: int
    page_number: int
    word_count: int
    created_at: str

@dataclass
class TextChunk:
    """Text chunk with metadata"""
    text: str
    metadata: ChunkMetadata
    embedding: Optional[List[float]] = None

class RAGPipeline:
    """Complete RAG pipeline for NCTB textbooks"""
    
    def __init__(self, openai_api_key: str, pinecone_api_key: str, firebase_cred_path: str = None):
        self.openai_api_key = openai_api_key
        self.pinecone_api_key = pinecone_api_key
        
        # Initialize OpenAI
        openai.api_key = openai_api_key
        self.client = openai.OpenAI(api_key=openai_api_key)
        
        # Initialize tokenizer for counting tokens
        self.encoding = tiktoken.get_encoding("cl100k_base")
        
        # Initialize Pinecone
        self.pc = Pinecone(api_key=pinecone_api_key)
        self.index_name = "nctb-textbooks"
        self._setup_pinecone_index()
        
        # Initialize Firebase if credentials provided
        self.firestore_db = None
        if firebase_cred_path and os.path.exists(firebase_cred_path):
            self._setup_firebase(firebase_cred_path)
        
        # NCTB curriculum structure
        self.curriculum_structure = {
            '9': {
                'Physics': ['Motion', 'Force and Pressure', 'Work, Power and Energy', 'Sound', 'Light'],
                'Chemistry': ['Matter and Its States', 'Elements and Compounds', 'Acids, Bases and Salts', 'Chemical Reactions'],
                'Biology': ['Cell and Its Structure', 'Life Process', 'Reproduction', 'Heredity and Evolution'],
                'Mathematics': ['Real Numbers', 'Sets and Functions', 'Algebraic Expressions', 'Indices and Logarithms', 'Linear Equations']
            },
            '10': {
                'Physics': ['Heat and Temperature', 'Waves and Sound', 'Light and Optics', 'Electricity and Magnetism', 'Modern Physics'],
                'Chemistry': ['Atomic Structure', 'Periodic Table', 'Chemical Bonding', 'Metals and Non-metals', 'Organic Chemistry'],
                'Biology': ['Nutrition', 'Respiration', 'Transportation', 'Excretion', 'Control and Coordination'],
                'Mathematics': ['Trigonometry', 'Geometry', 'Coordinate Geometry', 'Statistics', 'Probability']
            },
            '11': {
                'Physics': ['Mechanics', 'Thermal Physics', 'Waves', 'Electricity', 'Magnetism'],
                'Chemistry': ['General Chemistry', 'Organic Chemistry', 'Physical Chemistry', 'Inorganic Chemistry'],
                'Biology': ['Cell Biology', 'Plant Biology', 'Animal Biology', 'Human Biology', 'Ecology'],
                'Mathematics': ['Calculus', 'Algebra', 'Geometry', 'Trigonometry', 'Statistics']
            },
            '12': {
                'Physics': ['Advanced Mechanics', 'Thermodynamics', 'Electromagnetic Waves', 'Modern Physics', 'Electronics'],
                'Chemistry': ['Advanced Organic Chemistry', 'Physical Chemistry', 'Inorganic Chemistry', 'Environmental Chemistry'],
                'Biology': ['Advanced Cell Biology', 'Genetics', 'Evolution', 'Biotechnology', 'Environmental Biology'],
                'Mathematics': ['Advanced Calculus', 'Linear Algebra', 'Differential Equations', 'Probability', 'Statistics']
            }
        }
    
    def _setup_pinecone_index(self):
        """Setup Pinecone vector database index"""
        try:
            # Check if index exists
            existing_indexes = self.pc.list_indexes()
            if self.index_name not in [idx.name for idx in existing_indexes]:
                # Create index with 1536 dimensions for text-embedding-3-large
                self.pc.create_index(
                    name=self.index_name,
                    dimension=1536,
                    metric='cosine',
                    spec=ServerlessSpec(
                        cloud='aws',
                        region='us-east-1'
                    )
                )
                logger.info(f"Created Pinecone index: {self.index_name}")
            else:
                logger.info(f"Using existing Pinecone index: {self.index_name}")
            
            # Get index reference
            self.index = self.pc.Index(self.index_name)
            
        except Exception as e:
            logger.error(f"Failed to setup Pinecone index: {e}")
            raise
    
    def _setup_firebase(self, cred_path: str):
        """Setup Firebase Firestore"""
        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            
            self.firestore_db = firestore.client()
            logger.info("Firebase Firestore initialized")
            
        except Exception as e:
            logger.error(f"Failed to setup Firebase: {e}")
            self.firestore_db = None
    
    def extract_text_from_pdf(self, pdf_path: str) -> Tuple[str, List[Dict]]:
        """Extract clean text from PDF with page information"""
        try:
            doc = fitz.open(pdf_path)
            full_text = ""
            page_info = []
            
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)
                text = page.get_text()
                
                # Clean the text
                cleaned_text = self._clean_text(text)
                
                if cleaned_text.strip():
                    page_info.append({
                        'page_number': page_num + 1,
                        'text': cleaned_text,
                        'word_count': len(cleaned_text.split())
                    })
                    full_text += cleaned_text + "\n\n"
            
            doc.close()
            logger.info(f"Extracted text from {len(doc)} pages")
            return full_text, page_info
            
        except Exception as e:
            logger.error(f"Error extracting text from PDF: {e}")
            raise
    
    def _clean_text(self, text: str) -> str:
        """Clean extracted text by removing page numbers, extra spaces, etc."""
        # Remove page numbers (common patterns)
        text = re.sub(r'\n\d+\n', '\n', text)
        text = re.sub(r'Page \d+', '', text)
        text = re.sub(r'পৃষ্ঠা \d+', '', text)
        
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'\n\s*\n', '\n\n', text)
        
        # Remove special characters that might interfere
        text = re.sub(r'[^\w\s\.\,\;\:\!\?\(\)\[\]\{\}\-\+\=\*\/\%\@\#\$\&\'\"\`\~\n\r\u0980-\u09FF]', '', text)
        
        return text.strip()
    
    def detect_chapters(self, text: str, subject: str = None) -> List[Dict]:
        """Detect chapter boundaries from text using common heading patterns"""
        chapters = []
        
        # Bengali chapter patterns
        bengali_patterns = [
            r'অধ্যায়\s*[০-৯]+',  # Chapter in Bengali numerals
            r'পাঠ\s*[০-৯]+',      # Lesson in Bengali numerals
            r'অধ্যায়\s*\d+',     # Chapter with English numerals
        ]
        
        # English chapter patterns
        english_patterns = [
            r'Chapter\s+\d+',
            r'CHAPTER\s+\d+',
            r'Unit\s+\d+',
            r'Lesson\s+\d+',
        ]
        
        all_patterns = bengali_patterns + english_patterns
        
        # Find all chapter headings
        chapter_matches = []
        for pattern in all_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                chapter_matches.append({
                    'start': match.start(),
                    'end': match.end(),
                    'text': match.group(),
                    'full_line': text[max(0, match.start()-50):match.end()+100].split('\n')[0]
                })
        
        # Sort by position in text
        chapter_matches.sort(key=lambda x: x['start'])
        
        # If no chapters detected, treat entire text as one chapter
        if not chapter_matches:
            return [{
                'title': f"{subject} - Complete Text" if subject else "Complete Text",
                'start_pos': 0,
                'end_pos': len(text),
                'content': text
            }]
        
        # Extract chapter content
        for i, match in enumerate(chapter_matches):
            start_pos = match['start']
            end_pos = chapter_matches[i + 1]['start'] if i + 1 < len(chapter_matches) else len(text)
            
            content = text[start_pos:end_pos].strip()
            
            chapters.append({
                'title': match['full_line'].strip(),
                'start_pos': start_pos,
                'end_pos': end_pos,
                'content': content
            })
        
        return chapters
    
    def chunk_text(self, text: str, min_chunk_size: int = 300, max_chunk_size: int = 800) -> List[str]:
        """Split text into chunks while preserving sentence boundaries"""
        sentences = sent_tokenize(text)
        chunks = []
        current_chunk = ""
        
        for sentence in sentences:
            # Check if adding this sentence would exceed max chunk size
            potential_chunk = current_chunk + " " + sentence if current_chunk else sentence
            
            # Count words
            word_count = len(potential_chunk.split())
            
            if word_count <= max_chunk_size:
                current_chunk = potential_chunk
            else:
                # If current chunk is above minimum size, save it
                if len(current_chunk.split()) >= min_chunk_size:
                    chunks.append(current_chunk.strip())
                    current_chunk = sentence
                else:
                    # If current chunk is too small, continue adding
                    current_chunk = potential_chunk
                    # But if it's getting too large, force split
                    if word_count > max_chunk_size * 1.5:
                        chunks.append(current_chunk.strip())
                        current_chunk = ""
        
        # Add the last chunk if it exists and meets minimum size
        if current_chunk and len(current_chunk.split()) >= min_chunk_size:
            chunks.append(current_chunk.strip())
        elif current_chunk and chunks:
            # Append to last chunk if too small
            chunks[-1] += " " + current_chunk
        
        return chunks
    
    def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding using OpenAI's text-embedding-3-large"""
        try:
            response = self.client.embeddings.create(
                model="text-embedding-3-large",
                input=text
            )
            return response.data[0].embedding
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            raise
    
    def process_textbook(self, pdf_path: str, class_level: str, subject: str, 
                        chapter_name: str = None) -> List[TextChunk]:
        """Process a complete textbook PDF and return chunks with embeddings"""
        logger.info(f"Processing textbook: Class {class_level} {subject}")
        
        # Extract text from PDF
        full_text, page_info = self.extract_text_from_pdf(pdf_path)
        
        # Detect chapters if chapter_name not provided
        if chapter_name:
            chapters = [{
                'title': chapter_name,
                'start_pos': 0,
                'end_pos': len(full_text),
                'content': full_text
            }]
        else:
            chapters = self.detect_chapters(full_text, subject)
        
        all_chunks = []
        
        for chapter_idx, chapter in enumerate(chapters):
            logger.info(f"Processing chapter: {chapter['title']}")
            
            # Chunk the chapter content
            chunks = self.chunk_text(chapter['content'])
            
            for chunk_idx, chunk_text in enumerate(chunks):
                # Generate chunk ID
                chunk_id = f"{class_level}-{subject.lower()}-{chapter_idx+1}-{chunk_idx+1:03d}"
                
                # Create metadata
                metadata = ChunkMetadata(
                    class_level=class_level,
                    subject=subject,
                    chapter=chapter['title'],
                    chunk_id=chunk_id,
                    chapter_number=chapter_idx + 1,
                    page_number=self._estimate_page_number(chapter['start_pos'], page_info),
                    word_count=len(chunk_text.split()),
                    created_at=datetime.now().isoformat()
                )
                
                # Generate embedding
                embedding = self.generate_embedding(chunk_text)
                
                # Create chunk object
                chunk = TextChunk(
                    text=chunk_text,
                    metadata=metadata,
                    embedding=embedding
                )
                
                all_chunks.append(chunk)
        
        logger.info(f"Generated {len(all_chunks)} chunks for {subject} Class {class_level}")
        return all_chunks
    
    def _estimate_page_number(self, text_position: int, page_info: List[Dict]) -> int:
        """Estimate page number based on text position"""
        char_count = 0
        for page in page_info:
            char_count += len(page['text'])
            if char_count >= text_position:
                return page['page_number']
        return page_info[-1]['page_number'] if page_info else 1
    
    def store_chunks_in_pinecone(self, chunks: List[TextChunk]) -> bool:
        """Store chunks and embeddings in Pinecone vector database"""
        try:
            # Prepare vectors for Pinecone
            vectors = []
            for chunk in chunks:
                vector = {
                    'id': chunk.metadata.chunk_id,
                    'values': chunk.embedding,
                    'metadata': {
                        'class_level': chunk.metadata.class_level,
                        'subject': chunk.metadata.subject,
                        'chapter': chunk.metadata.chapter,
                        'chapter_number': chunk.metadata.chapter_number,
                        'page_number': chunk.metadata.page_number,
                        'word_count': chunk.metadata.word_count,
                        'text': chunk.text[:1000],  # Store truncated text in metadata
                        'created_at': chunk.metadata.created_at
                    }
                }
                vectors.append(vector)
            
            # Batch upload to Pinecone
            batch_size = 100
            for i in range(0, len(vectors), batch_size):
                batch = vectors[i:i + batch_size]
                self.index.upsert(vectors=batch)
                logger.info(f"Uploaded batch {i//batch_size + 1}/{(len(vectors)-1)//batch_size + 1}")
            
            logger.info(f"Successfully stored {len(chunks)} chunks in Pinecone")
            return True
            
        except Exception as e:
            logger.error(f"Error storing chunks in Pinecone: {e}")
            return False
    
    def store_metadata_in_firestore(self, chunks: List[TextChunk]) -> bool:
        """Store detailed metadata in Firestore"""
        if not self.firestore_db:
            logger.warning("Firestore not available, skipping metadata storage")
            return False
        
        try:
            batch = self.firestore_db.batch()
            
            for chunk in chunks:
                doc_ref = self.firestore_db.collection('textbook_chunks').document(chunk.metadata.chunk_id)
                chunk_data = {
                    'chunk_id': chunk.metadata.chunk_id,
                    'class_level': chunk.metadata.class_level,
                    'subject': chunk.metadata.subject,
                    'chapter': chunk.metadata.chapter,
                    'chapter_number': chunk.metadata.chapter_number,
                    'page_number': chunk.metadata.page_number,
                    'word_count': chunk.metadata.word_count,
                    'text': chunk.text,
                    'created_at': chunk.metadata.created_at,
                    'text_hash': hashlib.md5(chunk.text.encode()).hexdigest()
                }
                batch.set(doc_ref, chunk_data)
            
            batch.commit()
            logger.info(f"Successfully stored {len(chunks)} chunk metadata in Firestore")
            return True
            
        except Exception as e:
            logger.error(f"Error storing metadata in Firestore: {e}")
            return False
    
    def search_relevant_chunks(self, query: str, class_level: str, subject: str = None, 
                             chapter: str = None, top_k: int = 5) -> List[Dict]:
        """Search for relevant chunks using vector similarity"""
        try:
            # Generate query embedding
            query_embedding = self.generate_embedding(query)
            
            # Build filter
            filter_dict = {'class_level': class_level}
            if subject:
                filter_dict['subject'] = subject
            if chapter:
                filter_dict['chapter'] = chapter
            
            # Search in Pinecone
            results = self.index.query(
                vector=query_embedding,
                top_k=top_k,
                include_metadata=True,
                filter=filter_dict
            )
            
            # Format results
            relevant_chunks = []
            for match in results['matches']:
                chunk_info = {
                    'chunk_id': match['id'],
                    'score': float(match['score']),
                    'text': match['metadata']['text'],
                    'class_level': match['metadata']['class_level'],
                    'subject': match['metadata']['subject'],
                    'chapter': match['metadata']['chapter'],
                    'page_number': match['metadata']['page_number'],
                    'word_count': match['metadata']['word_count']
                }
                relevant_chunks.append(chunk_info)
            
            logger.info(f"Found {len(relevant_chunks)} relevant chunks for query")
            return relevant_chunks
            
        except Exception as e:
            logger.error(f"Error searching chunks: {e}")
            return []
    
    def generate_rag_response(self, query: str, class_level: str, subject: str = None, 
                            chapter: str = None) -> Dict:
        """Generate AI response using retrieved chunks (RAG)"""
        try:
            # Retrieve relevant chunks
            relevant_chunks = self.search_relevant_chunks(
                query=query,
                class_level=class_level,
                subject=subject,
                chapter=chapter,
                top_k=5
            )
            
            if not relevant_chunks:
                return {
                    'answer': f"This topic is not covered in your Class {class_level} {subject} book. Do you want me to explain from general knowledge?",
                    'source_chunks': [],
                    'confidence': 0.0
                }
            
            # Combine relevant chunks
            context = "\n\n".join([chunk['text'] for chunk in relevant_chunks])
            
            # Create system prompt
            system_prompt = f"""You are an expert AI tutor for Bangladeshi students following NCTB curriculum.
You are helping a Class {class_level} student with {subject or 'their studies'}.

Use the following textbook content to answer the student's question:

{context}

Instructions:
1. Answer based ONLY on the provided textbook content
2. Provide step-by-step explanations
3. Use examples from the textbook when available
4. Explain in both Bengali and English when helpful
5. If the content doesn't fully answer the question, say so clearly
6. Keep explanations clear and age-appropriate for Class {class_level} students
"""
            
            # Generate response
            response = self.client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": query}
                ],
                max_tokens=1500,
                temperature=0.7
            )
            
            answer = response.choices[0].message.content
            
            # Calculate confidence based on chunk scores
            avg_score = sum(chunk['score'] for chunk in relevant_chunks) / len(relevant_chunks)
            
            return {
                'answer': answer,
                'source_chunks': relevant_chunks,
                'confidence': float(avg_score),
                'context_used': len(relevant_chunks)
            }
            
        except Exception as e:
            logger.error(f"Error generating RAG response: {e}")
            return {
                'answer': "I'm sorry, I encountered an error while processing your question. Please try again.",
                'source_chunks': [],
                'confidence': 0.0
            }

if __name__ == "__main__":
    # Example usage
    rag = RAGPipeline(
        openai_api_key="your-openai-key",
        pinecone_api_key="your-pinecone-key",
        firebase_cred_path="path/to/firebase-creds.json"
    )
    
    # Process a textbook
    # chunks = rag.process_textbook("physics_class_10.pdf", "10", "Physics")
    # rag.store_chunks_in_pinecone(chunks)
    # rag.store_metadata_in_firestore(chunks)
    
    # Search and generate response
    # response = rag.generate_rag_response("What is Newton's first law?", "10", "Physics")
    # print(response['answer'])
