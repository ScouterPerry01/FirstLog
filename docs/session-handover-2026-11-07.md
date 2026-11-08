<!--
File path and name: docs/session-handover-2026-11-07.md
Modified On Timestamp: 2026-11-07 @ 21:08 EST
Created On Timestamp: 2026-11-07 @ 21:08 EST
File Description: Detailed handover for the 2026-11-07 session (numbered sections).
Uses: docs/NOW.md, docs/outstanding-and-deferred-items.md, docs/decisions/0001-tech-stack-flutter.md.
Used By: the next session (read only the sections NOW.md names).
Purpose: Keep the detail of this session findable without loading it every time.
-->

# FirstLog — Session handover 2026-11-07

## 1. Repository and licence

- Public repo: github.com/ScouterPerry01/FirstLog. Issues on; Wiki and Projects off; topics set.
- Licence GPL-3.0 (`LICENSE`, official text from GitHub's licence API; GitHub detects it as GPL-3.0).
- Requirements "Open source" line and open question updated (`9834ad1`). Both requirement documents got header
  comment blocks; their "Created" time is the first commit time because the real one is unknown.

## 2. Tracking

- Register `docs/outstanding-and-deferred-items.md`: sections 1 setup, 2 open questions, 3 🔴 gates, 4 MVP build,
  N findings. Mirrored as App.Tracker project `FLOG` (database `rann`): FLOG-1..21 from the register, then
  FLOG-22 (N1), FLOG-23 (N2), FLOG-24 (N3), FLOG-25 (N4).
- Register 2.2 (permission to use protocol texts) was flagged 🔴 by Claude's judgment, not by the Requirements.

## 3. Stack decision

- `docs/decisions/0001-tech-stack-flutter.md`: Flutter; installed apps are the capture tool; web mainly review and
  reports. Uno Platform (C#) was the runner-up. Requirements → Platforms and project `CLAUDE.md` updated (`c9f2d45`).
- Reason: offline on-device EN/FR speech that keeps listening with the screen locked needs native code and an
  Android foreground service; browsers can't do that.

## 4. Developer environment (Windows PC)

- Flutter SDK 3.47.9 (stable, Dart 3.13.7), git clone at `C:\Users\PSchi\develop\flutter`; its `bin` was added to
  the user PATH (ExpandString kept). Analytics not disabled (optional: `flutter --disable-analytics`).
- `flutter doctor`: no issues (Android SDK 37, command-line tools + licences done by the developer in Android
  Studio; Visual Studio 2026 C++ workload; Chrome).
- VS Code extensions `dart-code.flutter` and `dart-code.dart-code` v3.146.0 (installed from the command line).
- Android: Galaxy S22 (SM-S901W, Android 16) authorised for USB debugging; flagship, so not valid for N1's
  low-cost battery/speed results.
- **Trap - NDK install:** Gradle's automatic NDK install fails ("Package ndk not found") because the newest
  cmdline-tools replaced `sdkmanager` with the `android` CLI, which uses slash names. Fix: install the version the
  build asks for with `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\android.exe sdk install ndk/<version>`
  (done for 28.2.13676358, 2.1 GB).
- **Trap - `flutter run -d chrome` fails** ("Failed to launch browser after 3 tries"), also in the developer's own
  terminal. Cause found: the launched chrome.exe starts a second browser process and exits silently, so Flutter
  never sees "DevTools listening". Edge does the same. Not a Chrome policy or launch redirection. Suspected:
  security software injected into the browser (unproven). Workaround that works:
  `flutter run -d web-server --web-port 8765`, then open http://localhost:8765. Tracked as N4.
- Throwaway test app at `C:\Users\PSchi\develop\hello_flutter` (outside the repo; safe to delete).

## 5. Open items for next time

- N1 (FLOG-22) speech trial build - next step; plan scope first (engine candidates: sherpa-onnx, whisper.cpp, Vosk).
- N2 (FLOG-23) - developer to answer: do offline / MVP rules apply only to installed apps for capture?
- N4 (FLOG-25) - optional: test the security-software theory for `-d chrome`.
- Open questions 2.1-2.6 and 🔴 gates 3.1-3.4 unchanged.

## Resume prompt

```text
Resume FirstLog. Read docs/NOW.md first, then docs/session-handover-2026-11-07.md sections 4 and 5 only.

Guardrails: ask me before every commit, push, tag, branch operation or destructive command, and show the diff first.

Standing rules:
- The Requirements and Background documents are the source of truth; raise conflicts, don't edit them unasked.
- Refer to requirement IDs (e.g. EM-2, ST-4) in code comments and commits.
- Stack is Flutter (decision 0001); the web version is mainly for review and reports.
- Use the full Python path for App.Tracker (see the app-tracker-sync skill), never "python".
- Web runs: flutter run -d web-server (-d chrome fails on this PC, see N4).
- Missing NDK: install with "android sdk install ndk/<version>" from cmdline-tools\latest\bin.
- Timestamps in headers: current Gatineau local time (EST/EDT).

Keep App.Tracker (FLOG-n) and the register updated as items start and finish.

First:
1. Show git status; if the 2026-11-07 wrap-up commit is not on main, stop and tell me.
2. Propose a plan and scope for N1 (FLOG-22), the offline EN/FR speech trial build, and confirm with me before
   creating the Flutter project or editing anything.

I will do myself: answer N2 (offline/MVP rules for web vs installed apps), get a low-cost Android test phone,
and optionally test the security-software theory for flutter run -d chrome (N4).
```
