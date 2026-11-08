# FirstLog – Requirements

Nov 7, 2026 · @Perry

## Purpose, vision and scope

FirstLog is a free, open-source, multilingual app that lets a first aider document an incident hands-free, by voice, while giving care. It turns what is said, seen and photographed into a structured record per casualty, supports 9-1-1 calls and multi-casualty triage, and produces a clean handover to EMS and reports afterward.

**In scope**

- Voice capture and transcription for the whole incident, organized automatically into structured fields
- Multiple casualties, each with a separate record, plus a scene-level record
- Multiple first aiders, with one designated Primary (incident lead)
- Voice-triggered 9-1-1 call support and capture of the call
- On-request protocol support: list the available protocols (e.g. for triage), then give a brief reminder of the chosen one (a step-by-step walkthrough may be added in a later phase)
- Photos linked to the scene, casualties, injuries and responders
- A live EMS update summary, a transfer-of-care record, and post-incident summary and detailed reports
- All major platforms, offline operation, and multiple languages

**Out of scope (for now)**

- Diagnosis, treatment recommendations or first aid advice of any kind; the only guidance is a brief protocol reminder the user asks for
- Direct integration with any specific EMS or dispatch system (designed for, not built in v1)
- Use as a professional ePCR for paramedics
- Step-by-step protocol walkthroughs (possible later phase, only after a regulatory review)

**Guiding principles**

1. Care comes first: the app must never slow down or block care, or a call to 9-1-1.
2. Hands-free by default; every voice action also has a one-tap equivalent.
3. Works with no signal.
4. Private by design: data stays on the device unless the user chooses to share it.
5. Documents, does not decide: the first aider stays in control of every entry and decision. The app never offers first aid advice on its own; protocol guidance appears only when the user asks for it.

## Users and roles

Every person in an incident has one role, and the record always shows who is the Primary.

| Role | Who | What they can do |
| --- | --- | --- |
| Primary first aider | The person in charge of the scene; exactly one at a time | Start/close the incident, assign casualties and roles, call 9-1-1, hand over to EMS, sign the record |
| Additional first aider | Anyone else giving care | Join an incident, document casualties assigned to them, add photos and notes |
| Bystander / helper (optional) | Non-trained helpers | Named in the record (e.g. who called 9-1-1, who fetched the AED); no app access needed |
| Casualty | Each injured or ill person | Not a user; has a record |
| EMS crew | Paramedics on arrival | Receive the handover (QR, screen, PDF); optionally confirm transfer of care on the Primary's device |
| Organization admin (optional) | Event or workplace first aid coordinator | Manage responder profiles, templates and report storage for a team |

**Role rules**

- The device that starts an incident makes its user the Primary.
- The Primary can hand the Primary role to another first aider; the change is time-stamped in the log.
- Each first aider has a profile: name, qualification level (e.g. Standard First Aid, EMR), certificate expiry, language, optional organization.
- Responders can be added by name only, without an app account, so no one is excluded from the record.

## Core workflows

A single incident moves through eight stages; stages 3 to 5 repeat for every casualty and can overlap.

1. **Start.** One tap or a wake phrase ("FirstLog, start incident") opens a new incident, starts recording, and stamps time and GPS location.
2. **Scene size-up.** The first aider describes the scene and hazards; the app fills the scene record (location, hazards, number of casualties, resources).
3. **Casualty capture.** Saying "new casualty" (or tapping +) creates a casualty with a temporary ID (C1, C2…) and a colour tag. Everything said next is attached to that casualty until another is selected.
4. **Triage (multi-casualty).** The Primary assigns a triage category to each casualty using the protocol they chose (e.g. START), asking the app for a brief reminder of it if they want one, and assigns first aiders to casualties. A scene board shows every casualty, category and assigned responder.
5. **Ongoing care.** Vitals, treatments, changes in condition and photos are logged against the casualty, each with a timestamp and the responder who recorded it.
6. **9-1-1 call.** "FirstLog, call 9-1-1" opens the phone's dialer with 9-1-1 ready (or dials directly where the OS allows), logs the call time, and captures the conversation where the OS allows. The app shows a short script: location, number of casualties, main problems.
7. **EMS arrival and handover.** The app produces a one-screen summary per casualty, shares it by QR code, PDF or nearby transfer, and records the transfer of care: receiving crew, unit number, time, and confirmation.
8. **Close and report.** The Primary closes the incident, reviews and corrects the auto-structured record, and generates summary and detailed reports.

**Example voice commands** (each also available as a button)

