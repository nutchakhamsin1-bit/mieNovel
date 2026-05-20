import 'package:flutter_test/flutter_test.dart';
import 'package:mie_project/services/text_analysis_service.dart';

void main() {
  group('TextAnalysisService.stats', () {
    test('handles empty input', () {
      final s = TextAnalysisService.stats('   ');
      expect(s['words'], 0);
      expect(s['characters'], 0);
    });

    test('counts words and characters', () {
      const text = 'Hello world. This is a test.';
      final s = TextAnalysisService.stats(text);
      expect(s['words'], greaterThan(0));
      expect(s['characters'], text.length);
    });

    test('reading_minutes scales with word count', () {
      final short = TextAnalysisService.stats('one two three');
      final long = TextAnalysisService.stats(
        List.filled(500, 'word').join(' '),
      );
      expect(
        (long['reading_minutes'] as double),
        greaterThan(short['reading_minutes'] as double),
      );
    });
  });

  group('TextAnalysisService.extractKeywords', () {
    test('filters stopwords and short tokens', () {
      const text = 'the cat and the cat saw a dog';
      final kw = TextAnalysisService.extractKeywords(text, topN: 3);
      final words = kw.map((e) => e['word']).toList();
      expect(words.contains('the'), isFalse);
      expect(words.contains('cat'), isTrue);
    });

    test('respects topN', () {
      const text =
          'alpha alpha beta beta beta gamma gamma gamma gamma delta delta';
      final kw = TextAnalysisService.extractKeywords(text, topN: 2);
      expect(kw.length, 2);
      expect(kw.first['word'], 'gamma');
    });
  });

  group('TextAnalysisService.sentimentScore', () {
    test('positive text scores > 0', () {
      expect(
        TextAnalysisService.sentimentScore('love happy amazing'),
        greaterThan(0),
      );
    });

    test('negative text scores < 0', () {
      expect(TextAnalysisService.sentimentScore('sad pain hate'), lessThan(0));
    });

    test('neutral text scores 0', () {
      expect(TextAnalysisService.sentimentScore('the table is wooden'), 0);
    });
  });
}
