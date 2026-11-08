<!--
File path and name: docs/NOW.md
Modified On Timestamp: 2026-11-07 @ 19:59 EST
Created On Timestamp: 2026-11-07 @ 19:59 EST
File Description: The ONE short "where are we right now" file. Read this first when resuming.
Uses: docs/session-log.md, the current handover file, docs/outstanding-and-deferred-items.md.
Used By: Claude Code at the start of every session; the end-session skill rewrites it.
Purpose: Keep current state out of the always-loaded CLAUDE.md.
-->

# NOW — FirstLog

> **This file is OVERWRITTEN at the end of every session, never appended to. Keep it under ~40 lines.**
> History goes in `docs/session-log.md`; detail in the day's handover file.

**As of:** 2026-11-07 evening

**Branch:** `main` (only branch), pushed to github.com/ScouterPerry01/FirstLog (public, GPL-3.0).
Phase: planning - no application code yet.

**Just finished:** Public repo created; licence decided (GPL-3.0); outstanding-items register and App.Tracker
project `FLOG` set up; tech stack decided: **Flutter**, web version mainly for review and reports
(`docs/decisions/0001-tech-stack-flutter.md`).

**NEXT:** N1 - trial build (spike) of offline English + French speech on a low-cost Android phone with the screen
locked, plus a browser build. Before starting: install the Flutter SDK and confirm the test phone; plan the spike
with the developer first.

**Waiting on the developer:** N2 - confirm the offline / MVP acceptance criteria apply to the installed apps for
hands-free capture (not the web version). Open questions 2.1-2.6 and the 🔴 gates 3.1-3.4 in the register.

**To resume, read ONLY:** this file, then `docs/outstanding-and-deferred-items.md` (short). Read the Requirements
by heading, not whole.

**Standing state:** Ask before every commit / push. Requirements and Background are the source of truth - raise
conflicts, do not edit them unasked.