- "Start incident" · "New casualty" · "Switch to casualty two"
- "Call 9-1-1" · "Take photo" · "Mark casualty one red"
- "Vitals: pulse 110, breathing 24" · "Show EMS summary" · "Hand over casualty one"
- "What triage protocols are there?" · "Remind me of START" · "Remind me of SALT"

## Functional requirements by area

Priority: **M** = must have for the first release, **S** = should have, **C** = could have later.

### Voice capture and transcription

| ID | Requirement | Priority |
| --- | --- | --- |
| VC-1 | Record continuous audio from incident start to close, with a visible recording indicator | M |
| VC-2 | Transcribe speech on the device, without internet, in the user's chosen language | M |
| VC-3 | Keep the original audio linked to every transcript segment for later verification | M |
| VC-4 | Recognize a small set of voice commands (start, new casualty, switch, call 9-1-1, photo, summary) | M |
| VC-5 | Tolerate background noise (traffic, crowds, sirens) and mark low-confidence text for review | S |
| VC-6 | Identify which first aider is speaking when several share one device | C |

### Structuring the information

| ID | Requirement | Priority |
| --- | --- | --- |
| ST-1 | Extract structured fields from speech: casualty ID, mechanism of injury, chief complaint, level of consciousness, airway/breathing/circulation, vitals, injuries by body location, treatments, medications, allergies, history | M |
| ST-2 | Attach each extracted item to the right casualty and the responder who said it, with a timestamp | M |
| ST-3 | Show extracted items as editable cards; the user can confirm, correct or delete any item | M |
| ST-4 | Never invent data: every structured item links back to the transcript words it came from | M |
| ST-5 | Use standard first aid assessment frameworks (primary survey, SAMPLE history, OPQRST for pain) to organize the recorded fields only; they do not prompt or direct care | S |
| ST-6 | Body diagram where injuries can be placed by tap or by voice ("left forearm") | S |

### Casualties and triage

| ID | Requirement | Priority |
| --- | --- | --- |
| TR-1 | Unlimited casualties per incident, each with a separate record | M |
| TR-2 | Temporary IDs (C1, C2…) with optional name, age, sex and description | M |
| TR-3 | Triage category per casualty, chosen by the first aider under the protocol they selected (START, JumpSTART for children, SALT), with history of every change | M |
| TR-4 | Scene board: all casualties at a glance with category, assigned first aider and last update time | M |
| TR-5 | Optional link to a physical triage tag number or barcode | C |
| TR-6 | Record each casualty's GPS position when the casualty is created, and log a new time-stamped position whenever the casualty is moved; positions appear on the scene board and in the EMS summary | M |

### Protocols on request

The app gives protocol guidance only when the user asks, and in the MVP only as a brief reminder; a walkthrough may be added in a later phase after a regulatory review.

| ID | Requirement | Priority |
| --- | --- | --- |
| PR-1 | By voice or tap, the user can ask which protocols are available (e.g. "What triage protocols are there?"); the app lists them by area, starting with triage (START, JumpSTART, SALT) | M |
| PR-2 | After the user picks a protocol, the app shows its brief reminder (PR-4) | M |
| PR-3 | Later phase, only after a regulatory review: an optional walkthrough that presents the protocol's generic steps one at a time, by voice and on screen; it takes no answers about the casualty and suggests no category. If added, the app asks after PR-1 whether the user wants the reminder or the walkthrough | C |
| PR-4 | Brief reminder: a short summary of the protocol on one screen, also read aloud on request | M |
| PR-5 | Protocol content is shown as published by its source, with name, version and source; the app adds no advice of its own and never picks a category or treatment | M |
| PR-6 | Guidance never starts on its own and never interrupts recording or a 9-1-1 call | M |
| PR-7 | The incident log records which protocol was used, and when its reminder was shown | S |
| PR-8 | Protocols for other areas beyond triage, as content sources allow | C |

### Responders

| ID | Requirement | Priority |
| --- | --- | --- |
| RS-1 | Record every first aider involved, with role and qualification | M |
| RS-2 | Exactly one Primary at a time; transfers of the Primary role are logged | M |
| RS-3 | Other first aiders' devices can join the incident and sync, with no internet (Bluetooth / local Wi-Fi) | S |
| RS-4 | Assign casualties to first aiders and show who is caring for whom | S |

### 9-1-1 support

| ID | Requirement | Priority |
| --- | --- | --- |
| EM-1 | Voice or one-tap command opens the device's dialer for the local emergency number (9-1-1, 1-1-2, 9-9-9… by region) | M |
| EM-2 | The app must never block, delay or replace a direct call; if the app fails, the phone's own dialer still works | M |
| EM-3 | Log call start and end times and who called | M |
| EM-4 | Show a call script with the incident address, GPS coordinates and casualty count | M |
| EM-5 | Capture the call conversation where the operating system permits (speakerphone + microphone); otherwise prompt for a spoken summary after the call | S |
| EM-6 | Support text-to-9-1-1 / NG9-1-1 where available | C |

