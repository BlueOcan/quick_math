import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

// ── Data model ───────────────────────────────────────────────────────────────
class WordQuestion {
  final String question;
  final String correct;
  final List<String> options; // already shuffled, 4 items
  final String category; // 'synonyms' | 'antonyms' | 'spell_check'
  final String difficulty; // 'easy' | 'medium' | 'hard'

  const WordQuestion({
    required this.question,
    required this.correct,
    required this.options,
    required this.category,
    required this.difficulty,
  });
}

// ── Category enum ─────────────────────────────────────────────────────────────
enum WordCategory { synonyms, antonyms, spellCheck }

extension WordCategoryExt on WordCategory {
  String get label {
    switch (this) {
      case WordCategory.synonyms:
        return 'Synonyms';
      case WordCategory.antonyms:
        return 'Antonyms';
      case WordCategory.spellCheck:
        return 'Spell Check';
    }
  }

  String get description {
    switch (this) {
      case WordCategory.synonyms:
        return 'Find the word with the same meaning';
      case WordCategory.antonyms:
        return 'Find the word with the opposite meaning';
      case WordCategory.spellCheck:
        return 'Pick the correctly spelled word';
    }
  }

  String get assetPath {
    switch (this) {
      case WordCategory.synonyms:
        return 'assets/words/synonyms.json';
      case WordCategory.antonyms:
        return 'assets/words/antonyms.json';
      case WordCategory.spellCheck:
        return 'assets/words/spell_check.json';
    }
  }

  String get key {
    switch (this) {
      case WordCategory.synonyms:
        return 'synonyms';
      case WordCategory.antonyms:
        return 'antonyms';
      case WordCategory.spellCheck:
        return 'spell_check';
    }
  }
}

// ── Question loader & picker ──────────────────────────────────────────────────
class WordQuestionBank {
  static final Random _rng = Random();

  // Cache so we only load each file once per app session
  static final Map<String, List<Map<String, dynamic>>> _cache = {};

  static Future<List<Map<String, dynamic>>> _load(String path) async {
    if (_cache.containsKey(path)) return _cache[path]!;
    final raw = await rootBundle.loadString(path);
    final list = List<Map<String, dynamic>>.from(json.decode(raw) as List);
    _cache[path] = list;
    return list;
  }

  /// Returns a shuffled list of [count] WordQuestions for [category] and
  /// [difficulty] (0=easy, 1=medium, 2=hard).
  /// Falls back to all difficulties if not enough questions exist.
  static Future<List<WordQuestion>> getQuestions({
    required WordCategory category,
    required int difficulty,
    required int count,
  }) async {
    final diffStr = difficulty == 0
        ? 'easy'
        : difficulty == 1
            ? 'medium'
            : 'hard';

    List<Map<String, dynamic>> all;
    try {
      all = await _load(category.assetPath);
    } catch (_) {
      return [];
    }

    // Filter by difficulty
    var filtered = all.where((e) => e['difficulty'] == diffStr).toList();

    // Fallback: if fewer than count entries, use all difficulties
    if (filtered.length < count) filtered = List.from(all);

    // Shuffle and take [count]
    filtered.shuffle(_rng);
    final picked = filtered.take(count).toList();

    return picked.map((e) {
      final correct = e['correct'] as String;
      final wrong = List<String>.from(e['wrong'] as List);
      // Always 4 options: 1 correct + up to 3 wrong (pad if needed)
      final opts = [correct, ...wrong.take(3)]..shuffle(_rng);
      return WordQuestion(
        question: e['question'] as String,
        correct: correct,
        options: opts,
        category: category.key,
        difficulty: diffStr,
      );
    }).toList();
  }
}
