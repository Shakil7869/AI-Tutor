#!/usr/bin/env python3
"""
Test script to show sorted dropdown format
"""

from chapter_pdf_manager import NCTB_CHAPTERS

def show_sorted_dropdown():
    """Display how chapters will appear in the dropdown when sorted"""
    print("📋 Sorted Chapter Dropdown Preview:")
    print("=" * 80)
    
    # Sort chapters by chapter_number like in the template
    sorted_chapters = dict(sorted(NCTB_CHAPTERS.items(), key=lambda x: x[1]['chapter_number']))
    
    for i, (chapter_id, chapter) in enumerate(sorted_chapters.items(), 1):
        if 'advanced' not in chapter_id:  # Show Class 9 chapters
            dropdown_text = f"{chapter['chapterNumber']} {chapter['name']} ({chapter['englishName']})"
            print(f"{i:2d}. {dropdown_text}")
    
    print("\n✅ Chapters are now sorted by chapter number in dropdown")
    print("🎯 Format: Bengali Number + Bengali Name + (English Name)")

if __name__ == '__main__':
    show_sorted_dropdown()
