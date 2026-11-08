<!-- File path and name: docs/outstanding-and-deferred-items.md
     Modified On Timestamp: 2026-11-08 @ 16:58 EST
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
| 1.2 | Choose the open-source licence and record it in the Requirements | ⚪ | **DONE** | GPL-3.0: `LICENSE` (`f72d9bf`); Requirements "Open source" + open question updated (`9834ad1`) |
| 1.3 | Choose the tech stack: Flutter or Progressive Web App | 🟡 | **DONE** | Flutter; web mainly review/reports - `docs/decisions/0001-tech-stack-flutter.md`, Requirements → Platforms, `CLAUDE.md` |
| 1.4 | Set up session context: `docs/NOW.md` and `docs/session-log.md` | ⚪ | **DONE** | `docs/NOW.md` (`c9f2d45`); `docs/session-log.md` and first handover added at the 2026-11-07 wrap-up |

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
| N1 | Trial build (spike) on Android: key-phrase listening with the screen locked (reliability, battery), offline EN + FR dictation accuracy, end-phrase spotting; picks the speech engine | 🟡 | **PARTLY DONE** | Scope per decision 0002; step 0 research done 2026-11-08 (sherpa-onnx streaming + Canary-180m set-ups; Vosk fallback). Code in `spikes/speech_trial/` on branch `spike/n1-speech-trial`. Step 2 (voice loop, both set-ups, logging) built; Windows self-test OK. **EN phone runs 1-2 done 2026-11-08 (Galaxy S22):** loop works with the screen locked; zero false triggers in ~4 min of normal talk; keywords inside sentences never fire; Canary (B) far more accurate than A, so B is the saved text and A only listens for commands; battery 100→98 % in ~22 min. Fixed after the runs: mic stopped by prompts, own-voice echo, Canary invented text over silence, end phrase left in the text (audio now cut at the end phrase), 9-1-1 missed when misheard and triggered by the app's own prompt (EM-2), Android echo cancellation removed (phantom words), tones/vibration added (prompts lost on Bluetooth earbuds). "Scene info" misheard as "scene impul" → "scene report" added. Next: EN run 3 with the fixes, then FR. sherpa_onnx pinned to 1.13.8 (2.x dropped espeak-ng, Piper voices silent). Browser part moved to N5. Dev phone is a flagship; battery/speed results need a low-cost phone |
| N2 | Confirm the offline and MVP acceptance criteria apply to the installed apps for hands-free capture, not the web version | 🟡 | **OPEN** | Decision 0001 → Consequences; owner to confirm; Requirements → Offline and performance |
| N3 | Set up the Flutter development environment on the Windows PC | ⚪ | **DONE** | Flutter 3.47.9, `flutter doctor` clean, test app ran on Windows, web and Android - handover 2026-11-07 §4 |
| N4 | `flutter run -d chrome` fails: the browser relaunches itself so Flutter never connects (Edge too) | ⚪ | **OPEN** | Security software on the dev PC suspected, unproven; workaround `flutter run -d web-server` - handover 2026-11-07 §4 |
| N5 | Speech engine in the browser build | 🟡 | **DEFERRED** | Moved out of N1 on 2026-11-08; decide after N2 (browser capture is best effort only, decision 0001). Correction 2026-11-08: `sherpa_onnx` supports Flutter web via WebAssembly since 1.13.5 (the step-0 "no web" finding came from an older version's pub.dev page), so this is mostly a test, not a bridge to build. Trial project created without the web platform; add with `flutter create --platforms web .` |
| N6 | External / paid speech engines as a plug-in | ⚪ | **DEFERRED** | Owner idea 2026-11-08. Conditions: on-device only (VC-2, no cloud), user warning, GPL-3.0 route (separate app via the OS, or a licence exception). Needs its own decision record; revisit after N1 shows whether open-source engines are good enough |
| N7 | Voice interaction model: key phrases + command-driven dictation, no continuous recording | 🟡 | **DONE** | Decision 0002 and Requirements edits, owner-approved 2026-11-08, committed on branch `spike/n1-speech-trial` |

---

## Release gate — the short list 🔴

Every 🔴 row above, one line each, so the release check is a single read.

1. 2.2 - Permission to use protocol texts
2. 3.1 - Legal review: recording consent and privacy
3. 3.2 - Regulatory review (medical-device status)
4. 3.3 - Independent security review
5. 3.4 - MVP review by a first aid instructor and a paramedic
