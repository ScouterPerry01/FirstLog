<!--
File path and name: README.md
Modified On Timestamp: 2026-11-07 @ 19:06 EST
Created On Timestamp: 2026-11-07 @ 19:06 EST
File Description: Public front page of the FirstLog repository.
Uses: FirstLog – Requirements.md, FirstLog – Background & Feasibility.md, LICENSE
Used By: GitHub repository home page; new contributors
Purpose: Explain what FirstLog is, its current status, and where the source-of-truth documents live.
-->

# FirstLog

FirstLog is a free, open-source, multilingual app that lets a first aider document an incident
hands-free, by voice, while giving care. It turns what is said, seen and photographed into a
structured record per casualty, supports 9-1-1 calls and multi-casualty triage, and hands over a
clean record to EMS, with summary and detailed reports afterward.

> **Status: planning.** There is no application code yet. The requirements and feasibility study
> below describe what is being built.

## What it will do

- Voice capture and transcription for the whole incident, organized into structured fields
- Multiple casualties, each with its own record, plus a scene-level record
- Multiple first aiders, with one designated Primary (incident lead)
- Voice-triggered 9-1-1 call support and capture of the call
- Brief protocol reminders, only when the user asks for one
- Photos linked to the scene, casualties, injuries and responders
- A live EMS update, a transfer-of-care record, and summary and detailed PDF reports

## Guiding principles

- **Care comes first.** The app must never block, delay or replace a 9-1-1 call.
- **No first aid advice.** FirstLog records; it does not diagnose or direct care.
- **Offline and private.** Works with no internet; data stays on the device unless the user shares it.
- **Nothing invented.** Every structured item links back to the transcript it came from.

## MVP platforms

Android, Windows, Linux and modern web browsers, in English and French.
Apple devices (iPhone, iPad, Mac) and smartwatches are not supported in the MVP.

## Documents

- [FirstLog – Requirements](<FirstLog – Requirements.md>): scope, workflows, requirement IDs,
  data model, reports, non-functional requirements and release phases
- [FirstLog – Background & Feasibility](<FirstLog – Background & Feasibility.md>): existing
  solutions, feasibility constraints and effort estimates

## Contributing

Ideas, questions and feedback are welcome in the [issue tracker](../../issues).
Please refer to requirement IDs (for example TR-6 or PR-4) where relevant.

## Licence

FirstLog is licensed under the [GNU General Public License v3.0](LICENSE).
