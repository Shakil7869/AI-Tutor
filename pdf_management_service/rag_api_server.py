#!/usr/bin/env python3
"""
RAG API Server for NCTB Textbooks
Flask API for textbook processing and AI question answering
"""

import os
import sys
import json
import logging
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
from werkzeug.utils import secure_filename
import tempfile
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Import our RAG pipeline
from rag_pipeline import RAGPipeline

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flask app setup
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter integration
app.config['MAX_CONTENT_LENGTH'] = 200 * 1024 * 1024  # 200MB max file size

# Global RAG pipeline instance
rag_pipeline = None

def initialize_rag_pipeline():
    """Initialize the RAG pipeline with API keys"""
    global rag_pipeline
    
    # Get API keys from environment variables
    openai_key = os.getenv('OPENAI_API_KEY')
    pinecone_key = os.getenv('PINECONE_API_KEY')
    firebase_cred = os.getenv('FIREBASE_CREDENTIALS_PATH')
    
    if not openai_key or not pinecone_key:
        logger.error("Missing required API keys. Set OPENAI_API_KEY and PINECONE_API_KEY environment variables.")
        return False
    
    try:
        rag_pipeline = RAGPipeline(
            openai_api_key=openai_key,
            pinecone_api_key=pinecone_key,
            firebase_cred_path=firebase_cred
        )
        logger.info("RAG pipeline initialized successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize RAG pipeline: {e}")
        return False

@app.route('/', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'NCTB RAG API',
        'version': '1.0.0',
        'rag_initialized': rag_pipeline is not None
    })

