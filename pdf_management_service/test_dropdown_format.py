#!/usr/bin/env python3
"""
Test script to show dropdown format for NCTB chapters
"""

from chapter_pdf_manager import NCTB_CHAPTERS

def show_dropdown_format():
    """Display how chapters will appear in the dropdown"""
    print("📋 Chapter Dropdown Preview:")
    print("=" * 70)
    
    sample_chapters = [
        'real_numbers', 'sets_functions', 'practical_geometry', 
        'trigonometric_ratios', 'distance_height', 'statistics'
    ]
    
    for chapter_id in sample_chapters:
        chapter = NCTB_CHAPTERS[chapter_id]
        dropdown_text = f"{chapter['chapterNumber']} {chapter['name']} ({chapter['englishName']})"
        print(f"• {dropdown_text}")
    
    print("\n✅ Dropdown format: Bengali Number + Bengali Name + (English Name)")
    print("📝 Example: ৭ম অধ্যায় ব্যবহারিক জ্যামিতি (Practical Geometry)")

if __name__ == '__main__':
    show_dropdown_format()
