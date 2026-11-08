<!--
File path and name: docs/NOW.md
Modified On Timestamp: 2026-11-08 @ 17:21 EST
Created On Timestamp: 2026-11-07 @ 19:59 EST
File Description: The ONE short "where are we right now" file. Read this first when resuming.
Uses: docs/session-log.md, docs/session-handover-2026-11-08.md, docs/outstanding-and-deferred-items.md.
Used By: Claude Code at the start of every session; the end-session skill rewrites it.
Purpose: Keep current state out of the always-loaded CLAUDE.md.
-->

# NOW — FirstLog

> **This file is OVERWRITTEN at the end of every session, never appended to. Keep it under ~40 lines.**
> History goes in `docs/session-log.md`; detail in the day's handover file.

**As of:** 2026-11-08 17:21 EST

**Branch:** `spike/n1-speech-trial` at `725bc75`, pushed (plus this wrap-up commit). `main` has decision 0002.
Phase: N1 speech trial (FLOG-22), code in `spikes/speech_trial/` - throwaway, not the FirstLog app.

**Just finished:** Decision 0002 (key phrases + command-driven dictation). Trial app built: voice loop, set-up A
(sherpa-onnx streaming zipformer) and B (Canary-180m + Silero VAD), offline Piper prompts, logging, self-test.
English phone runs 1-2 on the Galaxy S22, and two rounds of fixes from them (handover §3-§4). The run-2 fixes
(`725bc75`) are installed on the phone but **not yet run by a person**.

**NEXT:**
1. EN run 3 with the run-2 fixes (same script; "Scene report" in 2a; one run with earbuds) - pull logs, compare.
2. French script and run.
3. Step 3: battery test on a low-cost phone; step 5: `docs/spikes/n1-speech-trial-results.md`; draft decision
   0003 (speech engine). Early finding: Canary (B) for dictation text, A only for commands.

**Waiting on the developer:**
- Run 3 (EN) and the FR run on the phone. Final key-phrase choice (decision 0002 left them as examples).
- Delete the stray folder `C:\Program Files\speech_trial` by hand (the tool may not).
- A low-cost Android phone for battery/speed. N2 (FLOG-23), N4 (FLOG-25), open questions 2.1-2.6, gates 3.1-3.4.

**To resume, read ONLY:** this file, then `docs/session-handover-2026-11-08.md` §3-§6. `spikes/speech_trial/README.md`
explains how to build, push models, pull logs and run the self-test.

**Standing state:** Ask before every commit / push / branch op. Requirements and Background are the source of
truth - raise conflicts, do not edit them unasked. Web runs use `flutter run -d web-server` until N4 is resolved.
