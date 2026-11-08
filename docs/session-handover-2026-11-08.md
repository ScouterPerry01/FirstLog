<!--
File path and name: docs/session-handover-2026-11-08.md
Modified On Timestamp: 2026-11-08 @ 17:21 EST
Created On Timestamp: 2026-11-08 @ 17:21 EST
File Description: Handover for 2026-11-08: decision 0002, the N1 speech trial build and English phone runs 1-2.
Uses: docs/decisions/0002-voice-interaction-command-driven-capture.md, spikes/speech_trial/,
      docs/outstanding-and-deferred-items.md.
Used By: the next session (NOW.md points to the sections to read).
Purpose: Detail that does not belong in NOW.md or the session log.
-->

# Session handover — 2026-11-08

## 1. Commits

| Commit | Branch | What |
|---|---|---|
| `e61fdb9` | main | Decision 0002: key phrases + command-driven dictation (N7 done) |
| `1a1c73a` | spike/n1-speech-trial | Trial project created, model download script |
| `d2a893d` | spike/n1-speech-trial | Voice loop, set-ups A/B, offline prompts, logging |
| `988ded1` | spike/n1-speech-trial | Mic kept running through prompts; mic level and diagnostics |
| `725bc75` | spike/n1-speech-trial | Fixes from EN runs 1-2 (§4) |

All pushed. The wrap-up commit follows on the spike branch.

## 2. Environment and how to run (details in `spikes/speech_trial/README.md`)

- Flutter: `C:\Users\PSchi\develop\flutter\bin\flutter.bat`. adb: `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`.
  Phone: Galaxy S22, serial R5CT61X3ZTT. Package `io.github.scouterperry01.speech_trial`.
- Build + install: `flutter build apk --release`, then `adb -s R5CT61X3ZTT install -r build\app\outputs\flutter-apk\app-release.apk`
  (keeps the pushed models).
- Pull logs: `& .\tool\push_models_android.ps1 -Device R5CT61X3ZTT -PullLogs` → `trial-logs/` (git-ignored; has speech).
- Self-test: `flutter build windows --debug`, then `Start-Process build\windows\x64\runner\Debug\speech_trial.exe
  -ArgumentList '--selftest' -Wait` → `trial-logs\selftest.txt`. It replays every phone dictation in `trial-logs`.
- Traps: the phone must be unlocked for remote taps; PowerShell here-strings piped to `git commit -F -` fail (use
  a message file); never call bare `python` (Store stub hangs) - use the full path.
- sherpa_onnx pinned at 1.13.8 (2.x drops espeak-ng, so Piper voices go silent). Streaming token times restart at
  each reset; tokens come back with a leading space, not "▁".

## 3. Phone runs (EN, Galaxy S22) - findings

Runs `20261108-141203/141941` (run 1), `161735` (run 2, echo cancellation on), `162554` (echo off), `163225`
(earbuds). Owner had a cold.

- Works: loop with the screen locked; **0 false triggers** in ~4 min of normal talk; keywords inside a sentence
  never start a dictation; "stop dictation" works; battery 100→98 % in ~22 min; Canary 0.3-1.2 s per dictation.
- **Canary (B) is far more accurate than A**, and A often loses the start of a dictation, so B should be the saved
  text and A should only listen for commands. Input for decision 0003.
- Problems found, all fixed in §4: the mic was stopped by prompts; the app heard its own prompts; Canary invented
  "T S F F F…" over silence; the end phrase stayed in Canary's text; 9-1-1 missed about 8 times when misheard;
  the 9-1-1 prompt triggered 9-1-1 again; Android echo cancellation added 54 phantom "and"s and removed no echo;
  prompts weren't heard on Bluetooth earbuds; "Scene info" heard as "scene impul".

## 4. Fixes in `725bc75` (checked: analyze clean, 17/17 unit tests, Windows self-test) - not yet run by a person

- Echo: the app strips its own prompt from the start of the next utterance, plus one short word the cue tone may
  be heard as. Android echo cancellation removed.
- Canary: Silero VAD; repeated words or letters removed and logged (ST-4); audio cut where A heard the end phrase,
  minus 300 ms (the self-test sweep gave 14/15 clean). The saved recording is complete (VC-3). Known leftover:
  when A misses the end phrase there is no cut, and text like "Plug End." can remain.
- 9-1-1 (EM-2, VC-10): close matches (≤0.2 of letters differ) and "nine one one" on its own; the prompt is now
  "Emergency call heard…"; the echo of a read-back that contains the phrase is ignored, so a real 9-1-1 said
  during a read-back is only caught after it ends.
- Cues: tones + vibration (`vibration` 3.2.1) + 300 ms of silent lead-in for Bluetooth; switch on screen.
- Hotwords for set-up A (benefit unproven; greedy BPE split); key phrases "scene report", "vital", "stop dictation".

## 5. Owner observations to carry forward

- With earbuds the state was unclear without looking; cues are the attempted fix and need checking in run 3.
- The owner asked whether other words should be accepted for commands. Agreed: wait for run 3's near-miss log,
  then choose. The options table (scene report / location, observations, care given, medical history, end
  dictation…) is in the conversation; decision 0002 says the final phrases come from the trial results.

## 6. Open items

- EN run 3, then the FR script and run (French end phrases "arrête la dictée" / "fin de dictée" untested).
- Step 3 battery test (low-cost phone), step 5 results doc, draft decision 0003.
- FLOG-22's title in App.Tracker still says "plus browser build" (moved to N5); rename when the tool allows.
- Possibly true BPE tokenization for hotwords (EN `bpe.model` exists).
- Owner: delete `C:\Program Files\speech_trial` (left by an early failed Windows build).

## Resume prompt

```text
Resume FirstLog. Read docs/NOW.md first, then docs/session-handover-2026-11-08.md sections 3-6 only.
Guardrails: ask me before every commit, push, tag, branch operation or destructive command, and show the diff first.
Standing rules:
- The Requirements and Background documents are the source of truth; raise conflicts, don't edit them unasked. Refer to requirement IDs (VC-n, ST-n, EM-n...).
- Flutter is C:\Users\PSchi\develop\flutter\bin\flutter.bat; web runs use flutter run -d web-server.
- Use the full Python path for App.Tracker (C:\Users\PSchi\AppData\Local\Python\bin\python.exe -I), never "python".
- Commit messages go in a file (git commit -F <file>); piped here-strings fail.
- Phone work: unlock the phone first; logs via tool\push_models_android.ps1 -PullLogs; trial-logs/ holds speech and stays out of git.
- Timestamps in Gatineau EST/EDT.
Keep App.Tracker (FLOG-n) and the register updated as items start and finish.
First:
1. Check git status on spike/n1-speech-trial; if the 2026-11-08 wrap-up commit is missing, show me and wait.
2. When I've done EN run 3, pull the logs and compare with runs 1-2 (cues, earbuds, 9-1-1, end-phrase cut, scene report).
3. Then propose the French script and confirm scope before editing.
I will do myself: EN run 3 and the FR run on the phone, the final key-phrase choice, deleting C:\Program Files\speech_trial, and finding a low-cost phone.
```