@app.route('/upload-textbook', methods=['POST'])
def upload_textbook():
    """Upload and process a textbook PDF"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Get metadata from form
        class_level = request.form.get('class_level')
        subject = request.form.get('subject')
        chapter_name = request.form.get('chapter_name', None)
        
        if not class_level or not subject:
            return jsonify({'error': 'class_level and subject are required'}), 400
        
        if not rag_pipeline:
            return jsonify({'error': 'RAG pipeline not initialized'}), 500
        
        # Save file temporarily
        filename = secure_filename(file.filename)
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
            file.save(temp_file.name)
            temp_path = temp_file.name
        
        try:
            # Process the textbook
            logger.info(f"Processing textbook: Class {class_level} {subject}")
            chunks = rag_pipeline.process_textbook(
                pdf_path=temp_path,
                class_level=class_level,
                subject=subject,
                chapter_name=chapter_name
            )
            
            # Store in vector database
            pinecone_success = rag_pipeline.store_chunks_in_pinecone(chunks)
            firestore_success = rag_pipeline.store_metadata_in_firestore(chunks)
            
            # Clean up temp file
            os.unlink(temp_path)
            
            return jsonify({
                'status': 'success',
                'message': f'Processed {len(chunks)} chunks from {subject} Class {class_level}',
                'chunks_count': len(chunks),
                'pinecone_stored': pinecone_success,
                'firestore_stored': firestore_success,
                'class_level': class_level,
                'subject': subject,
                'chapter_name': chapter_name
            })
            
        except Exception as e:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            raise e
            
    except Exception as e:
        logger.error(f"Error processing textbook: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/ask-question', methods=['POST'])
def ask_question():
    """Answer a question using RAG pipeline"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        query = data.get('question')
        class_level = data.get('class_level')
        subject = data.get('subject')
        chapter = data.get('chapter')
        
        if not query or not class_level:
            return jsonify({'error': 'question and class_level are required'}), 400
        
        if not rag_pipeline:
            return jsonify({'error': 'RAG pipeline not initialized'}), 500
        
        # Generate RAG response
        response = rag_pipeline.generate_rag_response(
            query=query,
            class_level=class_level,
            subject=subject,
            chapter=chapter
        )
        
        return jsonify({
            'status': 'success',
            'answer': response['answer'],
            'confidence': response['confidence'],
            'source_chunks_count': len(response['source_chunks']),
            'sources': response['source_chunks'],
            'query': query,
            'class_level': class_level,
            'subject': subject,
            'chapter': chapter
        })
        
    except Exception as e:
        logger.error(f"Error generating answer: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/search-content', methods=['POST'])
def search_content():
    """Search for relevant content chunks"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        query = data.get('query')
        class_level = data.get('class_level')
        subject = data.get('subject')
        chapter = data.get('chapter')
        top_k = data.get('top_k', 5)
        
        if not query or not class_level:
            return jsonify({'error': 'query and class_level are required'}), 400
        
        if not rag_pipeline:
            return jsonify({'error': 'RAG pipeline not initialized'}), 500
        
        # Search for relevant chunks
        chunks = rag_pipeline.search_relevant_chunks(
            query=query,
            class_level=class_level,
            subject=subject,
            chapter=chapter,
            top_k=top_k
        )
        
        return jsonify({
            'status': 'success',
            'chunks': chunks,
            'total_found': len(chunks),
            'query': query,
            'class_level': class_level,
            'subject': subject,
            'chapter': chapter
        })
        
    except Exception as e:
        logger.error(f"Error searching content: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/generate-summary', methods=['POST'])
def generate_summary():
    """Generate summary for a chapter"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        class_level = data.get('class_level')
        subject = data.get('subject')
        chapter = data.get('chapter')
        
        if not class_level or not subject or not chapter:
            return jsonify({'error': 'class_level, subject, and chapter are required'}), 400
        
        if not rag_pipeline:
            return jsonify({'error': 'RAG pipeline not initialized'}), 500
        
        # Search for all content in the chapter
        chunks = rag_pipeline.search_relevant_chunks(
            query=chapter,  # Use chapter name as query
            class_level=class_level,
            subject=subject,
            chapter=chapter,
            top_k=20  # Get more chunks for comprehensive summary
        )
        
        if not chunks:
            return jsonify({'error': 'No content found for this chapter'}), 400
        
        # Combine chunk content
        content = "\n\n".join([chunk['text'] for chunk in chunks])
        
        # Generate summary using OpenAI
        summary_prompt = f"""Summarize the following chapter content from Class {class_level} {subject} textbook.
        
Chapter: {chapter}

Content:
{content}

Provide a comprehensive summary that includes:
1. Key concepts and definitions
2. Important formulas or principles
3. Main topics covered
4. Real-world applications mentioned

Keep the summary clear and suitable for Class {class_level} students."""

        response = rag_pipeline.client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are an expert teacher creating chapter summaries for NCTB textbooks."},
                {"role": "user", "content": summary_prompt}
            ],
            max_tokens=1000,
            temperature=0.7
        )
        
        summary = response.choices[0].message.content
        
        return jsonify({
            'status': 'success',
            'summary': summary,
            'chapter': chapter,
            'class_level': class_level,
            'subject': subject,
            'source_chunks': len(chunks)
        })
        
    except Exception as e:
        logger.error(f"Error generating summary: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/generate-quiz', methods=['POST'])
def generate_quiz():
    """Generate quiz questions for a chapter"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        class_level = data.get('class_level')
        subject = data.get('subject')
        chapter = data.get('chapter')
        mcq_count = data.get('mcq_count', 5)
        short_count = data.get('short_count', 2)
        
        if not class_level or not subject or not chapter:
            return jsonify({'error': 'class_level, subject, and chapter are required'}), 400
        
        if not rag_pipeline:
            return jsonify({'error': 'RAG pipeline not initialized'}), 500
        
        # Search for chapter content
        chunks = rag_pipeline.search_relevant_chunks(
            query=chapter,
            class_level=class_level,
            subject=subject,
            chapter=chapter,
            top_k=15
        )
        
        if not chunks:
            return jsonify({'error': 'No content found for this chapter'}), 400
        
        # Combine chunk content
        content = "\n\n".join([chunk['text'] for chunk in chunks])
        
        # Generate quiz using OpenAI
        quiz_prompt = f"""Create a quiz for Class {class_level} {subject} students based on the following chapter content.

Chapter: {chapter}

Content:
{content}

Generate:
1. {mcq_count} multiple choice questions (MCQs) with 4 options each
2. {short_count} short answer questions

Format the response as a JSON object with the following structure:
{{
    "mcqs": [
        {{
            "question": "Question text",
            "options": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
            "correct_answer": "A",
            "explanation": "Why this is correct"
        }}
    ],
    "short_questions": [
        {{
            "question": "Question text",
            "sample_answer": "Sample answer"
        }}
    ]
}}

Make sure questions are:
- Appropriate for Class {class_level} level
- Based on the provided content
- Cover different aspects of the chapter
- Include both conceptual and application-based questions"""

        response = rag_pipeline.client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are an expert teacher creating quizzes for NCTB textbooks. Always respond with valid JSON."},
                {"role": "user", "content": quiz_prompt}
            ],
            max_tokens=2000,
            temperature=0.7
        )
        
        quiz_content = response.choices[0].message.content
        
        # Try to parse as JSON
        try:
            quiz_data = json.loads(quiz_content)
        except json.JSONDecodeError:
            # If JSON parsing fails, create a simple structure
            quiz_data = {
                "mcqs": [],
                "short_questions": [],
                "raw_content": quiz_content
            }
        
        return jsonify({
            'status': 'success',
            'quiz': quiz_data,
            'chapter': chapter,
            'class_level': class_level,
            'subject': subject,
            'source_chunks': len(chunks)
        })
        
    except Exception as e:
        logger.error(f"Error generating quiz: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/list-subjects', methods=['GET'])
def list_subjects():
    """List available subjects for each class"""
    if not rag_pipeline:
        return jsonify({'error': 'RAG pipeline not initialized'}), 500
    
    return jsonify({
        'status': 'success',
        'curriculum': rag_pipeline.curriculum_structure
    })

@app.route('/admin/upload-form', methods=['GET'])
def upload_form():
    """Simple HTML form for testing textbook uploads"""
    form_html = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>NCTB Textbook Upload</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .form-group { margin: 15px 0; }
            label { display: block; margin-bottom: 5px; font-weight: bold; }
            input, select, textarea { width: 300px; padding: 8px; }
            button { background: #007cba; color: white; padding: 10px 20px; border: none; cursor: pointer; }
            button:hover { background: #005a87; }
        </style>
    </head>
    <body>
        <h1>NCTB Textbook Upload</h1>
        
        <form action="/upload-textbook" method="post" enctype="multipart/form-data">
            <div class="form-group">
                <label for="file">Select PDF File:</label>
                <input type="file" id="file" name="file" accept=".pdf" required>
            </div>
            
            <div class="form-group">
                <label for="class_level">Class Level:</label>
                <select id="class_level" name="class_level" required>
                    <option value="">Select Class</option>
                    <option value="9">Class 9</option>
                    <option value="10">Class 10</option>
                    <option value="11">Class 11</option>
                    <option value="12">Class 12</option>
                </select>
            </div>
            
            <div class="form-group">
                <label for="subject">Subject:</label>
                <select id="subject" name="subject" required>
                    <option value="">Select Subject</option>
                    <option value="Physics">Physics</option>
                    <option value="Chemistry">Chemistry</option>
                    <option value="Biology">Biology</option>
                    <option value="Mathematics">Mathematics</option>
                </select>
            </div>
            
            <div class="form-group">
                <label for="chapter_name">Chapter Name (Optional):</label>
                <input type="text" id="chapter_name" name="chapter_name" placeholder="Leave empty for auto-detection">
            </div>
            
            <button type="submit">Upload and Process</button>
        </form>
        
        <h2>Test Question Answering</h2>
        <form action="/ask-question" method="post" onsubmit="askQuestion(event)">
            <div class="form-group">
                <label for="question">Question:</label>
                <textarea id="question" rows="3" placeholder="Enter your question here..."></textarea>
            </div>
            
            <div class="form-group">
                <label for="test_class">Class Level:</label>
                <select id="test_class">
                    <option value="9">Class 9</option>
                    <option value="10">Class 10</option>
                    <option value="11">Class 11</option>
                    <option value="12">Class 12</option>
                </select>
            </div>
            
            <div class="form-group">
                <label for="test_subject">Subject:</label>
                <select id="test_subject">
                    <option value="">Any Subject</option>
                    <option value="Physics">Physics</option>
                    <option value="Chemistry">Chemistry</option>
                    <option value="Biology">Biology</option>
                    <option value="Mathematics">Mathematics</option>
                </select>
            </div>
            
            <button type="button" onclick="askQuestion()">Ask Question</button>
        </form>
        
        <div id="answer" style="margin-top: 20px; padding: 15px; background: #f5f5f5; display: none;">
            <h3>Answer:</h3>
            <div id="answer-content"></div>
        </div>
        
        <script>
        async function askQuestion() {
            const question = document.getElementById('question').value;
            const classLevel = document.getElementById('test_class').value;
            const subject = document.getElementById('test_subject').value;
            
            if (!question) {
                alert('Please enter a question');
                return;
            }
            
            try {
                const response = await fetch('/ask-question', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        question: question,
                        class_level: classLevel,
                        subject: subject || undefined
                    })
                });
                
                const data = await response.json();
                
                if (data.status === 'success') {
                    document.getElementById('answer-content').innerHTML = '<p>' + data.answer.replace(/\\n/g, '<br>') + '</p>';
                    document.getElementById('answer').style.display = 'block';
                } else {
                    alert('Error: ' + data.error);
                }
            } catch (error) {
                alert('Error: ' + error.message);
            }
        }
        </script>
    </body>
    </html>
    '''
    return form_html

if __name__ == '__main__':
    # Initialize RAG pipeline on startup
    if initialize_rag_pipeline():
        logger.info("Starting RAG API server...")
        app.run(host='0.0.0.0', port=5000, debug=True)
    else:
        logger.error("Failed to initialize RAG pipeline. Exiting.")
        sys.exit(1)
