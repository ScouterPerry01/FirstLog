<!--
File path and name: docs/decisions/0001-tech-stack-flutter.md
Modified On Timestamp: 2026-11-07 @ 19:59 EST
Created On Timestamp: 2026-11-07 @ 19:59 EST
File Description: Decision record 0001 - FirstLog is built with Flutter; the web version is mainly a review and
                  report tool.
Uses: FirstLog – Requirements.md (Platforms, Offline and performance, Security and privacy, release phases),
      FirstLog – Background & Feasibility.md (Feasibility).
Used By: CLAUDE.md, FirstLog – Requirements.md (Platforms), docs/outstanding-and-deferred-items.md (1.3),
         App.Tracker FLOG-3, all build work.
Purpose: Record why the stack was chosen, what was rejected, and what follows from it, so it is not re-argued.
-->

# 0001 — Tech stack: Flutter, with the web version mainly for review and reports

**Status:** Accepted · **Date:** 2026-11-07 · **Decided by:** the project owner · **Register:** 1.3 (FLOG-3)

## Context

The Requirements ask for one shared codebase covering Android, Windows, Linux and modern web browsers in the
MVP (iOS and macOS later), and named two candidates: Flutter or a Progressive Web App (PWA).

The deciding requirement is **offline, on-device speech recognition in English and French that keeps listening
hands-free while the phone is locked or in a pocket** (Voice capture; Offline and performance; data stays on the
device). Screens, photos, PDF reports and the "Call 9-1-1" handoff are straightforward in every option.

What that requirement rules in or out:

- **Browser speech recognition is not acceptable.** Chrome's built-in Web Speech API sends audio to a server,
  which breaks the offline and privacy rules.
- **Speech must come from an open-source engine bundled with the app** (candidates: sherpa-onnx, whisper.cpp,
  Vosk). These are C/C++ libraries, so the stack must call native code on every platform.
- **Browsers cannot keep the microphone running** when the screen locks or the app goes to the background, and
  browser storage can be evicted and is not encrypted by default. Android needs a native foreground service.
- **Version 1 needs device-to-device sync with no internet** (Bluetooth / Wi-Fi Direct / nearby connections),
  which browsers cannot do.

## Decision

1. **FirstLog is built with Flutter (Dart)** as the single shared codebase for Android, Windows, Linux and web,
   and later iOS and macOS.
2. **The installed apps are the capture tool.** Hands-free capture at a scene is designed and tested on the
   installed app, with Android phones as the primary device.
3. **The web version's main purpose is review and reports:** opening and reviewing incident records, correcting
   them, and producing and sharing reports. Capture in the browser is best effort and works only while the page is
   open and in the foreground.

## Options considered

| Option | Outcome | Main reason |
|---|---|---|
| **Flutter** | **Chosen** | All MVP platforms officially supported; native interop (Dart FFI) for on-device speech engines; Android background recording possible; largest contributor pool of the options that fit |
| PWA (web app) | Rejected as the main app | No background recording, evictable and unencrypted storage, no device-to-device sync, offline speech only through heavy WebAssembly |
| Uno Platform (C#) | Runner-up | Covers all four platforms in the owner's own language; smaller community and fewer likely contributors |
| Avalonia UI (C#) | Rejected | Android and browser targets less mature than its desktop target |
| .NET MAUI | Rejected | No Linux and no web support |
| Kotlin Multiplatform | Rejected | Web target the least mature; new language and tooling |
| React Native | Rejected | No official Linux support |
| Tauri 2 | Rejected | Two languages (web + Rust); mobile support newer |

## Consequences

- **New language for the owner:** Dart (close to C#). Tooling: Flutter SDK with VS Code or Android Studio;
  Visual Studio is not the primary IDE for this project.
- **The first build step is a trial build (spike) of the riskiest part:** offline English and French recognition
  on a low-cost Android phone, continuing with the screen locked, plus the same engine in a browser build. Its
  results pick the speech engine and confirm the battery target (2 hours of continuous recording).
- **Requirements wording updated (Platforms):** Flutter named, and the web version described as mainly a review
  and report tool.
- **To confirm with the owner later:** "Every capture, triage and report function works with no internet"
  (Offline and performance) and the MVP acceptance criteria are interpreted as applying to the installed apps for
  hands-free capture. If the web version must meet them too, revisit this decision.
- **Not decided here:** the speech engine, local database and encryption library, PDF library, and state
  management approach. Each gets its own decision record when chosen.
