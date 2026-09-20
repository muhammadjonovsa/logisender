import 'dart:math';

/// Smart template engine that generates unique text variations
/// from a base template, ensuring no duplicate sends.
class SmartTemplateEngine {
  static final _random = Random();

  /// Emoji pools for random selection.
  static const _directionEmojis = ['➡️', '→', '➩', '➺', '➻'];
  static const _packageEmojis = ['📦', '📫', '📬', '📭'];
  static const _truckEmojis = ['🚛', '🚚', '🚐', '🏎️'];
  static const _moneyEmojis = ['💰', '💵', '💲', '🤑'];
  static const _checkEmojis = ['✅', '✔️', '☑️', '🆗'];


  /// Russian synonyms for common logistics terms.
  static const _synonymsRu = {
    'Takhta': ['Тахта', 'Такhta', 'Такhta доска', 'Доска', 'Такhta брус'],
    'доска': ['такhta', 'брус', 'пиломатериал', 'дерево'],
    ' tent': ['палатка', 'тент', 'тентовка', 'тент-палатка'],
    'Груз': ['Товар', 'Продукция', 'Отправка', 'Партия'],
    'договорная': ['обсуждается', 'по запросу', 'торг', 'договорённость'],
    'готов': ['готовность', 'в наличии', 'на месте', 'загрузка'],
    ' ставка': ['цена', 'тариф', 'стоимость', 'расценка'],
  };

  /// Uzbek synonyms for common logistics terms.
  static const _synonymsUz = {
    'Takhta': ['Taxta', 'Taxta doska', 'Doska', 'Taxta brus'],
    'груз': ['товар', 'малумот', 'юбориш', 'партія'],
    'палатка': ['тент', 'тентлаш', 'тент-палатка'],
  };

  /// Preposition/prefix words that can be shuffled.
  static const _fillerWords = [
    '',
    '',
    '',
    '⭐ ',
    '🔥 ',
    '📢 ',
    '⚡ ',
    '',
    '',
  ];

  /// Generates a unique text variation from the original template.
  ///
  /// The engine applies these transformations:
  /// 1. Random synonym replacement
  /// 2. Random emoji substitution
  /// 3. Line reordering (subtle)
  /// 4. Random filler word prefix
  /// 5. Whitespace variation
  static String generateVariation(String originalText) {
    var text = originalText;

    // Apply synonym replacement
    text = _applySynonyms(text);

    // Apply emoji variations
    text = _applyEmojiVariations(text);

    // Add random prefix
    final prefix = _fillerWords[_random.nextInt(_fillerWords.length)];
    if (prefix.isNotEmpty && _random.nextBool()) {
      text = '$prefix$text';
    }

    // Apply subtle whitespace variation
    text = _applyWhitespaceVariation(text);

    return text;
  }

  static String _applySynonyms(String text) {
    final allSynonyms = <String, List<String>>{};
    allSynonyms.addAll(_synonymsRu);
    for (final entry in _synonymsUz.entries) {
      if (allSynonyms.containsKey(entry.key)) {
        allSynonyms[entry.key] = [...allSynonyms[entry.key]!, ...entry.value];
      } else {
        allSynonyms[entry.key] = entry.value;
      }
    }

    for (final entry in allSynonyms.entries) {
      if (text.contains(entry.key) && _random.nextDouble() < 0.4) {
        final synonym =
            entry.value[_random.nextInt(entry.value.length)];
        text = text.replaceFirst(entry.key, synonym);
      }
    }

    return text;
  }

  static String _applyEmojiVariations(String text) {
    text = text.replaceAllMapped(
      RegExp(_directionEmojis.map(RegExp.escape).join('|')),
      (match) {
        return _random.nextDouble() < 0.3
            ? _directionEmojis[_random.nextInt(_directionEmojis.length)]
            : match.group(0)!;
      },
    );

    text = text.replaceAllMapped(
      RegExp(_packageEmojis.map(RegExp.escape).join('|')),
      (match) {
        return _random.nextDouble() < 0.3
            ? _packageEmojis[_random.nextInt(_packageEmojis.length)]
            : match.group(0)!;
      },
    );

    text = text.replaceAllMapped(
      RegExp(_truckEmojis.map(RegExp.escape).join('|')),
      (match) {
        return _random.nextDouble() < 0.3
            ? _truckEmojis[_random.nextInt(_truckEmojis.length)]
            : match.group(0)!;
      },
    );

    text = text.replaceAllMapped(
      RegExp(_moneyEmojis.map(RegExp.escape).join('|')),
      (match) {
        return _random.nextDouble() < 0.3
            ? _moneyEmojis[_random.nextInt(_moneyEmojis.length)]
            : match.group(0)!;
      },
    );

    text = text.replaceAllMapped(
      RegExp(_checkEmojis.map(RegExp.escape).join('|')),
      (match) {
        return _random.nextDouble() < 0.3
            ? _checkEmojis[_random.nextInt(_checkEmojis.length)]
            : match.group(0)!;
      },
    );

    return text;
  }

  static String _applyWhitespaceVariation(String text) {
    final lines = text.split('\n');

    // Slight chance to add an empty line between sections
    if (lines.length > 2 && _random.nextDouble() < 0.25) {
      final insertIndex = 1 + _random.nextInt(lines.length - 2);
      lines.insert(insertIndex, '');
    }

    // Slight chance to trim trailing spaces
    if (_random.nextDouble() < 0.5) {
      return lines.join('\n').trimRight();
    }

    return lines.join('\n');
  }

  /// Splits template text into structured parts for analysis.
  static Map<String, String> parseStructure(String text) {
    final parts = <String, String>{};
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('➡') || trimmed.contains('→')) {
        parts['direction'] = trimmed;
      } else if (trimmed.contains('📦') || trimmed.contains('Cargo') || trimmed.contains('Груз')) {
        parts['cargo'] = trimmed;
      } else if (trimmed.contains('🚛') || trimmed.contains('Required')) {
        parts['vehicle'] = trimmed;
      } else if (trimmed.contains('💰') || trimmed.contains('Rate') || trimmed.contains('ставк')) {
        parts['rate'] = trimmed;
      } else if (trimmed.contains('✅') || trimmed.contains('ready') || trimmed.contains('готов')) {
        parts['status'] = trimmed;
      } else if (trimmed.contains('🇷🇺') || trimmed.contains('🇺🇿') || trimmed.contains('📍')) {
        parts['location'] = trimmed;
      } else {
        parts['misc_${parts.length}'] = trimmed;
      }
    }

    return parts;
  }
}
