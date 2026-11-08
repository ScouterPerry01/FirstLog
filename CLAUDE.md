<!--
File path and name: CLAUDE.md
Modified On Timestamp: 2026-11-08 @ 03:34 EST (added voice interaction decision 0002) - earlier: 2026-11-07 @ 19:59 EST (added Architecture decisions and Session context)
Created On Timestamp: 2026-11-07 @ 19:25 EST (first git commit; written earlier the same day)
File Description: Project instructions for Claude Code in the FirstLog repository.
Uses: FirstLog – Requirements.md, FirstLog – Background & Feasibility.md, docs/decisions/, docs/NOW.md,
      docs/outstanding-and-deferred-items.md
Used By: Claude Code, loaded on every turn in this repository.
Purpose: Durable rules, source-of-truth pointers and architecture decisions only - no progress or dates of work.
-->

# FirstLog

FirstLog is a free, open-source, multilingual app that lets a first aider document an incident hands-free, by voice, while giving care, and hand over a clean record to EMS.

## Source of truth

Read these two documents before planning or writing code. They define what FirstLog must do and why:

- `FirstLog – Requirements.md`: scope, roles, workflows, requirement IDs (VC, ST, TR, RS, PR, EM, PH, HO, IR) with M/S/C priorities, data model, reports, non-functional requirements, risks, and release phases with acceptance criteria.
- `FirstLog – Background & Feasibility.md`: existing solutions, feasibility constraints, effort estimates.

If code and these documents disagree, the documents win. Raise the conflict with the user instead of changing the documents on your own. Refer to requirements by their IDs (e.g. TR-6, PR-4) in code comments, commits and PRs.

## Rules that must not be broken

- Care comes first: the app must never block, delay or replace a 9-1-1 call (EM-2).
- The app gives no first aid advice of its own. In the MVP, protocol guidance is only a brief reminder the user asks for (PR-4, PR-5); walkthroughs are a later phase, only after a regulatory review.
- Works with no internet; data stays on the device unless the user shares or syncs it.
- Every structured item links back to the transcript it came from; never invent data (ST-4).

## MVP target

Android, Windows, Linux and modern web browsers. Apple devices (iPhone, iPad, Mac) and smartwatches are out of scope for the MVP.

## Architecture decisions

Decision records live in `docs/decisions/` (one numbered file each). Do not re-argue an accepted decision; propose a new record that replaces it.

- **Stack: Flutter (Dart)**, one codebase for all platforms (`0001-tech-stack-flutter.md`).
- **The installed apps are the capture tool; the web version is mainly for review and reports.** Do not design hands-free capture around the browser.
- Speech recognition runs on the device through a bundled open-source engine; never a cloud or browser speech service. Code against a speech-engine interface so engines can be swapped.
- **Voice interaction: listen for key phrases, record only dictations the user starts** (field keyword → dictation → end phrase); no continuous recording of the scene (`0002-voice-interaction-command-driven-capture.md`).

## Session context

Read `docs/NOW.md` first when resuming. Outstanding work is in `docs/outstanding-and-deferred-items.md`, mirrored in App.Tracker as project `FLOG`.
