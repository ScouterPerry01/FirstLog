// File path and name: spikes/speech_trial/lib/trial_config.dart
// Modified On Timestamp: 2026-11-08 @ 16:58 EST (after run 2: "scene report", bare "nine one one", 9-1-1 prompt
//                       without the phrase, tones/vibration cues with a Bluetooth lead-in)
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Key phrases, spoken prompts, model folder names and timings for the N1 speech trial,
//                   per language (English, French).
// Uses: -
// Used By: capture_controller.dart, speech/sherpa_engines.dart, speech/voice.dart, main.dart.
// Purpose: Keep every tunable value in one place. The phrases are EXAMPLES (decision 0002); the trial logs the
//          raw recognized text so the final EN/FR phrases can be chosen from real results.

enum TrialLanguage { en, fr }

/// Fields a dictation can be saved to (ST-1). Trial subset only.
enum TrialField { scene, vitals, treatment, history }

class LanguagePack {
  const LanguagePack({
    required this.code,
    required this.streamingModelDir,
    required this.voiceDir,
    required this.sessionNew,
    required this.sessionContinue,
    required this.fields,
    required this.endPhrases,
    required this.readBack,
    required this.call911,
    required this.call911Bare,
    required this.promptAsk,
    required this.promptReadyNew,
    required this.promptReadyContinue,
    required this.promptProceed,
    required this.promptSaved,
    required this.promptNothingToRead,
    required this.promptCall911,
    required this.weekdays,
    required this.months,
  });

  final String code; // 'en' / 'fr' - also the Canary source language
  final String streamingModelDir;
  final String voiceDir;

  // Key phrases (VC-4). Lower case; matched after normalising the recognized text.
  final List<String> sessionNew;
  final List<String> sessionContinue;
  final Map<TrialField, List<String>> fields;
  final List<String> endPhrases;
  final List<String> readBack;
  final List<String> call911;

  /// "Nine one one" said on its own (run 2: "call" and "nine one one" were often heard as two utterances).
  /// Counts only as the whole utterance, and not during a dictation.
  final List<String> call911Bare;

  // Spoken prompts (VC-8).
  final String promptAsk;
  final String promptReadyNew;
  final String promptReadyContinue;
  final String promptProceed;
  final String promptSaved;
  final String promptNothingToRead;
  final String promptCall911;

  final List<String> weekdays; // Monday first
  final List<String> months; // January first

  /// Every key phrase, for recognizer hotwords and near-miss logging.
  List<String> get allCommands => [
        ...sessionNew,
        ...sessionContinue,
        for (final l in fields.values) ...l,
        ...endPhrases,
        ...readBack,
        ...call911,
        ...call911Bare,
      ];

  /// Day, date and time, said after "Ready" (VC-8).
  String spokenDateTime(DateTime t) {
    final day = weekdays[t.weekday - 1];
    final month = months[t.month - 1];
    final mm = t.minute.toString().padLeft(2, '0');
    if (code == 'fr') {
      return '$day ${t.day} $month ${t.year}, ${t.hour} h $mm.';
    }
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$day, $month ${t.day}, ${t.year}, $h12:$mm $ampm.';
  }
}

const englishPack = LanguagePack(
  code: 'en',
  streamingModelDir: 'sherpa-onnx-streaming-zipformer-en-2023-06-26',
  voiceDir: 'vits-piper-en_US-amy-low',
  sessionNew: ['new', 'new log', 'new one'],
  sessionContinue: ['continuing', 'continue', 'continue log'],
  fields: {
    // "scene report" added after run 2: "info" was heard as "impul" nearly every time.
    TrialField.scene: ['scene info', 'scene information', 'scene report', 'scene'],
    TrialField.vitals: ['vitals', 'vital signs', 'vital'], // "vital" heard on phone run 1
    TrialField.treatment: ['treatment', 'treatments'],
    TrialField.history: ['history'],
  },
  // "stop dictation": said naturally by the owner on phone run 1 (VC-7 end phrase).
  endPhrases: ['first log end', 'firstlog end', 'first log and', 'first log ends', 'first log ended', 'stop dictation'],
  readBack: ['read back', 'read it back'],
  call911: ['call nine one one', 'call nine eleven', 'call 911', 'call nine one won'],
  call911Bare: ['nine one one', 'nine eleven'],
  promptAsk: 'New first aid log, or continuing?',
  promptReadyNew: 'Ready for a new log.',
  promptReadyContinue: 'Ready to continue.',
  promptProceed: 'Proceed.',
  promptSaved: 'Saved.',
  promptNothingToRead: 'Nothing saved yet.',
  // Must not contain a 9-1-1 phrase: on run 2 the app heard its own prompt and triggered again.
  promptCall911: 'Emergency call heard. Trial build, not dialling.',
  weekdays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  months: [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ],
);