### Photos and media

| ID | Requirement | Priority |
| --- | --- | --- |
| PH-1 | Take photos inside the app; photos never go to the phone's general photo gallery | M |
| PH-2 | Link each photo to the scene, a casualty, an injury location and/or a responder, with time and GPS | M |
| PH-3 | Annotate photos (arrows, circles, short notes) | S |
| PH-4 | Record consent status for casualty photos where possible | S |
| PH-5 | Short video clips | C |

### EMS handover and transfer of care

| ID | Requirement | Priority |
| --- | --- | --- |
| HO-1 | One-screen EMS summary per casualty, readable in under 60 seconds | M |
| HO-2 | Share the summary by QR code, PDF, email or nearby device transfer | M |
| HO-3 | Record transfer of care: casualty, receiving service, unit number, crew names, time, destination hospital if known | M |
| HO-4 | Capture a confirmation (signature or tap) from the receiving crew | S |
| HO-5 | Export in a standard health-data format (HL7 FHIR) for future EMS integration | C |

### Incident records

| ID | Requirement | Priority |
| --- | --- | --- |
| IR-1 | Every incident gets a unique ID and a complete, time-stamped event log | M |
| IR-2 | After closing, edits are tracked (who, when, what changed); the original is never overwritten | M |
| IR-3 | Search and list past incidents by date, location and responder | S |
| IR-4 | Set retention periods and secure deletion | M |

## Data model

An Incident is the top-level record; everything else belongs to it, and every item carries who recorded it and when.

| Entity | Belongs to | Key fields |
| --- | --- | --- |
| Incident | — | ID, start/end time, location (address + GPS), type, status, Primary, protocol used |
| Scene | Incident | Hazards, environment, mechanism, number of casualties, resources on scene |
| Responder | Incident | Name, role (Primary / additional / bystander), qualification, time joined/left |
| Casualty | Incident | Temp ID, name, age, sex, description, GPS position history, triage category history, assigned responder |
| Observation | Casualty | Type (vital sign, assessment finding, injury, history), value, body location, time, recorded by, source transcript segment |
| Intervention | Casualty | Action (e.g. CPR, AED, bleeding control, splint), start/end time, performed by, response |
| Media | Incident, optionally Casualty / Responder / Observation | Photo or audio file, time, GPS, annotations, consent status |
| Transcript segment | Incident | Text, language, speaker, start/end time, confidence, link to audio |
| Call | Incident | Number dialled, caller, start/end time, recording/transcript link, summary |
| Handover | Casualty | Receiving service, unit, crew, time, destination, confirmation, summary sent |
| Audit entry | Any record | Who changed what, when, old and new value |

## Reports

FirstLog produces three reports, each available on screen, as PDF, and in any supported language regardless of the language spoken at the scene.

| Report | When | Audience | Contents |
| --- | --- | --- | --- |
| EMS update summary | During the incident, on demand | Paramedics, dispatcher | Per casualty: age/sex, what happened, triage category, ABCs and level of consciousness, latest vitals with times, key injuries, treatments given and response, allergies/medications if known |
| Incident summary report | After closing | Organization, employer, event organizer | Date, time, location, Primary and responders, casualty count and outcomes, timeline of key events, 9-1-1 call, handover times |
| Detailed incident report | After closing | Records, legal, quality review | Everything: full timeline, all observations and interventions per casualty, full transcripts, call record, photos with links, handover records, audit trail of edits |

**Report rules**

- Summary formats follow a standard handover structure (e.g. MIST: Mechanism, Injuries, Signs, Treatment) so paramedics recognize it at once.
- Detailed reports can include or exclude photos and transcripts, and can redact names for sharing.
- Templates are customizable so organizations can match their own incident forms (e.g. workplace injury reports).

## Non-functional requirements

### Platforms

- iOS, Android, Windows, macOS, Linux and modern web browsers from one shared codebase (candidate: Flutter, or a Progressive Web App).
- MVP platforms: Android, Windows, Linux and modern web browsers. Apple devices (iPhone, iPad, Mac) and smartwatches, including Apple Watch, are not supported in the MVP; the web version is not tested or supported on Apple devices either.
- Phones are the primary device; tablets and laptops are used mostly for review and reports.
- Minimum supported versions to be set so that roughly 95% of active devices are covered.

### Offline and performance

