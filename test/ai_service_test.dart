import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mathematical Formatting Tests', () {
    test('should format mathematical expressions with Unicode superscripts', () {
      // Test various mathematical expressions
      const testInputs = [
        '(a+b)^2 = a^2 + 2ab + b^2',
        'x^3 + y^3 = (x+y)(x^2 - xy + y^2)',
        '10^2 = 100',
        'E = mc^2',
        'sin^2(x) + cos^2(x) = 1',
        'The area is 4x^2 + 6x + 9',
      ];
      
      const expectedOutputs = [
        '(a+b)² = a² + 2ab + b²',
        'x³ + y³ = (x+y)(x² - xy + y²)',
        '10² = 100',
        'E = mc²',
        'sin²(x) + cos²(x) = 1',
        'The area is 4x² + 6x + 9',
      ];

      for (int i = 0; i < testInputs.length; i++) {
        final result = _formatMathematicalExpressions(testInputs[i]);
        expect(result, equals(expectedOutputs[i]), 
          reason: 'Failed for input: ${testInputs[i]}');
      }
    });

    test('should detect Bengali language correctly', () {
      const bengaliTexts = [
        'আমি গণিত শিখতে চাই',
        'এই সমীকরণটি সমাধান করুন',
        'বীজগণিত কী?',
      ];
      
      const englishTexts = [
        'I want to learn mathematics',
        'Solve this equation',
        'What is algebra?',
      ];

      for (final text in bengaliTexts) {
        final result = _detectLanguage(text);
        expect(result, equals('bengali'), 
          reason: 'Failed to detect Bengali for: $text');
      }

      for (final text in englishTexts) {
        final result = _detectLanguage(text);
        expect(result, equals('english'), 
          reason: 'Failed to detect English for: $text');
      }
    });

    test('should format complex mathematical expressions', () {
      const input = '''
      The quadratic formula is x = (-b +- sqrt(b^2 - 4ac)) / 2a
      For a circle: x^2 + y^2 = r^2
      Pythagorean theorem: a^2 + b^2 = c^2
      Volume of sphere: V = (4/3) * pi * r^3
      ''';
      
      final result = _formatMathematicalExpressions(input);
      
      expect(result, contains('x² + y² = r²'));
      expect(result, contains('a² + b² = c²'));
      expect(result, contains('r³'));
      expect(result, contains('π'));
      expect(result, contains('√'));
      expect(result, contains('±'));
    });
  });
}

