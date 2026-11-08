<!--
File path and name: docs/NOW.md
Modified On Timestamp: 2026-11-07 @ 21:08 EST
Created On Timestamp: 2026-11-07 @ 19:59 EST
File Description: The ONE short "where are we right now" file. Read this first when resuming.
Uses: docs/session-log.md, docs/session-handover-2026-11-07.md, docs/outstanding-and-deferred-items.md.
Used By: Claude Code at the start of every session; the end-session skill rewrites it.
Purpose: Keep current state out of the always-loaded CLAUDE.md.
-->

# NOW — FirstLog

> **This file is OVERWRITTEN at the end of every session, never appended to. Keep it under ~40 lines.**
> History goes in `docs/session-log.md`; detail in the day's handover file.

**As of:** 2026-11-07 evening

**Branch:** `main` (only branch), pushed to github.com/ScouterPerry01/FirstLog (public, GPL-3.0). Last code-free
docs commit: the 2026-11-07 wrap-up. Phase: planning - no FirstLog application code yet.

**Just finished:** Repo, licence, register + App.Tracker `FLOG`, stack decision (Flutter; web mainly review and
reports - `docs/decisions/0001-tech-stack-flutter.md`). Flutter dev environment set up on the Windows PC and
verified with a throwaway counter app on Windows, web (`-d web-server`) and an Android phone.

**NEXT:** N1 (FLOG-22) - plan, then build, the speech trial: offline English + French recognition on Android with
the screen locked, plus a browser build. Plan the scope with the developer before creating the Flutter project.

**Waiting on the developer:**
- N2 (FLOG-23): do the offline / MVP acceptance rules apply only to the installed apps for hands-free capture?
- A low-cost Android phone for N1's battery and speed results (the current dev phone is a flagship).
- N4 (FLOG-25): optional 2-minute test of whether security software blocks `flutter run -d chrome`.
- Open questions 2.1-2.6 and 🔴 gates 3.1-3.4 in the register.

**To resume, read ONLY:** this file, then `docs/session-handover-2026-11-07.md` §4 (dev environment) and §5 (open
items). Read the Requirements by heading, not whole.

**Standing state:** Ask before every commit / push. Requirements and Background are the source of truth - raise
conflicts, do not edit them unasked. Web runs use `flutter run -d web-server` until N4 is resolved.
