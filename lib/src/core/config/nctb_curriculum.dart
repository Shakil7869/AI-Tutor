/// NCTB (National Curriculum and Textbook Board) Mathematics Curriculum
/// For Bangladeshi students following the national curriculum
class NCTBCurriculum {
  /// Mathematics chapters for Class 9-10 according to NCTB curriculum
  static const Map<int, List<Map<String, dynamic>>> mathChapters = {
    9: [
      {
        'id': 'real_numbers',
        'name': 'বাস্তব সংখ্যা',
        'englishName': 'Real Numbers',
        'chapterNumber': '১ম অধ্যায়',
        'description': 'প্রাকৃতিক সংখ্যা, পূর্ণ সংখ্যা, মূলদ ও অমূলদ সংখ্যা',
        'englishDescription': 'Natural numbers, integers, rational and irrational numbers',
        'topics': [
          'প্রাকৃতিক সংখ্যা',
          'পূর্ণ সংখ্যা',
          'মূলদ সংখ্যা',
          'অমূলদ সংখ্যা',
          'বাস্তব সংখ্যার বৈশিষ্ট্য'
        ]
      },
      {
        'id': 'sets_functions',
        'name': 'সেট ও ফাংশন',
        'englishName': 'Sets and Functions',
        'chapterNumber': '২য় অধ্যায়',
        'description': 'সেটের ধারণা, সেটের প্রক্রিয়া, ফাংশনের মূলনীতি',
        'englishDescription': 'Set concepts, set operations, function principles',
        'topics': [
          'সেটের ধারণা',
          'সেটের প্রকারভেদ',
          'সেটের প্রক্রিয়া',
          'ভেন চিত্র',
          'ফাংশনের মূলনীতি'
        ]
      },
      {
        'id': 'algebraic_expressions',
        'name': 'বীজগাণিতিক রাশি',
        'englishName': 'Algebraic Expressions',
        'chapterNumber': '৩য় অধ্যায়',
        'description': 'বীজগাণিতিক রাশির গুণ, ভাগ, উৎপাদক নির্ণয়',
        'englishDescription': 'Multiplication, division and factorization of algebraic expressions',
        'topics': [
          'বীজগাণিতিক রাশির গুণ',
          'বীজগাণিতিক রাশির ভাগ',
          'উৎপাদক নির্ণয়',
          'বর্গের সূত্র প্রয়োগ'
        ]
      },
      {
        'id': 'indices_logarithms',
        'name': 'সূচক ও লগারিদম',
        'englishName': 'Indices and Logarithms',
        'chapterNumber': '৪র্থ অধ্যায়',
        'description': 'সূচকের নিয়ম, লগারিদমের ধর্ম ও প্রয়োগ',
        'englishDescription': 'Laws of indices, properties and applications of logarithms',
        'topics': [
          'সূচকের নিয়মাবলী',
          'লগারিদমের ধারণা',
          'লগারিদমের ধর্ম',
          'লগারিদমের প্রয়োগ'
        ]
      },
      {
        'id': 'linear_equations',
        'name': 'এক চলকবিশিষ্ট সমীকরণ',
        'englishName': 'Linear Equations in One Variable',
        'chapterNumber': '৫ম অধ্যায়',
        'description': 'রৈখিক সমীকরণ সমাধান ও সমস্যা সমাধান',
        'englishDescription': 'Solving linear equations and word problems',
        'topics': [
          'সরল সমীকরণ',
          'সমীকরণ সমাধান',
          'দৈনন্দিন জীবনের সমস্যা',
          'শতকরা সমস্যা'
        ]
      },
      {
        'id': 'lines_angles_triangles',
        'name': 'রেখা, কোণ ও ত্রিভুজ',
        'englishName': 'Lines, Angles and Triangles',
        'chapterNumber': '৬ষ্ঠ অধ্যায়',
        'description': 'রেখার ধর্ম, কোণের প্রকার, ত্রিভুজের বৈশিষ্ট্য',
        'englishDescription': 'Properties of lines, types of angles, triangle properties',
        'topics': [
          'রেখা ও রেখাংশ',
          'কোণের প্রকারভেদ',
          'ত্রিভুজের শ্রেণীবিভাগ',
          'ত্রিভুজের কোণের সমষ্টি'
        ]
      },
      {
        'id': 'practical_geometry',
        'name': 'ব্যবহারিক জ্যামিতি',
        'englishName': 'Practical Geometry',
        'chapterNumber': '৭ম অধ্যায়',
        'description': 'জ্যামিতিক অঙ্কন ও নির্মাণ',
        'englishDescription': 'Geometric constructions and drawings',
        'topics': [
          'কোণ অঙ্কন',
          'ত্রিভুজ অঙ্কন',
          'চতুর্ভুজ অঙ্কন',
          'বৃত্ত অঙ্কন'
        ]
      },
      {
        'id': 'circles',
        'name': 'বৃত্ত',
        'englishName': 'Circles',
        'chapterNumber': '৮ম অধ্যায়',
        'description': 'বৃত্তের ধর্ম, স্পর্শক ও জ্যা সংক্রান্ত উপপাদ্য',
        'englishDescription': 'Circle properties, tangent and chord theorems',
        'topics': [
          'বৃত্তের উপাদান',
          'বৃত্তের জ্যা',
          'বৃত্তের স্পর্শক',
          'বৃত্ত সংক্রান্ত উপপাদ্য'
        ]
      },
      {
        'id': 'trigonometric_ratios',
        'name': 'ত্রিকোণমিতিক অনুপাত',
        'englishName': 'Trigonometric Ratios',
        'chapterNumber': '৯ম অধ্যায়',
        'description': 'ত্রিকোণমিতিক অনুপাত ও তাদের প্রয়োগ',
        'englishDescription': 'Trigonometric ratios and their applications',
        'topics': [
          'sin, cos, tan অনুপাত',
          'ত্রিকোণমিতিক সূত্র',
          'পরিপূরক কোণ',
          'ত্রিকোণমিতিক অভেদ'
        ]
      },
      {
        'id': 'distance_height',
        'name': 'দূরত্ব ও উচ্চতা',
        'englishName': 'Distance and Height',
        'chapterNumber': '১০ম অধ্যায়',
        'description': 'ত্রিকোণমিতি ব্যবহার করে দূরত্ব ও উচ্চতা নির্ণয়',
        'englishDescription': 'Finding distance and height using trigonometry',
        'topics': [
          'উন্নতি কোণ',
          'অবনতি কোণ',
          'উচ্চতা নির্ণয়',
          'দূরত্ব নির্ণয়'
        ]
      },
      {
        'id': 'algebraic_ratios',
        'name': 'বীজগাণিতিক অনুপাত ও সমানুপাত',
        'englishName': 'Algebraic Ratios and Proportions',
        'chapterNumber': '১১শ অধ্যায়',
        'description': 'অনুপাত, সমানুপাত ও তাদের প্রয়োগ',
        'englishDescription': 'Ratios, proportions and their applications',
        'topics': [
          'অনুপাতের ধর্ম',
          'সমানুপাতের ধর্ম',
          'যৌগিক অনুপাত',
          'ব্যবহারিক সমস্যা'
        ]
      },
      {
        'id': 'simultaneous_equations',
        'name': 'দুই চলকবিশিষ্ট সরল সহসমীকরণ',
        'englishName': 'Simultaneous Linear Equations in Two Variables',
        'chapterNumber': '১২শ অধ্যায়',
        'description': 'দুই চলকের সরল সমীকরণ সমাধান',
        'englishDescription': 'Solving linear equations in two variables',
        'topics': [
          'গ্রাফিক্যাল পদ্ধতি',
          'বিলোপ পদ্ধতি',
          'প্রতিস্থাপন পদ্ধতি',
          'ব্যবহারিক সমস্যা'
        ]
      },
      {
        'id': 'finite_series',
        'name': 'সসীম ধারা',
        'englishName': 'Finite Series',
        'chapterNumber': '১৩শ অধ্যায়',
        'description': 'সমান্তর ও গুণোত্তর ধারা',
        'englishDescription': 'Arithmetic and geometric progressions',
        'topics': [
          'সমান্তর অগ্রগতি',
          'গুণোত্তর অগ্রগতি',
          'ধারার সমষ্টি',
          'গড় নির্ণয়'
        ]
      },
      {
        'id': 'ratio_similarity_symmetry',
        'name': 'অনুপাত, সদৃশতা ও প্রতিসমতা',
        'englishName': 'Ratio, Similarity and Symmetry',
        'chapterNumber': '১৪শ অধ্যায়',
        'description': 'জ্যামিতিক আকৃতির সদৃশতা ও প্রতিসমতা',
        'englishDescription': 'Similarity and symmetry of geometric shapes',
        'topics': [
          'সদৃশ ত্রিভুজ',
          'প্রতিসম আকৃতি',
          'স্কেল ফ্যাক্টর',
          'ক্ষেত্রফলের অনুপাত'
        ]
      },
      {
        'id': 'area_theorems',
        'name': 'ক্ষেত্রফল সম্পর্কিত উপপাদ্য ও সম্পাদ্য',
        'englishName': 'Area Related Theorems and Constructions',
        'chapterNumber': '১৫শ অধ্যায়',
        'description': 'জ্যামিতিক আকৃতির ক্ষেত্রফল নির্ণয়',
        'englishDescription': 'Finding areas of geometric shapes',
        'topics': [
          'ত্রিভুজের ক্ষেত্রফল',
          'চতুর্ভুজের ক্ষেত্রফল',
          'বৃত্তের ক্ষেত্রফল',
          'জটিল আকৃতির ক্ষেত্রফল'
        ]
      },
      {
        'id': 'mensuration',
        'name': 'পরিমিতি',
        'englishName': 'Mensuration',
        'chapterNumber': '১৬শ অধ্যায়',
        'description': 'ত্রিমাত্রিক আকৃতির আয়তন ও পৃষ্ঠতলের ক্ষেত্রফল',
        'englishDescription': 'Volume and surface area of 3D shapes',
        'topics': [
          'ঘনক ও ঘনক্ষেত্র',
          'চোঙ ও বেলন',
          'পিরামিড ও কোণক',
          'গোলক'
        ]
      },
      {
        'id': 'statistics',
        'name': 'পরিসংখ্যান',
        'englishName': 'Statistics',
        'chapterNumber': '১৭শ অধ্যায়',
        'description': 'তথ্য সংগ্রহ, উপস্থাপনা ও বিশ্লেষণ',
        'englishDescription': 'Data collection, presentation and analysis',
        'topics': [
          'তথ্য সংগ্রহ',
          'গড়, মধ্যক, প্রচুরক',
          'গ্রাফ ও চার্ট',
          'সম্ভাব্যতা'
        ]
      }
    ],
    10: [
      // Class 10 chapters will be similar but with advanced topics
      // For now, using same structure as Class 9 but can be customized
      {
        'id': 'real_numbers_advanced',
        'name': 'বাস্তব সংখ্যা (উন্নত)',
        'englishName': 'Real Numbers (Advanced)',
        'chapterNumber': '১ম অধ্যায়',
        'description': 'উন্নত বাস্তব সংখ্যার ধারণা ও প্রয়োগ',
        'englishDescription': 'Advanced concepts and applications of real numbers',
        'topics': [
          'করণী সংখ্যা',
          'সংখ্যা রেখা',
          'পূর্ণ সংখ্যার ধর্ম',
          'অমূলদ সংখ্যার প্রমাণ'
        ]
      },
      // Add more Class 10 chapters as needed...
    ]
  };

  /// Get chapters for a specific class
  static List<Map<String, dynamic>> getChaptersForClass(int classLevel) {
    return mathChapters[classLevel] ?? [];
  }

  /// Get chapter by ID
  static Map<String, dynamic>? getChapterById(String id, int classLevel) {
    final chapters = getChaptersForClass(classLevel);
    try {
      return chapters.firstWhere((chapter) => chapter['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all available topics for a chapter
  static List<String> getTopicsForChapter(String chapterId, int classLevel) {
    final chapter = getChapterById(chapterId, classLevel);
    return chapter?['topics']?.cast<String>() ?? [];
  }

  /// Check if a chapter exists
  static bool hasChapter(String id, int classLevel) {
    return getChapterById(id, classLevel) != null;
  }

  /// Get Bengali chapter names for display
  static List<String> getBengaliChapterNames(int classLevel) {
    return getChaptersForClass(classLevel)
        .map((chapter) => chapter['name'] as String)
        .toList();
  }

  /// Get English chapter names for API calls
  static List<String> getEnglishChapterNames(int classLevel) {
    return getChaptersForClass(classLevel)
        .map((chapter) => chapter['englishName'] as String)
        .toList();
  }
}
