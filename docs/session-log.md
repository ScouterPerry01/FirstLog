<!--
File path and name: docs/session-log.md
Modified On Timestamp: 2026-11-07 @ 21:08 EST
Created On Timestamp: 2026-11-07 @ 21:08 EST
File Description: Append-only session history, newest first.
Uses: N/A (historical record).
Used By: Claude Code on demand; the end-session skill adds a block at the top.
Purpose: Preserve what happened, session by session, without paying for it in context.
-->

# FirstLog — Session log

**Append-only. Add each new session as a block at the TOP (just below this header). Do not rewrite or condense
earlier blocks. Keep each block to ~5-10 lines - detail belongs in that day's handover file.**

When this file passes ~40 KB, move it to `docs/archive/session-log-through-<date>.md` and start a fresh one.

---

## 2026-11-07 19:00 -> 21:08 EST - Repo, licence, stack decision, Flutter setup

- Public GitHub repo created (`f72d9bf`); licence decided GPL-3.0 and recorded in the Requirements (`9834ad1`).
- Register `docs/outstanding-and-deferred-items.md` and App.Tracker project `FLOG` set up (FLOG-1..25).
- Decision 0001: Flutter; installed apps capture, web mainly review/reports (`c9f2d45`); `docs/NOW.md` added.
- Flutter 3.47.9 installed; `flutter doctor` clean; throwaway app ran on Windows, web (`-d web-server`) and an
  Android 16 phone. `-d chrome` fails (browser relaunches itself; security software suspected - N4).
- No FirstLog code yet, so no tests run. Builds were the throwaway app only (`flutter build windows/web`, `flutter run`).
