# NCTB Curriculum Integration Guide

## Overview
This AI Tutor app has been specifically designed for Bangladeshi students following the **National Curriculum and Textbook Board (NCTB)** mathematics curriculum for Classes 9-10.

## NCTB Mathematics Chapters (Class 9-10)

### Complete Chapter List
The app now includes all 17 chapters from the NCTB mathematics curriculum:

1. **বাস্তব সংখ্যা** (Real Numbers) - Chapter 1
2. **সেট ও ফাংশন** (Sets and Functions) - Chapter 2  
3. **বীজগাণিতিক রাশি** (Algebraic Expressions) - Chapter 3
4. **সূচক ও লগারিদম** (Indices and Logarithms) - Chapter 4
5. **এক চলকবিশিষ্ট সমীকরণ** (Linear Equations in One Variable) - Chapter 5
6. **রেখা, কোণ ও ত্রিভুজ** (Lines, Angles and Triangles) - Chapter 6
7. **ব্যবহারিক জ্যামিতি** (Practical Geometry) - Chapter 7
8. **বৃত্ত** (Circles) - Chapter 8
9. **ত্রিকোণমিতিক অনুপাত** (Trigonometric Ratios) - Chapter 9
10. **দূরত্ব ও উচ্চতা** (Distance and Height) - Chapter 10
11. **বীজগাণিতিক অনুপাত ও সমানুপাত** (Algebraic Ratios and Proportions) - Chapter 11
12. **দুই চলকবিশিষ্ট সরল সহসমীকরণ** (Simultaneous Linear Equations) - Chapter 12
13. **সসীম ধারা** (Finite Series) - Chapter 13
14. **অনুপাত, সদৃশতা ও প্রতিসমতা** (Ratio, Similarity and Symmetry) - Chapter 14
15. **ক্ষেত্রফল সম্পর্কিত উপপাদ্য ও সম্পাদ্য** (Area Related Theorems) - Chapter 15
16. **পরিমিতি** (Mensuration) - Chapter 16
17. **পরিসংখ্যান** (Statistics) - Chapter 17

## Key Features

### 1. Bilingual Support
- **Bengali (বাংলা)**: Chapter names and descriptions in Bengali
- **English**: English translations for better understanding
- **Mixed Context**: AI can explain concepts using both languages

### 2. NCTB-Specific AI Tutor
The AI tutor has been enhanced with:
- **NCTB Curriculum Context**: Understands the specific syllabus structure
- **Chapter-Specific Prompts**: Tailored explanations for each chapter
- **Bangladeshi Context**: Uses examples relevant to Bangladeshi students
- **Cultural Awareness**: References familiar scenarios and contexts

### 3. User Interface Updates
- **Bengali Text**: Subject names displayed in Bengali with English translations
- **NCTB Branding**: Clear indication of NCTB curriculum compliance
- **Class-Specific Content**: Different content for Class 9 and 10 students

## Technical Implementation

### Files Modified/Created:

1. **`lib/src/core/config/nctb_curriculum.dart`** (NEW)
   - Complete NCTB curriculum data structure
   - Chapter information with Bengali and English names
   - Topic breakdowns for each chapter
   - Utility methods for accessing curriculum data

2. **`lib/src/shared/services/ai_service.dart`** (UPDATED)
   - NCTB-aware AI prompts
   - Chapter-specific system prompts
   - Bengali-English bilingual context
   - Class level integration

3. **`lib/src/features/subjects/presentation/screens/chapter_list_screen.dart`** (UPDATED)
   - Displays NCTB chapters with Bengali names
   - Shows chapter numbers (১ম অধ্যায়, ২য় অধ্যায়, etc.)
   - Enhanced UI with better styling

4. **UI Screen Updates:**
   - Dashboard: Bengali subject names
   - Subject List: NCTB curriculum description
   - Learn Mode: Class level passed to AI service

### Key Classes and Methods:

```dart
// Get chapters for a specific class
List<Map<String, dynamic>> chapters = NCTBCurriculum.getChaptersForClass(9);

// Get chapter by ID
Map<String, dynamic>? chapter = NCTBCurriculum.getChapterById('real_numbers', 9);

// Get topics for a chapter
List<String> topics = NCTBCurriculum.getTopicsForChapter('real_numbers', 9);
```

## AI Tutor Enhancements

### Chapter-Specific Prompts
Each chapter has a specialized AI prompt that includes:
- **NCTB Context**: Reference to specific chapter and syllabus
- **Bengali Terms**: Mathematical terminology in Bengali
- **Local Examples**: Bangladesh-relevant problem scenarios
- **Cultural Sensitivity**: Understanding of local educational context

### Example AI Prompt (Real Numbers):
```
You are an expert math tutor specializing in Real Numbers (বাস্তব সংখ্যা) 
for Class 9-10 Bangladeshi students following NCTB curriculum.

NCTB Context:
- Chapter: বাস্তব সংখ্যা (Real Numbers)
- Chapter Number: ১ম অধ্যায়
- Topics: প্রাকৃতিক সংখ্যা, পূর্ণ সংখ্যা, মূলদ সংখ্যা, অমূলদ সংখ্যা, বাস্তব সংখ্যার বৈশিষ্ট্য
```

## Benefits for Bangladeshi Students

1. **Familiar Content**: Follows exact NCTB curriculum structure
2. **Language Support**: Bengali mathematical terms alongside English
3. **Cultural Context**: Examples and scenarios relevant to Bangladesh
4. **Curriculum Alignment**: Perfect match with textbook chapters
5. **Progressive Learning**: Proper chapter sequence as per NCTB guidelines

## Usage Instructions

### For Students:
1. Select your class level (9 or 10)
2. Browse chapters in Bengali and English
3. Click on any chapter to start learning
4. Ask questions in English or Bengali
5. Get explanations tailored to NCTB curriculum

### For Teachers:
1. Use as supplementary teaching aid
2. Reference NCTB-aligned content
3. Students get consistent curriculum-based answers
4. Track student progress through NCTB chapters

## Future Enhancements

1. **More Subjects**: Physics, Chemistry, Biology with NCTB curriculum
2. **Bengali Interface**: Complete app translation to Bengali
3. **Exam Preparation**: NCTB board exam specific questions
4. **Class-Specific Variations**: Different complexity for Class 9 vs 10
5. **Assessment Tools**: NCTB-style question generation

## Testing and Validation

- ✅ App builds successfully with NCTB integration
- ✅ All 17 chapters properly configured
- ✅ AI service enhanced with NCTB context
- ✅ Bengali text displays correctly
- ✅ Chapter navigation works smoothly
- ✅ AI responses include NCTB-specific context

## Deployment Notes

The app is now ready for Bangladeshi students with full NCTB curriculum support. The AI tutor understands the context of each chapter and can provide explanations that align with the national curriculum standards.

---

**Last Updated**: August 24, 2025  
**Curriculum Version**: NCTB Mathematics Class 9-10  
**App Version**: 1.0.0 with NCTB Integration
