<!--
File path and name: spikes/speech_trial/README.md
Modified On Timestamp: 2026-11-08 @ 06:23 EST (voice loop, self-test, phone scripts, sherpa_onnx pin)
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

Key phrases are currently spotted by matching set-up A's text. A dedicated keyword spotter (sherpa-onnx KWS,
English only) is downloaded for comparison but not wired in yet.

Spoken prompts use sherpa-onnx text-to-speech with Piper voices (EN `amy-low`, FR `siwis-medium`).

**sherpa_onnx is pinned to 1.13.8.** Version 2.x removed the built-in espeak-ng pronunciation engine, so Piper
voices produce no audio there (it asks for an external phonemizer). 1.13.8 still has espeak-ng and already has
Flutter web support (since 1.13.5).

## Get the models (not in git)

```powershell
& .\spikes\speech_trial\tool\download_models.ps1          # ~550 MB on disk, into spikes/speech_trial/models/
& .\spikes\speech_trial\tool\push_models_android.ps1      # copy them to the phone (install the app once first)
```

`models/` and `trial-logs/` are git-ignored. Each model's licence must be checked before anything is shipped;
this trial only runs them locally.

## Run

```powershell
cd spikes\speech_trial
flutter run -d <android-device-id>   # main target; then lock the screen and keep talking
flutter run -d windows               # desktop check
flutter build windows --debug; Start-Process build\windows\x64\runner\Debug\speech_trial.exe -ArgumentList '--selftest' -Wait
                                     # hands-off engine check -> trial-logs\selftest.txt
& .\tool\push_models_android.ps1 -PullLogs   # copy phone logs to trial-logs\
```

The voice loop: tap **Start trial** → "New first aid log, or continuing?" → say "New" → "Ready…" + date and time →
say a field keyword ("Scene info", "Vitals", "Treatment", "History") → "Proceed" → dictate → "FirstLog end" →
"Saved". "Read back" reads the last dictation. "Call 9-1-1" is logged and answered, **never dialled**.

Tests run in airplane mode. Battery and speed numbers only count on a low-cost phone.

**Windows build trap:** if the very first `flutter build windows` fails part-way, CMake can remember
`C:\Program Files\speech_trial` as its install folder, and later builds then put the DLLs there and the exe
fails with 0xC0000135. Fix: delete `build\windows` and build again.
