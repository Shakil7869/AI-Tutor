#!/usr/bin/env python3
"""
Test script for NCTB RAG Pipeline
Verifies all components are working correctly
"""

import os
import sys
import json
import requests
import time
from pathlib import Path

class RAGTester:
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.timeout = 30
        
    def test_health_check(self):
        """Test if the RAG API server is running"""
        print("🔍 Testing health check...")
        try:
            response = self.session.get(f"{self.base_url}/")
            if response.status_code == 200:
                data = response.json()
                if data.get('rag_initialized'):
                    print("✅ RAG API server is healthy and initialized")
                    return True
                else:
                    print("⚠️  RAG API server is running but not fully initialized")
                    print("   Check your API keys in .env file")
                    return False
            else:
                print(f"❌ Health check failed: {response.status_code}")
                return False
        except requests.exceptions.ConnectionError:
            print("❌ Cannot connect to RAG API server")
            print("   Make sure the server is running on http://localhost:5000")
            return False
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return False
    
    def test_subjects_endpoint(self):
        """Test the subjects listing endpoint"""
        print("🔍 Testing subjects endpoint...")
        try:
            response = self.session.get(f"{self.base_url}/list-subjects")
            if response.status_code == 200:
                data = response.json()
                curriculum = data.get('curriculum', {})
                if curriculum:
                    print("✅ Subjects endpoint working")
                    print(f"   Found curriculum for classes: {list(curriculum.keys())}")
                    return True
                else:
                    print("⚠️  Subjects endpoint returns empty curriculum")
                    return False
            else:
                print(f"❌ Subjects endpoint failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Subjects endpoint error: {e}")
            return False
    
    def test_question_answering(self):
        """Test the question answering without uploaded content"""
        print("🔍 Testing question answering...")
        try:
            test_question = {
                "question": "What is Newton's first law of motion?",
                "class_level": "10",
                "subject": "Physics"
            }
            
            response = self.session.post(
                f"{self.base_url}/ask-question",
                json=test_question
            )
            
            if response.status_code == 200:
                data = response.json()
                answer = data.get('answer', '')
                confidence = data.get('confidence', 0)
                
                if answer:
                    print("✅ Question answering working")
                    print(f"   Answer length: {len(answer)} characters")
                    print(f"   Confidence: {confidence:.2f}")
                    
                    # Check if it's an out-of-syllabus response
                    if "not covered in your" in answer.lower():
                        print("   📝 Response indicates content not in textbook (expected without uploads)")
                    return True
                else:
                    print("⚠️  Question answering returned empty answer")
                    return False
            else:
                print(f"❌ Question answering failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Question answering error: {e}")
            return False
    
    def test_content_search(self):
        """Test content search functionality"""
        print("🔍 Testing content search...")
        try:
            search_query = {
                "query": "motion",
                "class_level": "10",
                "subject": "Physics",
                "top_k": 3
            }
            
            response = self.session.post(
                f"{self.base_url}/search-content",
                json=search_query
            )
            
            if response.status_code == 200:
                data = response.json()
                chunks = data.get('chunks', [])
                print("✅ Content search working")
                print(f"   Found {len(chunks)} relevant chunks")
                return True
            else:
                print(f"❌ Content search failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Content search error: {e}")
            return False
    
    def test_summary_generation(self):
        """Test summary generation"""
        print("🔍 Testing summary generation...")
        try:
            summary_request = {
                "class_level": "10",
                "subject": "Physics",
                "chapter": "Motion"
            }
            
            response = self.session.post(
                f"{self.base_url}/generate-summary",
                json=summary_request
            )
            
            if response.status_code == 200:
                data = response.json()
                summary = data.get('summary', '')
                print("✅ Summary generation working")
                print(f"   Summary length: {len(summary)} characters")
                return True
            else:
                print(f"❌ Summary generation failed: {response.status_code}")
                if response.status_code == 400:
                    print("   This is expected if no content is uploaded for this chapter")
                return False
        except Exception as e:
            print(f"❌ Summary generation error: {e}")
            return False
    
    def test_quiz_generation(self):
        """Test quiz generation"""
        print("🔍 Testing quiz generation...")
        try:
            quiz_request = {
                "class_level": "10",
                "subject": "Physics",
                "chapter": "Motion",
                "mcq_count": 3,
                "short_count": 1
            }
            
            response = self.session.post(
                f"{self.base_url}/generate-quiz",
                json=quiz_request
            )
            
            if response.status_code == 200:
                data = response.json()
                quiz = data.get('quiz', {})
                mcqs = quiz.get('mcqs', [])
                short_questions = quiz.get('short_questions', [])
                
                print("✅ Quiz generation working")
                print(f"   Generated {len(mcqs)} MCQs and {len(short_questions)} short questions")
                return True
            else:
                print(f"❌ Quiz generation failed: {response.status_code}")
                if response.status_code == 400:
                    print("   This is expected if no content is uploaded for this chapter")
                return False
        except Exception as e:
            print(f"❌ Quiz generation error: {e}")
            return False
    
    def check_environment(self):
        """Check environment setup"""
        print("🔍 Checking environment setup...")
        
        # Check .env file
        env_file = Path(".env")
        if env_file.exists():
            print("✅ .env file exists")
            
            # Check for API keys (without revealing them)
            with open(env_file) as f:
                content = f.read()
                
            if "OPENAI_API_KEY=" in content and "your_openai_api_key_here" not in content:
                print("✅ OpenAI API key appears to be set")
            else:
                print("⚠️  OpenAI API key not set in .env file")
                
            if "PINECONE_API_KEY=" in content and "your_pinecone_api_key_here" not in content:
                print("✅ Pinecone API key appears to be set")
            else:
                print("⚠️  Pinecone API key not set in .env file")
        else:
            print("❌ .env file not found")
            
        # Check virtual environment
        venv_path = Path("venv")
        if venv_path.exists():
            print("✅ Virtual environment exists")
        else:
            print("⚠️  Virtual environment not found")
            
        # Check required directories
        required_dirs = ["data", "logs"]
        for directory in required_dirs:
            if Path(directory).exists():
                print(f"✅ {directory}/ directory exists")
            else:
                print(f"⚠️  {directory}/ directory not found")
    
    def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting NCTB RAG Pipeline Tests")
        print("=" * 50)
        
        # Environment checks
        self.check_environment()
        print()
        
        # API tests
        tests = [
            self.test_health_check,
            self.test_subjects_endpoint,
            self.test_question_answering,
            self.test_content_search,
            self.test_summary_generation,
            self.test_quiz_generation,
        ]
        
        passed_tests = 0
        total_tests = len(tests)
        
        for test in tests:
            try:
                if test():
                    passed_tests += 1
                print()
                time.sleep(1)  # Brief pause between tests
            except Exception as e:
                print(f"❌ Test failed with exception: {e}")
                print()
        
        # Results summary
        print("=" * 50)
        print(f"📊 Test Results: {passed_tests}/{total_tests} tests passed")
        
        if passed_tests == total_tests:
            print("🎉 All tests passed! RAG pipeline is working correctly.")
        elif passed_tests >= total_tests - 2:
            print("✅ Most tests passed. Some features may require textbook uploads.")
        else:
            print("⚠️  Several tests failed. Check the setup and configuration.")
            
        print("\n📝 Next Steps:")
        if passed_tests < total_tests:
            print("1. Ensure the RAG API server is running")
            print("2. Check API keys in .env file")
            print("3. Upload some textbook PDFs to test content features")
        else:
            print("1. Upload textbook PDFs via http://localhost:5000/admin/upload-form")
            print("2. Test the Flutter app integration")
            print("3. Try asking questions about uploaded content")

def main():
    """Main test function"""
    # Change to the correct directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Create tester instance
    tester = RAGTester()
    
    # Run all tests
    tester.run_all_tests()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n❌ Tests interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Test runner failed: {e}")
        sys.exit(1)