- Every capture, triage and report function works with no internet or cell signal.
- Opening the app to recording in under 3 seconds; voice command to action in under 1 second.
- Usable for at least 2 hours of continuous recording on a typical phone battery.
- Data syncs to other first aiders' devices locally, and to cloud storage only if the user turns that on.

### Languages

- User interface fully translatable, starting with English and French.
- Transcription and voice commands in each supported language; casualties may speak a different language from the first aider.
- Reports can be generated in a different language from the one spoken.
- Community translation through an open platform (e.g. Weblate).

### Usability and accessibility

- Large touch targets, high-contrast mode, one-handed use, works with gloves.
- Meets WCAG 2.2 AA; supports screen readers and text size settings.
- A new user can document a single-casualty incident without training.

### Security and privacy

- All data encrypted on the device; app lock with PIN or biometrics.
- No data leaves the device unless the user shares or syncs it; no advertising or tracking.
- Designed to meet health-privacy law in target regions (e.g. Quebec Law 25, provincial health privacy acts, PIPEDA, GDPR, HIPAA).
- Clear consent and notice for audio recording and photos.
- Independent security review before the first public release.

### Open source

- Licence: GPL-3.0 or Apache-2.0 (to decide), public repository, open issue tracker.
- No paid features; any optional cloud sync must also be self-hostable.

## Constraints, risks and open questions

The biggest risks are the phone platforms' limits on call recording and the reliability of voice capture in real scenes.

| Risk / constraint | Impact | Mitigation |
| --- | --- | --- |
| iOS does not let third-party apps record phone calls; Android restricts it | 9-1-1 call capture may be partial | Hand off to the native dialer, record via speakerphone where allowed, otherwise prompt for a spoken summary |
| Noisy scenes and stressed speech reduce transcription accuracy | Wrong or missing data | Keep original audio, flag low-confidence text, require review before reports are final |
| Automatic structuring may misassign data to the wrong casualty | Clinical and legal risk | Explicit casualty switching, visible "current casualty" banner, every item editable and traceable to the transcript |
| Health and photo data on personal phones | Privacy breach | On-device encryption, app lock, no cloud by default, retention rules |
| Recommending triage or treatment may make the app regulated software as a medical device | Regulatory approval needed | Give no advice of its own; show only brief reminders of published protocols, on request, unchanged and with their source; the first aider makes every decision; confirm with a regulatory review (e.g. Health Canada) before release |
| No standard way to send data into EMS systems | Handover is manual | QR/PDF now, FHIR export for future partnerships |
| Volunteer-run open-source project | Slow progress, abandonment | Clear roadmap, small MVP, partner with first aid organizations |

**Open questions**

- [ ] Which triage protocols must be in the first release (START only, or also SALT / JumpSTART)?
- [ ] Which organizations' protocol texts can FirstLog use, and under what licence or permission?
- [ ] Which languages after English and French?
- [ ] Which first aid organizations and EMS services can review the handover format?
- [ ] Is optional cloud sync needed for organizations in v1, or later?
- [ ] Which open-source licence?
- [ ] Legal review: recording consent and privacy obligations in each launch region.

## Release phases and acceptance criteria

Start with a narrow MVP that one first aider can use on one phone, then add team and EMS features. Timings assume 2 to 3 experienced developers.

| Phase | Timing | Scope |
| --- | --- | --- |
| 1. MVP | About 6 to 12 months | Single device, many casualties; voice capture and transcription; photos and 9-1-1 handoff; summary and detailed PDF reports; English and French; brief protocol reminders |
| 2. Version 1 | About 12 more months | Multi-device sync with no internet; Primary role handover; QR / PDF EMS handover; transfer-of-care sign-off; more languages; security audit |
| 3. Mature | Ongoing | Field trials with first aiders; EMS integrations (FHIR); call capture where allowed; accessibility and more protocols; community maintenance; protocol walkthroughs, if approved after a regulatory review |

**MVP is done when:**

- [ ] A first aider can start an incident, document 3 casualties by voice, and switch between them without touching the screen more than once per casualty.
- [ ] With no internet, at least 90% of spoken vitals and treatments in a test script land in the correct casualty's fields.
- [ ] "Call 9-1-1" opens the dialer in under 2 seconds on every supported platform.
- [ ] An EMS summary for one casualty can be shown and shared as PDF in under 30 seconds.
- [ ] Summary and detailed reports generate correctly in English and French.
- [ ] Reviewed by at least one first aid instructor and one paramedic.

**Version 1 is done when:**

- [ ] Three devices can join one incident and stay in sync with no internet.
- [ ] Primary role transfers and transfer of care are logged and appear in reports.
- [ ] A paramedic can scan the QR code and read the summary on their own device.
- [ ] An independent security review has been completed and its findings fixed.
