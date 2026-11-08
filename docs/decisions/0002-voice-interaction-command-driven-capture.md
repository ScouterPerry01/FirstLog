<!--
File path and name: docs/decisions/0002-voice-interaction-command-driven-capture.md
Modified On Timestamp: 2026-11-08 @ 03:34 EST
Created On Timestamp: 2026-11-08 @ 03:34 EST
File Description: Decision record 0002 - FirstLog listens for key phrases and records only dictations the user
                  starts; it does not record the scene continuously.
Uses: FirstLog – Requirements.md (Core workflows, Voice capture VC-1..VC-10, Structuring ST-1/ST-2, Offline and
      performance, Risks), docs/decisions/0001-tech-stack-flutter.md.
Used By: CLAUDE.md, FirstLog – Requirements.md, docs/outstanding-and-deferred-items.md (N1, N7), the N1 speech
         trial, all voice capture work.
Purpose: Record how the user talks to FirstLog and why, so it is not re-argued.
-->

# 0002 — Voice interaction: key phrases and command-driven dictation

**Status:** Accepted · **Date:** 2026-11-08 · **Decided by:** the project owner · **Register:** N7

## Context

The Requirements as first written assumed the app records the whole scene from incident start to close and works
out afterwards which words belong to which field and casualty (VC-1 "continuous audio", ST-1 "extract structured
fields from speech", "2 hours of continuous recording"). Decision 0001 carried that battery wording into the
speech trial.

While planning the trial (N1), the owner clarified how they see the app working: the user tells the app what they
are about to say, says it, and tells the app they are done.

## Decision

1. **Listen, don't record.** From launch until the incident is closed, the app listens on the device for its own
   key phrases only, including with the screen locked. It does not record the scene continuously; there is no
   continuous-audio option.
2. **Command-driven dictation.** A field keyword (e.g. "Scene info", "Vitals") starts capture for that field of
   the incident or the selected casualty; the app answers "Proceed". An end phrase (e.g. "FirstLog end") stops
   it. Capture also stops after a set silence, on the next field keyword, or on a Stop tap.
3. **The app speaks, offline, in the user's language:** "New first aid log, or continuing?" on launch; "Ready" with
   the day, date and time; "Proceed"; "Saved". It ignores its own voice.
4. **Read back on request.** By default the app says only "Saved"; "Read back" has it read the saved text aloud.
5. **Audio is kept per dictation**, linked to its transcript (VC-3), not for the whole incident.
6. **"Call 9-1-1" works at any moment**, including mid-dictation and while the app is speaking (EM-2).
7. The phrases above are examples; the final English and French phrases are chosen after the speech trial.

## Options considered

| Option | Outcome | Main reason |
|---|---|---|
| **Key phrases + command-driven dictation** | **Chosen** | User names the field, so nothing is guessed or misassigned; far less audio of bystanders and casualties; a short phrase list is easier to recognize in noise |
| Continuous recording with automatic extraction (original Requirements) | Replaced | Highest risk of putting data in the wrong field or casualty; records everyone on scene; hardest speech and language-processing problem |
| Continuous recording kept as an optional extra | Rejected | Privacy and consent cost (gate 3.1) for little gain once dictations keep their own audio |

## Consequences

- **Requirements updated** (owner-approved, 2026-11-08): Core workflows (stages 1-3 and a new "How voice capture
  works"), VC-1, VC-3, VC-4, new VC-7 to VC-10, ST-1, ST-2, the Transcript segment entity, the battery target,
  one new risk and one new open question (the exact phrases).
- **Battery target** is now 2 hours of *listening* with dictations as needed. This replaces the "2 hours of
  continuous recording" wording in decision 0001 → Consequences; the rest of 0001 stands.
- **The speech trial (N1) now measures three things:** reliable key-phrase listening with the screen locked
  (and its battery cost), accuracy on short English and French dictations, and spotting the end phrase while
  dictating.
- **New needs:** offline text-to-speech in English and French; pausing listening while the app speaks.
- **Not decided here:** the speech engine (decision after N1), the exact phrases, the silence timeout length.