/// Format mathematical expressions with proper Unicode superscripts and subscripts
String _formatMathematicalExpressions(String text) {
  // Replace common mathematical expressions with Unicode characters
  String formattedText = text;
  
  // Power/exponent replacements - more comprehensive patterns
  final powerReplacements = {
    // Common superscripts
    r'\^2': '²',
    r'\^3': '³', 
    r'\^4': '⁴',
    r'\^5': '⁵',
    r'\^6': '⁶',
    r'\^7': '⁷',
    r'\^8': '⁸',
    r'\^9': '⁹',
    r'\^0': '⁰',
    r'\^1': '¹',
    
    // Pattern for variables with exponents like a^2, x^3, etc.
    r'([a-zA-Z])\^2': r'$1²',
    r'([a-zA-Z])\^3': r'$1³',
    r'([a-zA-Z])\^4': r'$1⁴',
    r'([a-zA-Z])\^5': r'$1⁵',
    r'([a-zA-Z])\^6': r'$1⁶',
    r'([a-zA-Z])\^7': r'$1⁷',
    r'([a-zA-Z])\^8': r'$1⁸',
    r'([a-zA-Z])\^9': r'$1⁹',
    r'([a-zA-Z])\^0': r'$1⁰',
    r'([a-zA-Z])\^1': r'$1¹',
    
    // Expressions in parentheses with exponents like (a+b)^2
    r'\((.*?)\)\^2': r'($1)²',
    r'\((.*?)\)\^3': r'($1)³',
    r'\((.*?)\)\^4': r'($1)⁴',
    r'\((.*?)\)\^5': r'($1)⁵',
    r'\((.*?)\)\^6': r'($1)⁶',
    r'\((.*?)\)\^7': r'($1)⁷',
    r'\((.*?)\)\^8': r'($1)⁸',
    r'\((.*?)\)\^9': r'($1)⁹',
    
    // Numbers with exponents like 10^2, 2^3
    r'([0-9]+)\^2': r'$1²',
    r'([0-9]+)\^3': r'$1³',
    r'([0-9]+)\^4': r'$1⁴',
    r'([0-9]+)\^5': r'$1⁵',
    r'([0-9]+)\^6': r'$1⁶',
    r'([0-9]+)\^7': r'$1⁷',
    r'([0-9]+)\^8': r'$1⁸',
    r'([0-9]+)\^9': r'$1⁹',
    r'([0-9]+)\^0': r'$1⁰',
    r'([0-9]+)\^1': r'$1¹',
  };
  
  // Apply all power replacements
  for (final entry in powerReplacements.entries) {
    if (entry.key.contains(r'$1')) {
      // For patterns with capture groups
      formattedText = formattedText.replaceAllMapped(
        RegExp(entry.key),
        (match) {
          String replacement = entry.value;
          if (match.groupCount >= 1 && match.group(1) != null) {
            replacement = replacement.replaceAll(r'$1', match.group(1)!);
          }
          return replacement;
        },
      );
    } else {
      // For simple replacements without capture groups
      formattedText = formattedText.replaceAll(RegExp(entry.key), entry.value);
    }
  }
  
  // Common subscripts for chemical formulas or mathematical notation
  final subscriptReplacements = {
    r'_2': '₂',
    r'_3': '₃',
    r'_4': '₄',
    r'_5': '₅',
    r'_6': '₆',
    r'_7': '₇',
    r'_8': '₈',
    r'_9': '₉',
    r'_0': '₀',
    r'_1': '₁',
  };
  
  // Apply subscript replacements
  for (final entry in subscriptReplacements.entries) {
    formattedText = formattedText.replaceAll(entry.key, entry.value);
  }
  
  // Additional mathematical symbols
  formattedText = formattedText.replaceAll('sqrt', '√');
  formattedText = formattedText.replaceAll('pi', 'π');
  formattedText = formattedText.replaceAll('alpha', 'α');
  formattedText = formattedText.replaceAll('beta', 'β');
  formattedText = formattedText.replaceAll('gamma', 'γ');
  formattedText = formattedText.replaceAll('delta', 'δ');
  formattedText = formattedText.replaceAll('theta', 'θ');
  formattedText = formattedText.replaceAll('infinity', '∞');
  formattedText = formattedText.replaceAll('+-', '±');
  formattedText = formattedText.replaceAll('<=', '≤');
  formattedText = formattedText.replaceAll('>=', '≥');
  formattedText = formattedText.replaceAll('!=', '≠');
  
  return formattedText;
}

/// Detect language from user message (Bengali or English)
String _detectLanguage(String message) {
  // Count Bengali and English characters
  int bengaliCharCount = 0;
  int englishCharCount = 0;
  
  for (int i = 0; i < message.length; i++) {
    final char = message.codeUnitAt(i);
    
    // Bengali Unicode range: 0x0980-0x09FF
    if (char >= 0x0980 && char <= 0x09FF) {
      bengaliCharCount++;
    }
    // English letters: A-Z, a-z
    else if ((char >= 0x0041 && char <= 0x005A) || 
             (char >= 0x0061 && char <= 0x007A)) {
      englishCharCount++;
    }
  }
  
  // If more than 20% of characters are Bengali, consider it Bengali
  final totalChars = bengaliCharCount + englishCharCount;
  if (totalChars > 0 && bengaliCharCount > totalChars * 0.2) {
    return 'bengali';
  }
  
  // Default to English if unclear
  return 'english';
}
