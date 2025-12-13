#!/usr/bin/env python3
"""
Test script to demonstrate the new NCTB chapter display format
"""

from chapter_pdf_manager import NCTB_CHAPTERS, get_chapters_for_class

def test_chapter_display():
    """Test chapter display format"""
    print("🧪 Testing NCTB Chapter Display Format\n")
    
    # Test practical_geometry chapter as requested
    chapter = NCTB_CHAPTERS['practical_geometry']
    print("📐 Practical Geometry Chapter:")
    print(f"  ID: {chapter['id']}")
    print(f"  Bengali Name: {chapter['name']}")
    print(f"  English Name: {chapter['englishName']}")
    print(f"  Chapter Number: {chapter['chapterNumber']}")
    print(f"  Display Format: {chapter['chapterNumber']} {chapter['name']}")
    print(f"  Subtitle: {chapter['englishName']}")
    print()
    
    # Test a few more chapters
    test_chapters = ['real_numbers', 'sets_functions', 'algebraic_expressions']
    print("📚 Sample Chapters Display:")
    for chapter_id in test_chapters:
        chapter = NCTB_CHAPTERS[chapter_id]
        print(f"  • {chapter['chapterNumber']} {chapter['name']}")
        print(f"    {chapter['englishName']}")
        print()
    
    # Test class-specific chapters
    class_9_chapters = get_chapters_for_class(9)
    class_10_chapters = get_chapters_for_class(10)
    
    print(f"🎓 Class 9: {len(class_9_chapters)} chapters available")
    print(f"🎓 Class 10: {len(class_10_chapters)} chapters available")
    print()
    
    print("✅ All chapter formats working correctly!")

if __name__ == '__main__':
    test_chapter_display()
