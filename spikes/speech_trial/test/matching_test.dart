// File path and name: spikes/speech_trial/test/matching_test.dart
// Modified On Timestamp: 2026-11-08 @ 16:58 EST (run 2: 9-1-1 close matches, scene report, word times, letter
//                       stutter, cue tones)
// Created On Timestamp: 2026-11-08 @ 06:23 EST (replaces the flutter create counter test)
// File Description: Unit tests for the trial's key-phrase matching helpers.
// Uses: capture_controller.dart, speech/sherpa_engines.dart, trial_config.dart, package:flutter_test.
// Used By: flutter test.
// Purpose: Key phrases must trigger only when meant to (VC-4, VC-7, VC-10).

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_trial/capture_controller.dart';
import 'package:speech_trial/speech/sherpa_engines.dart';
import 'package:speech_trial/speech/voice.dart';
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

  test('echoPrefixWords strips the app\'s own prompt tail, as heard on phone run 1', () {
    expect(echoPrefixWords('cede second set of vitals', 'proceed'), 1);
    expect(echoPrefixWords('proceed paul ninety six', 'proceed'), 1);
    expect(echoPrefixWords('p m', normalize('Ready for a new log. Sunday, November 8, 2026, 2:12 PM.')), 2);
    expect(echoPrefixWords('diling', normalize('Call nine one one heard. Trial build, not dialling.')), 1);
    expect(echoPrefixWords('pulse one hundred ten', 'proceed'), 0);
    expect(echoPrefixWords('two car collision', 'proceed'), 0);
    // Self-test run 2 fixes: the cue tone heard as a word, and an echo slightly longer than the prompt.
    expect(echoPrefixWords('els proceed', 'proceed'), 2);
    expect(echoPrefixWords('des allés y', normalize('Allez-y.')), 3);
    expect(echoPrefixWords('enregistrée', normalize('Enregistré.')), 1);
    expect(echoPrefixWords('the pulse is weak', 'proceed'), 0);
  });

  test('isAnyCommand protects real commands from echo stripping', () {
    expect(isAnyCommand('continuing', englishPack), isTrue);
    expect(isAnyCommand('ing new', englishPack), isTrue);
    expect(isAnyCommand('saved', englishPack), isFalse);
  });

  test('closestCommand finds near misses', () {
    final m = closestCommand('call thine one one', englishPack)!;
    expect(m.$1, 'call nine one one');
    expect(m.$2, lessThan(0.34));
    expect(closestCommand('scene impul', englishPack)!.$1, 'scene info');
  });

  test('stripRepetition removes hallucinated runs only', () {
    final (clean, removed) = stripRepetition('Last meal was breakfast. T S F F F F F F F F');
    expect(clean, 'Last meal was breakfast. T S');
    expect(removed, 8);
    expect(stripRepetition('Pulse one one zero.').$2, 0); // a run of 2 is real speech
  });

  test('tokenizeForHotwords uses longest matching pieces', () {
    const tokens = {'▁SCENE', '▁IN', 'FO', '▁S', 'C', 'E', 'N', '▁VITAL', 'S'};
    expect(tokenizeForHotwords('scene info', tokens), '▁SCENE ▁IN FO');
    expect(tokenizeForHotwords('vitals', tokens), '▁VITAL S');
    expect(tokenizeForHotwords('call 911', tokens), isNull);
  });

  test('fuzzyEndPhraseWords catches misheard end phrases from run 1, not ordinary words', () {
    final ends = englishPack.endPhrases;
    expect(fuzzyEndPhraseWords('heart surgery pulse one hundred breathing twenty first law end', ends, 0.25), 3);
    expect(fuzzyEndPhraseWords('ce first lawg end', ends, 0.25), 3);
    expect(fuzzyEndPhraseWords('breathing twenty four shallow', ends, 0.25), 0);
    expect(fuzzyEndPhraseWords('the first one went to the end', ends, 0.25), 0);
    expect(fuzzyEndPhraseWords('Patient handed over to paramedics. Firstlogin.', ends, 0.5), 1);
    expect(fuzzyEndPhraseWords('Breathing twenty. Personal Log End.', ends, 0.5), 3);
  });

  test('containsCall911 accepts run-2 mishearings, not ordinary talk', () {
    final c = englishPack.call911;
    for (final heard in ['call mine one one', 'carlvine one one', 'all nine one one', 'i call mine one one',
        'pulse is getting weaker call nine one one', 'paul s getting weaker call nine one one']) {
      expect(containsCall911(heard, c, 0.2), isTrue, reason: heard);
    }
    for (final heard in ['call me on monday', 'pulse ninety one', 'i will call him later', 'nine one one',
        'emergency call heard trial build not dialling']) {
      expect(containsCall911(heard, c, 0.2), isFalse, reason: heard);
    }
    expect(containsCall911('nine one one', englishPack.call911Bare, 0.2), isTrue);
  });

  test('scene report is a scene keyword; the 9-1-1 prompt does not contain a 9-1-1 phrase', () {
    expect(isCommand('scene report', englishPack.fields[TrialField.scene]!), isTrue);
    for (final pack in [englishPack, frenchPack]) {
      expect(containsCall911(normalize(pack.promptCall911), pack.call911, 0.2), isFalse, reason: pack.code);
    }
  });

  test('word start times from BPE pieces, matched to normalized words', () {
    final w = wordsFromTokens(['▁PULSE', '▁WAS', 'N', "'T", '▁FIRST', '▁LOG'], [0.4, 0.9, 1.0, 1.1, 2.0, 2.3]);
    expect(w.map((e) => e.$1).toList(), ['PULSE', "WASN'T", 'FIRST', 'LOG']);
    expect(normalizedWordStarts(w), [0.4, 0.9, 0.9, 2.0, 2.3]); // "wasn t" is two normalized words
    expect(wordsFromTokens(['▁A', '▁B'], [5.0, 5.5], timestampOffset: 5).last.$2, 0.5);
    // sherpa-onnx gives a space instead of ▁ (self-test 2026-11-08).
    expect(wordsFromTokens([' AFTER', ' EAR', 'LY'], [1.08, 1.5, 1.6]).map((e) => e.$1).toList(), ['AFTER', 'EARLY']);
  });

  test('stripRepetition shortens stuttered letters inside a word (run 2)', () {
    final (clean, n) = stripRepetition('Patient handed over. Firststststststst log end.');
    expect(clean, 'Patient handed over. First log end.');
    expect(n, 1);
    expect(stripRepetition('Mississippi and coffee.').$2, 0);
  });

  test('cleanCanaryText removes end-phrase leftovers seen in the run-2 self-test', () {
    String clean(String raw) => cleanCanaryText(raw, englishPack, endedByPhrase: true).$1;
    expect(clean('Pale and cool. Firststststststststststst'), 'Pale and cool.');
    expect(clean('Patient handed over. Firstlog.'), 'Patient handed over.');
    // Known leftover: "Plug End." is too far from "first log end" (0.55 > 0.5) to remove safely; the audio cut
    // handles it when set-up A heard the end phrase.
    expect(clean('Seen is safe. Traffic stop.'), 'Seen is safe. Traffic stop.'); // "stop" is kept
    expect(cleanCanaryText('Came first. Firstlog.', englishPack, endedByPhrase: false).$1, 'Came first. Firstlog.');
  });

  test('cue tones: silent lead-in, then tones', () {
    final s = cueSamples(Cue.saved, 16000);
    final lead = 16000 * 300 ~/ 1000;
    expect(s.sublist(0, lead).every((x) => x == 0), isTrue);
    expect(s.length, lead + 2 * (16000 * 120 ~/ 1000 + 16000 * 70 ~/ 1000));
    expect(s.reduce((a, b) => a > b ? a : b), greaterThan(0.2));
    expect(cueSamples(Cue.none, 16000).length, lead);
  });

  test('spoken date and time', () {
    final t = DateTime(2026, 11, 8, 15, 5);
    expect(englishPack.spokenDateTime(t), 'Sunday, November 8, 2026, 3:05 PM.');
    expect(frenchPack.spokenDateTime(t), 'dimanche 8 novembre 2026, 15 h 05.');
  });
}
