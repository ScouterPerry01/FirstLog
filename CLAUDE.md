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
