/// Lightweight, dependency-free text analysis tuned for Thai + English novel
/// content. Used by the writing/preview screens to give authors quick feedback
/// and by the recommender to extract keyword signals.
class TextAnalysisService {
  static const Set<String> _stopwords = {
    // English
    'the', 'a', 'an', 'and', 'or', 'but', 'if', 'then', 'else', 'is', 'was',
    'are', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does',
    'did', 'of', 'to', 'in', 'on', 'at', 'by', 'for', 'with', 'about', 'as',
    'into', 'through', 'over', 'after', 'before', 'between', 'this', 'that',
    'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'them',
    'his', 'her', 'their', 'our', 'my', 'your', 'me', 'us',
    // Thai (function words / particles)
    'และ', 'หรือ', 'แต่', 'ของ', 'ที่', 'ใน', 'จาก', 'ไป', 'มา', 'ได้', 'ไม่',
    'เป็น', 'อยู่', 'คือ', 'ก็', 'นี้', 'นั้น', 'มี', 'จะ', 'ให้', 'ก่อน',
    'หลัง', 'ถึง', 'ด้วย', 'แล้ว', 'กับ', 'อย่าง', 'เพราะ', 'เมื่อ', 'ขณะ',
    'จึง', 'ครับ', 'ค่ะ', 'นะ', 'นะคะ', 'อีก', 'มาก', 'น้อย',
  };

  /// Quick stats: char/word/sentence counts + an estimated reading time.
  static Map<String, dynamic> stats(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return {
        'characters': 0,
        'words': 0,
        'sentences': 0,
        'paragraphs': 0,
        'reading_minutes': 0.0,
      };
    }

    final words = _tokenize(trimmed).length;
    final sentenceCount = RegExp(r'[\.!?…ฯ]+|\n{2,}')
        .allMatches(trimmed)
        .length
        .clamp(1, 1 << 31);
    final paragraphCount = trimmed
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .length;

    // ~250 Thai/English mixed words per minute (mid-range silent reading).
    final readingMinutes = words / 250.0;

    return {
      'characters': trimmed.runes.length,
      'words': words,
      'sentences': sentenceCount,
      'paragraphs': paragraphCount,
      'reading_minutes': readingMinutes,
    };
  }

  /// Top-N keywords by frequency. Returns list of {word, count}.
  static List<Map<String, dynamic>> extractKeywords(
    String text, {
    int topN = 10,
    int minLength = 2,
  }) {
    if (text.trim().isEmpty) return const [];
    final counts = <String, int>{};
    for (final token in _tokenize(text)) {
      final t = token.toLowerCase();
      if (t.length < minLength) continue;
      if (_stopwords.contains(t)) continue;
      if (RegExp(r'^[0-9_\W]+$').hasMatch(t)) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(topN)
        .map((e) => {'word': e.key, 'count': e.value})
        .toList();
  }

  /// Rough sentiment polarity in [-1, 1] using a tiny seed lexicon.
  static double sentimentScore(String text) {
    if (text.trim().isEmpty) return 0;
    const positive = {
      'love', 'happy', 'great', 'beautiful', 'amazing', 'joy', 'wonderful',
      'รัก', 'สุข', 'ดี', 'งดงาม', 'ยอดเยี่ยม', 'อบอุ่น', 'หวาน', 'สำเร็จ',
    };
    const negative = {
      'sad', 'angry', 'hate', 'bad', 'cry', 'pain', 'death',
      'เศร้า', 'โกรธ', 'เกลียด', 'เจ็บ', 'ร้องไห้', 'ตาย', 'แย่', 'หม่น',
    };
    int pos = 0;
    int neg = 0;
    for (final token in _tokenize(text).map((e) => e.toLowerCase())) {
      if (positive.contains(token)) pos++;
      if (negative.contains(token)) neg++;
    }
    final total = pos + neg;
    if (total == 0) return 0;
    return (pos - neg) / total;
  }

  /// Combined content signals for the writing/preview UI.
  static Map<String, dynamic> contentSignals(String text) {
    final s = stats(text);
    final dialogueLines =
        RegExp('"[^"]+"|“[^”]+”|‘[^’]+’')
            .allMatches(text)
            .length;
    final paragraphs = (s['paragraphs'] as int);
    final dialogueRatio =
        paragraphs == 0 ? 0.0 : dialogueLines / paragraphs;
    final keywords = extractKeywords(text, topN: 20);
    final words = (s['words'] as int);
    final diversity = keywords.isEmpty || words == 0
        ? 0.0
        : keywords.length / words;

    return {
      ...s,
      'dialogue_ratio': dialogueRatio.clamp(0.0, 1.0),
      'keyword_diversity': diversity.clamp(0.0, 1.0),
      'sentiment': sentimentScore(text),
      'top_keywords': keywords.take(5).toList(),
    };
  }

  static List<String> _tokenize(String text) {
    return text
        .split(RegExp('[\\s,\\.!?:;()\\[\\]{}"\'…\\-—–·]+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
