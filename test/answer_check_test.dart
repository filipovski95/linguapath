import 'package:flutter_test/flutter_test.dart';
import 'package:saylark/data/models.dart';
import 'package:saylark/logic/answer_check.dart';

void main() {
  bool ok(String typed, String text, [String? roman]) =>
      AnswerCheck.matches(typed, Entry(text: text, roman: roman));

  test('ignores capitals, punctuation and spaces', () {
    expect(ok('wie gehts', "Wie geht's?"), isTrue);
    expect(ok('  HALLO ', 'Hallo'), isTrue);
    expect(ok('donde esta', '¿Dónde está …?'), isTrue);
  });

  test('the article is optional', () {
    expect(ok('Kaffee', 'der Kaffee'), isTrue);
    expect(ok('der kaffee', 'der Kaffee'), isTrue);
    expect(ok('eau', "l'eau"), isTrue);
    expect(ok('cafe', 'el café'), isTrue);
  });

  test('accepts missing accents but reports them', () {
    final e = const Entry(text: 'la maçã');
    expect(AnswerCheck.matches('maca', e), isTrue);
    expect(AnswerCheck.exact('maca', e), isFalse);
    expect(AnswerCheck.exact('maçã', e), isTrue);
  });

  test('Chinese accepts characters or Pinyin without tones', () {
    expect(ok('你好', '你好', 'nǐ hǎo'), isTrue);
    expect(ok('ni hao', '你好', 'nǐ hǎo'), isTrue);
    expect(ok('nihao', '你好', 'nǐ hǎo'), isTrue);
    expect(ok('xie xie', '你好', 'nǐ hǎo'), isFalse);
  });

  test('Macedonian accepts Cyrillic or Latin', () {
    expect(ok('здраво', 'Здраво', 'Zdravo'), isTrue);
    expect(ok('zdravo', 'Здраво', 'Zdravo'), isTrue);
    expect(ok('kuce', 'куче', 'kuče'), isTrue);
  });

  test('Pinyin can be typed with tone numbers and v for ü', () {
    expect(ok('ni3 hao3', '你好', 'nǐ hǎo'), isTrue);
    expect(ok('nv3er2', '女儿', "nǚ'ér"), isTrue);
    expect(ok('ni3 hao4 ma', '你好', 'nǐ hǎo'), isFalse);
  });

  test('Macedonian Latin can be typed with digraphs', () {
    expect(ok('kuche', 'куче', 'kuče'), isTrue);
    expect(ok('kjerka', 'ќерка', 'ḱerka'), isTrue);
    expect(ok('zhena', 'жена', 'žena'), isTrue);
    expect(ok('shto', 'што', 'što'), isTrue);
    expect(ok('kuke', 'куче', 'kuče'), isFalse);
  });

  test('rejects wrong words and empty answers', () {
    expect(ok('Tschüss', 'Hallo'), isFalse);
    expect(ok('', 'Hallo'), isFalse);
    expect(ok('der', 'der Kaffee'), isFalse);
  });
}
