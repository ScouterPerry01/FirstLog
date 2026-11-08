<!-- File path and name: docs/outstanding-and-deferred-items.md
     Modified On Timestamp: 2026-11-07 @ 19:28 EST
     Created On Timestamp: 2026-11-07 @ 19:28 EST
     File Description: The authoritative register of every OUTSTANDING and DEFERRED item still to be addressed in
                       FirstLog. Each item is defined, given a status, and flagged as a release gate or not.
     Uses: the code and git history (the authority), CLAUDE.md, FirstLog – Requirements.md,
           FirstLog – Background & Feasibility.md.
     Used By: session planning, the release checklist, and the App.Tracker sync (each row is one App.Tracker item).
     Purpose: One place where nothing outstanding gets lost between sessions.
-->

# FirstLog — Outstanding & Deferred Items (master register)

**When an item changes, update its row here in the same commit.** Each row is mirrored as one App.Tracker item
(project `FLOG`): the row's **#** is the key that starts the App.Tracker title.

## How to read this

Each item carries a **gate** flag:

| Flag | Meaning |
|------|---------|
| 🔴 **RELEASE GATE** | Must be resolved before any real / production use. Non-negotiable. |
| 🟠 **SECURITY** | A real weakness, mitigated for now (e.g. dev-only, no real data). Becomes a release gate once reachable. |
| 🟡 **FUNCTIONAL** | A feature is stubbed, partial or not yet built. Affects completeness, not safety. |
| ⚪ **HOUSEKEEPING** | Clean-up, tech debt, tests or cosmetic. Low risk. |

and a **status**: **DONE** (kept for one revision so the change is visible, then removable), **PARTLY DONE**,
**OPEN** (not started), **DEFERRED** (decided to do later - say why), **CLOSED** (no longer applies - the premise
was wrong or it was superseded). "UNVERIFIED" marks a status read from docs that a code check could not confirm.

Status → App.Tracker: OPEN = Accepted (or Proposed if not yet agreed), PARTLY DONE = In Progress, DONE = Done,
DEFERRED = Deferred, CLOSED = Rejected.

There is no application code yet; every OPEN item below comes from the two source-of-truth documents.

---

## 1. Project setup and decisions ⚪

| # | Item | Gate | Status | Evidence / what remains |
|---|------|------|--------|-------------------------|
| 1.1 | Create the public GitHub repository | ⚪ | **DONE** | github.com/ScouterPerry01/FirstLog, commit `f72d9bf` |
| 1.2 | Choose the open-source licence and record it in the Requirements | ⚪ | **DONE** | GPL-3.0: `LICENSE` (`f72d9bf`); Requirements "Open source" + open question updated in this commit |
| 1.3 | Choose the tech stack: Flutter or Progressive Web App | 🟡 | **OPEN** | Requirements → Non-functional → Platforms; blocks all MVP build work |
| 1.4 | Set up session context: `docs/NOW.md` and `docs/session-log.md` | ⚪ | **OPEN** | Run the `organize-project-context` skill |

## 2. Open questions from the Requirements 🟡

| # | Item | Gate | Status | Evidence / what remains |
|---|------|------|--------|-------------------------|
| 2.1 | Which triage protocols in the first release (START only, or also SALT / JumpSTART)? | 🟡 | **OPEN** | Requirements → Open questions |
| 2.2 | Which organizations' protocol texts can FirstLog use, and under what licence or permission? | 🔴 | **OPEN** | Requirements → Open questions; protocol reminders (PR) can't ship without permission |
| 2.3 | Which languages after English and French? | 🟡 | **OPEN** | Requirements → Open questions; MVP needs EN + FR only |
| 2.4 | Which first aid organizations and EMS services can review the handover format? | 🟡 | **OPEN** | Requirements → Open questions; feeds item 3.4 |
| 2.5 | Is optional cloud sync needed for organizations in v1, or later? | 🟡 | **OPEN** | Requirements → Open questions; must be self-hostable if built |
| 2.6 | Contact the Peak Response project about reusing its work | 🟡 | **OPEN** | Background & Feasibility → Complexity and effort |

## 3. Legal, regulatory and review gates 🔴

| # | Item | Gate | Status | Evidence / what remains |
|---|------|------|--------|-------------------------|
| 3.1 | Legal review: recording consent and privacy obligations in each launch region | 🔴 | **OPEN** | Requirements → Open questions; Law 25, PIPEDA, provincial acts, GDPR, HIPAA |
| 3.2 | Regulatory review (e.g. Health Canada) confirming FirstLog is not a medical device | 🔴 | **OPEN** | Requirements → Risks (software as a medical device) |
| 3.3 | Independent security review before the first public release | 🔴 | **OPEN** | Requirements → Security and privacy |
| 3.4 | MVP reviewed by at least one first aid instructor and one paramedic | 🔴 | **OPEN** | Requirements → "MVP is done when" |

## 4. MVP build (phase 1) 🟡

| # | Item | Gate | Status | Evidence / what remains |
|---|------|------|--------|-------------------------|
| 4.1 | Offline voice capture and transcription | 🟡 | **OPEN** | Requirements → Voice capture and transcription; ≥90% of test-script vitals/treatments in the right casualty |
| 4.2 | Structuring into per-casualty and scene records, every item linked to its transcript | 🟡 | **OPEN** | Requirements → Structuring the information (ST-4) |
| 4.3 | Multiple casualties, triage and hands-free casualty switching | 🟡 | **OPEN** | Requirements → Casualties and triage |
| 4.4 | "Call 9-1-1" handoff to the dialer in under 2 seconds | 🟡 | **OPEN** | Requirements → 9-1-1 support (EM-2: never block or delay the call) |
| 4.5 | Photos linked to scene, casualties, injuries and responders | 🟡 | **OPEN** | Requirements → Photos and media |
| 4.6 | EMS summary (PDF in under 30 s) and summary + detailed reports in EN and FR | 🟡 | **OPEN** | Requirements → Reports; EMS handover |
| 4.7 | Brief protocol reminders, on request only | 🟡 | **OPEN** | Requirements → Protocols on request (PR-4, PR-5); depends on 2.1 and 2.2 |

## N. Findings (new items found while working)

New findings get the next **N-number** (N1, N2, ...) and go here AND into App.Tracker in the same session.

| # | Item | Gate | Status | Evidence / what remains |
|---|------|------|--------|-------------------------|
| | *(none yet)* | | | |

---

## Release gate — the short list 🔴

Every 🔴 row above, one line each, so the release check is a single read.

1. 2.2 - Permission to use protocol texts
2. 3.1 - Legal review: recording consent and privacy
3. 3.2 - Regulatory review (medical-device status)
4. 3.3 - Independent security review
5. 3.4 - MVP review by a first aid instructor and a paramedic