const frenchPack = LanguagePack(
  code: 'fr',
  streamingModelDir: 'sherpa-onnx-streaming-zipformer-fr-2023-04-14',
  voiceDir: 'vits-piper-fr_FR-siwis-medium',
  sessionNew: ['nouveau', 'nouvelle', 'nouveau registre'],
  sessionContinue: ['on continue', 'continuer', 'continue', 'je continue'],
  fields: {
    TrialField.scene: ['info scène', 'infos scène', 'information scène', 'scène'],
    TrialField.vitals: ['signes vitaux', 'signe vitaux'],
    TrialField.treatment: ['traitement', 'traitements', 'soins'],
    TrialField.history: ['antécédents', 'antécédent'],
  },
  // "First Log" is English; the French model may hear it differently - check the logs and add what it outputs.
  endPhrases: [
    'first log fin', 'fin first log', 'fin de dictée', 'fin de la dictée', 'arrête la dictée', 'arrêter la dictée'
  ],
  readBack: ['relire', 'relis', 'relecture'],
  call911: ['appel neuf un un', 'appeler le neuf un un', 'appelle le neuf un un', 'appel neuf cent onze'],
  call911Bare: ['neuf un un', 'neuf cent onze'],
  promptAsk: 'Nouveau registre de premiers soins, ou on continue ?',
  promptReadyNew: 'Prêt pour un nouveau registre.',
  promptReadyContinue: 'Prêt à continuer.',
  promptProceed: 'Allez-y.',
  promptSaved: 'Enregistré.',
  promptNothingToRead: 'Rien d\'enregistré pour l\'instant.',
  promptCall911: 'Appel d\'urgence entendu. Version d\'essai, pas d\'appel.',
  weekdays: ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'],
  months: [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ],
);

LanguagePack packFor(TrialLanguage l) => l == TrialLanguage.en ? englishPack : frenchPack;

/// Shared model folders (both languages).
const canaryModelDir = 'sherpa-onnx-nemo-canary-180m-flash-en-es-de-fr-int8';

/// Timings.
class TrialTimings {
  /// A dictation ends if no new words are recognized for this long (VC-7).
  static const dictationSilence = Duration(seconds: 8);

  /// Ignore the microphone this long after a prompt finishes, so the app does not hear itself (VC-8).
  static const afterPromptGuard = Duration(milliseconds: 350);

  /// How often battery and speed are written to the log.
  static const metricsEvery = Duration(minutes: 1);

  /// Canary is run on chunks no longer than this (crude split; dictations are expected to be short).
  static const canaryMaxChunk = Duration(seconds: 25);
}

/// Recognizer tuning (set-up A). Hotwords bias the streaming model towards the key phrases; they need
/// modified_beam_search, which costs more CPU than greedy search (watch the battery numbers).
class TrialTuning {
  static const hotwordsScore = 2.0;
  static const maxActivePaths = 4;

  /// Silero voice detector, used to cut silence out of a dictation before Canary sees it: on run 1 Canary
  /// invented "T S F F F..." over 8 s of trailing silence (ST-4: never invent data).
  static const vadModel = 'silero_vad.onnx';
  static const vadThreshold = 0.5;
  static const vadMinSilence = 0.5; // seconds
  static const vadMinSpeech = 0.25; // seconds
  static const vadMaxSpeech = 20.0; // seconds per segment

  /// An ignored utterance this close to a key phrase (share of letters that differ) is logged as a near miss.
  static const nearMissRatio = 0.34;

  /// Live (set-up A): the words before a pause end a dictation if this close to an end phrase. Kept tight,
  /// because a false match cuts a dictation short.
  static const endPhraseLiveRatio = 0.25;

  /// Canary text of a dictation already ended by the end phrase: a trailing look-alike is removed.
  static const endPhraseTextRatio = 0.5;

  /// "Call 9-1-1" heard slightly wrong still counts (share of letters that differ). Run 2 misses scored
  /// 0.07-0.14 ("call mine one one", "carlvine one one", "all nine one one"). Missing a real call is worse
  /// than a false alarm here (EM-2); the trial never dials.
  static const call911Ratio = 0.2;

  /// The streaming model reports a word's time a little after it was said; the end-phrase cut is moved this
  /// much earlier. Chosen from the self-test on the run-1/2 phone recordings (see README).
  static var endPhraseTimingLag = const Duration(milliseconds: 300);
}

/// Tones, vibration and the Bluetooth lead-in (run 2: with earbuds, short prompts like "Saved." were not
/// heard; Bluetooth audio wakes up slowly and drops the first part of a sound).
class TrialCues {
  /// Silence played before every prompt, so a sleeping Bluetooth link wakes before the tone starts.
  static const leadIn = Duration(milliseconds: 300);
  static const toneMs = 120;
  static const gapMs = 70;
  static const volume = 0.35; // of full scale

  /// Tone pitches (Hz): rising = "heard you, go ahead"; two equal = "saved"; three high = emergency.
  static const start = [660.0, 880.0];
  static const saved = [880.0, 880.0];
  static const alert = [1046.0, 1046.0, 1046.0];

  /// Vibration patterns, alternating wait/vibrate in ms.
  static const vibrateStart = [0, 150];
  static const vibrateSaved = [0, 100, 120, 100];
  static const vibrateAlert = [0, 600];
}

const sampleRate = 16000;
