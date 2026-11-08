<!--
File path and name: spikes/speech_trial/README.md
Modified On Timestamp: 2026-11-08 @ 03:34 EST
Created On Timestamp: 2026-11-08 @ 03:34 EST (replaces the flutter create placeholder)
File Description: What the N1 speech trial is, how to get the models, and how to run it.
Uses: tool/download_models.ps1, docs/decisions/0002-voice-interaction-command-driven-capture.md.
Used By: the developer and contributors reproducing the trial.
Purpose: Make the trial reproducible; results go in docs/spikes/n1-speech-trial-results.md.
-->

# Speech trial (N1) — throwaway

**This is a disposable trial build, not the FirstLog app.** Its only job is to choose the on-device speech engine
for FirstLog and check the battery target (register item N1, App.Tracker FLOG-22). The real app will be a fresh
project. It gives no first aid advice and stores nothing beyond local test logs.

## What it measures (decision 0002)

1. **Key-phrase listening** with the screen locked: does it catch the phrases, how often does it fire by mistake,
   and what does 2 hours of listening cost in battery (VC-1, VC-4, VC-10)?
2. **Dictation accuracy**, offline, in English and French, on short vitals/treatment phrases (VC-2, ST-1).
3. **End-phrase spotting** while dictating (VC-7).

Engine set-ups compared, all through one speech-engine interface:

| Set-up | Models | How text arrives |
|---|---|---|
| A — streaming | sherpa-onnx streaming zipformer EN (2023-06-26) and FR (2023-04-14), int8 | While speaking |
| B — phrase by phrase | sherpa-onnx NeMo Canary-180m-flash (EN/ES/DE/FR), int8, with the Silero voice detector | After each phrase |
| Fallback | Vosk small EN / FR | Only if A and B both miss |

Key phrases: sherpa-onnx keyword spotter (GigaSpeech, English only) - French route to be decided in the trial.

## Get the models (not in git)

```powershell
& .\spikes\speech_trial\tool\download_models.ps1
```

They land in `spikes/speech_trial/models/` (git-ignored). Each model's licence must be checked before anything
is shipped; this trial only runs them locally.

## Run

```powershell
cd spikes\speech_trial
flutter run -d <android-device-id>   # main target
flutter run -d windows               # desktop check
```

Tests run in airplane mode. Battery and speed numbers only count on a low-cost phone.
