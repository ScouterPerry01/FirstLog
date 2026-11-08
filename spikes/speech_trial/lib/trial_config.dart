// File path and name: spikes/speech_trial/lib/trial_config.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
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
    TrialField.scene: ['scene info', 'scene information', 'scene'],
    TrialField.vitals: ['vitals', 'vital signs'],
    TrialField.treatment: ['treatment', 'treatments'],
    TrialField.history: ['history'],
  },
  endPhrases: ['first log end', 'firstlog end', 'first log and', 'first log ends', 'first log ended'],
  readBack: ['read back', 'read it back'],
  call911: ['call nine one one', 'call nine eleven', 'call 911', 'call nine one won'],
  promptAsk: 'New first aid log, or continuing?',
  promptReadyNew: 'Ready for a new log.',
  promptReadyContinue: 'Ready to continue.',
  promptProceed: 'Proceed.',
  promptSaved: 'Saved.',
  promptNothingToRead: 'Nothing saved yet.',
  promptCall911: 'Call nine one one heard. Trial build, not dialling.',
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
  endPhrases: ['first log fin', 'fin first log', 'fin de dictée', 'fin de la dictée'],
  readBack: ['relire', 'relis', 'relecture'],
  call911: ['appel neuf un un', 'appeler le neuf un un', 'appelle le neuf un un', 'appel neuf cent onze'],
  promptAsk: 'Nouveau registre de premiers soins, ou on continue ?',
  promptReadyNew: 'Prêt pour un nouveau registre.',
  promptReadyContinue: 'Prêt à continuer.',
  promptProceed: 'Allez-y.',
  promptSaved: 'Enregistré.',
  promptNothingToRead: 'Rien d\'enregistré pour l\'instant.',
  promptCall911: 'Appel du neuf un un entendu. Version d\'essai, pas d\'appel.',
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

const sampleRate = 16000;
