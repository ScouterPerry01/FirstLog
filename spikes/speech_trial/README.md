<!--
File path and name: spikes/speech_trial/README.md
Modified On Timestamp: 2026-11-08 @ 16:58 EST (switches, cues, no echo cancellation, Canary clean-up, phone runs 1-2)
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
say a field keyword ("Scene info" / "Scene report", "Vitals", "Treatment", "History") → "Proceed" → dictate →
"First Log end" or "Stop dictation" → "Saved". "Read back" reads the last dictation. "Call 9-1-1" (also a close
mishearing, or "nine one one" said on its own) is logged and answered, **never dialled**.

Switches on the screen (all logged in `run-start`):

- **Canary (set-up B)**: also transcribe each dictation with Canary.
- **Key-phrase hotwords**: bias set-up A towards the key phrases (needs modified_beam_search; more CPU).
- **Tones and vibration**: a rising tone + one buzz before "Proceed"/"Ready", two beeps + two buzzes before
  "Saved", three high beeps + a long buzz before the 9-1-1 answer, so the state is clear without the screen.
  Every prompt starts with 300 ms of silence so Bluetooth earbuds are awake before the sound starts.

What the trial learned so far and built in:

- **No Android echo cancellation.** On the S22 its "voice communication" mode removed no echo and made set-up A
  hear a phantom "and" about once a second, which also stopped dictations ending on silence. Instead the app
  strips its own prompt from the start of the next utterance (`echo-stripped` in the log), including a short
  word the cue tone is sometimes heard as.
- **Canary hears only the dictation:** the Silero voice detector drops silence (Canary invented "T T T…" over
  silence), runs of repeated words or letters are removed and logged, and the audio is cut where set-up A heard
  the end phrase start, moved 300 ms earlier because the streaming model reports words slightly late (picked from
  the self-test on the phone recordings: 14 of 15 clean). The saved recording stays complete (VC-3).
- The self-test also replays every dictation recorded on the phone (`trial-logs/run-*/audio`), checks the word
  timing and whether the cue tones are heard as words.

Tests run in airplane mode. Battery and speed numbers only count on a low-cost phone.

**Windows build trap:** if the very first `flutter build windows` fails part-way, CMake can remember
`C:\Program Files\speech_trial` as its install folder, and later builds then put the DLLs there and the exe
fails with 0xC0000135. Fix: delete `build\windows` and build again.
