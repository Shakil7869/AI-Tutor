import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'enhanced_chat_screen.dart';
import 'chapter_summary_screen.dart';

class ClassSubjectSelectionScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ClassSubjectSelectionScreen({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<ClassSubjectSelectionScreen> createState() => _ClassSubjectSelectionScreenState();
}

class _ClassSubjectSelectionScreenState extends ConsumerState<ClassSubjectSelectionScreen> {
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedChapter;
  
  final Map<String, Map<String, List<String>>> _curriculum = {
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
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Class & Subject'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NCTB AI Tutor',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Choose your class and subject to start learning',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Class selection
            Text(
              'Select Your Class',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildClassSelection(),
            const SizedBox(height: 24),

            // Subject selection
            if (_selectedClass != null) ...[
              Text(
                'Select Subject',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSubjectSelection(),
              const SizedBox(height: 24),
            ],

            // Chapter selection
            if (_selectedClass != null && _selectedSubject != null) ...[
              Text(
                'Select Chapter (Optional)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can select a specific chapter or chat about the entire subject',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              _buildChapterSelection(),
              const SizedBox(height: 24),
            ],

            // Action buttons
            if (_selectedClass != null && _selectedSubject != null) ...[
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _curriculum.keys.map((classLevel) {
        final isSelected = _selectedClass == classLevel;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedClass = classLevel;
              _selectedSubject = null; // Reset subject when class changes
              _selectedChapter = null; // Reset chapter when class changes
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade300,
              ),
            ),
            child: Text(
              'Class $classLevel',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectSelection() {
    if (_selectedClass == null) return const SizedBox.shrink();
    
    final subjects = _curriculum[_selectedClass]!.keys.toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final isSelected = _selectedSubject == subject;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubject = subject;
              _selectedChapter = null; // Reset chapter when subject changes
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getSubjectIcon(subject),
                  color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterSelection() {
    if (_selectedClass == null || _selectedSubject == null) {
      return const SizedBox.shrink();
    }
    
    final chapters = _curriculum[_selectedClass]![_selectedSubject]!;
    
    return Column(
      children: [
        // "All Chapters" option
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedChapter = null;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _selectedChapter == null 
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedChapter == null 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.all_inclusive,
                  color: _selectedChapter == null 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  'All Chapters (General $_selectedSubject)',
                  style: TextStyle(
                    color: _selectedChapter == null 
                      ? Theme.of(context).primaryColor 
                      : Colors.black87,
                    fontWeight: _selectedChapter == null 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Individual chapters
        ...chapters.map((chapter) {
          final isSelected = _selectedChapter == chapter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChapter = chapter;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chapter,
                      style: TextStyle(
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.black87,
                        fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action - Start Chat
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EnhancedChatScreen(
                    classLevel: _selectedClass!,
                    subject: _selectedSubject,
                    chapter: _selectedChapter,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: Text(_selectedChapter != null 
              ? 'Start Chat about $_selectedChapter'
              : 'Start Chat about $_selectedSubject'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Secondary actions (only if chapter is selected)
        if (_selectedChapter != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChapterSummaryScreen(
                          classLevel: _selectedClass!,
                          subject: _selectedSubject!,
                          chapter: _selectedChapter!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.summarize),
                  label: const Text('Summary'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChapterQuizScreen(
                          classLevel: _selectedClass!,
                          subject: _selectedSubject!,
                          chapter: _selectedChapter!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.quiz),
                  label: const Text('Quiz'),
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Selection summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Selection:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text('Class: $_selectedClass'),
              Text('Subject: $_selectedSubject'),
              if (_selectedChapter != null) 
                Text('Chapter: $_selectedChapter')
              else
                const Text('Chapter: All chapters'),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.biotech;
      case 'biology':
        return Icons.nature;
      case 'mathematics':
        return Icons.calculate;
      default:
        return Icons.book;
    }
  }
}
