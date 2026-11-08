// File path and name: spikes/speech_trial/test/matching_test.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
// Created On Timestamp: 2026-11-08 @ 06:23 EST (replaces the flutter create counter test)
// File Description: Unit tests for the trial's key-phrase matching helpers.
// Uses: capture_controller.dart, trial_config.dart, package:flutter_test.
// Used By: flutter test.
// Purpose: Key phrases must trigger only when meant to (VC-4, VC-7, VC-10).

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_trial/capture_controller.dart';
import 'package:speech_trial/trial_config.dart';

void main() {
  test('normalize lowercases, strips punctuation, keeps accents', () {
    expect(normalize('  Scene INFO!  '), 'scene info');
    expect(normalize("Fin de l'appel, ÉTAT stable."), 'fin de l appel état stable');
  });

  test('findPhrase matches whole words only', () {
    expect(findPhrase('pulse 110 first log end', englishPack.endPhrases), 10);
    expect(findPhrase('first logend', ['first log end']), -1);
    expect(findPhrase('scenery', ['scene']), -1);
  });

  test('isCommand needs the phrase to be (almost) the whole utterance', () {
    expect(isCommand('vitals', englishPack.fields[TrialField.vitals]!), isTrue);
    expect(isCommand('vitals please', englishPack.fields[TrialField.vitals]!), isTrue);
    expect(isCommand('his vitals were taken earlier today', englishPack.fields[TrialField.vitals]!), isFalse);
    expect(isCommand('', englishPack.sessionNew), isFalse);
  });

  test('stripEndPhrase removes a spoken end phrase from Canary text', () {
    expect(stripEndPhrase('Pulse 110, breathing 24. First Log end.', englishPack.endPhrases),
        'Pulse 110, breathing 24.');
    expect(stripEndPhrase('Pouls 110. Fin de dictée.', frenchPack.endPhrases), 'Pouls 110.');
    expect(stripEndPhrase('Nothing to strip.', englishPack.endPhrases), 'Nothing to strip.');
  });

  test('spoken date and time', () {
    final t = DateTime(2026, 11, 8, 15, 5);
    expect(englishPack.spokenDateTime(t), 'Sunday, November 8, 2026, 3:05 PM.');
    expect(frenchPack.spokenDateTime(t), 'dimanche 8 novembre 2026, 15 h 05.');
  });
}
