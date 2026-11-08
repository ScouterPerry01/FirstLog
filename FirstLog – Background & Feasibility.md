# FirstLog – Background & Feasibility

Nov 7, 2026 · @Perry

## Summary

No existing app combines everything FirstLog aims to do; it can be built, but it is a large project with a few hard platform limits.

- **Does it exist?** The pieces exist separately, mostly as paid tools for paramedics. Nothing found combines hands-free voice capture, multi-casualty triage, responder roles, photos, 9-1-1 support and EMS handover in a free, open-source app for first aiders.
- **Can it be built?** Yes. The hard parts are recording 9-1-1 calls (blocked on iOS), sending data into EMS systems (no standard channel), and syncing several devices with no signal.
- **How complex?** High: roughly 6 to 12 months for a useful MVP with 2 to 3 experienced developers, and another year for a full first version.
- **Name:** FirstLog.

## Existing solutions

The closest relative is Peak Response, an open-source triage app built for fire departments; everything else covers only part of FirstLog's scope.

| Solution | What it does | Gap compared with FirstLog |
| --- | --- | --- |
| [First Due AI ePCR](https://support.firstduesizeup.com/hc/en-us/articles/44013093424411-AI-Powered-ePCR-Training-Guide) | Speech transcription plus AI fills the paramedic's electronic patient care report | Paid, for EMS agencies; single patient; no triage or 9-1-1 support |
| [ParaScribe](https://apps.apple.com/app/id6752537034) | Voice-to-text for EMS, generates structured clinical notes | Professional tool; no multi-casualty triage, roles or handover |
| [Peak Response](https://www.nist.gov/ctl/pscr/peak-response) | Open-source MCI app: speech-to-text data entry, triage tag scanning, GPS map, commander dashboard | Built for fire/EMS; no 9-1-1 call capture, first aider roles or transfer-of-care record |
| [Tübingen mobile triage study (JMIR 2024)](https://www.jmir.org/2024/1/e65728) | Research app recording responders, triage categories, injuries and GPS, sent to commanders | Prototype; showed the app was faster and more accurate than paper |
| [SALT Triage](https://apps.apple.com/us/app/id1216703981) | Helps a provider triage and count MCI victims | Counting aid only; no voice, records or reports |
| [GoCanvas First Aid Report Form](https://cdn.gocanvas.com/mobile-forms-apps/1640-First-Aid-Form-Safety-Link) | Mobile form for anyone giving first aid at a scene | Manual form; no voice, triage or handover |
| [St John First Responder (WA)](https://appfollow.io/ios/st-john-first-responder/1174762431?country=au) | Alerts volunteer first aiders, AED map, emergency dialer | Dispatch and reference, not documentation |

The research supports the idea: the Tübingen study found users were significantly faster and more accurate at triage with an app than with paper tags.

## Feasibility

Most of FirstLog can be built with current technology; four features need design workarounds.

| Feature | Challenge | Workaround |
| --- | --- | --- |
| Recording the 9-1-1 call | iOS blocks call recording by third-party apps; Android increasingly restricts it | Hand off to the native dialer, record the room on speakerphone where allowed, otherwise log times and prompt for a spoken summary |
| Sending data to EMS | No standard channel; every EMS service uses different software | QR code, on-screen summary, PDF, nearby transfer; HL7 FHIR export for future integration |
| Several first aiders on one incident | Phones must sync with poor or no signal | Offline-first design with local Bluetooth / Wi-Fi sync |
| Every device and OS | Many platforms to maintain | One shared codebase (Flutter or PWA); watches and very old devices limited |

**Other issues to plan for early**

- **Privacy law:** health data and casualty photos fall under Quebec's Law 25, provincial health privacy acts and PIPEDA in Canada, and GDPR or HIPAA elsewhere.
- **Medical-device rules:** documentation-only keeps risk low; recommending triage or treatment may make the app regulated software as a medical device (e.g. by Health Canada).
- **On-device AI:** speech recognition and structuring should run on the phone for privacy and no-signal use; noisy scenes and multiple languages need real-world testing.
- **Validation:** involve first aid organizations (St. John Ambulance, Red Cross) and local paramedics early so the handover format matches what EMS wants.

## Complexity and effort

FirstLog is comparable to a serious commercial product; a narrow MVP first is the realistic path. Estimates are rough and assume 2 to 3 experienced developers.

| Stage | Scope | Rough effort |
| --- | --- | --- |
| MVP | One device, voice capture and transcription, multiple casualties, photos, 9-1-1 handoff, summary and detailed PDF reports, 2 languages | About 6 to 12 months |
| Version 1 | Multi-responder sync, Primary role, QR/PDF handover, transfer-of-care sign-off, more languages, security audit | About 12 more months |
| Mature | EMS integrations, field trials, accessibility, ongoing maintenance | Ongoing, community-driven |

The hardest parts, in order: reliable voice capture in chaotic scenes, offline device-to-device sync, turning free speech into accurate per-casualty records, 9-1-1 call limits, and privacy and security. Contacting the Peak Response project about reusing its open-source code could save time.

## Name ideas

FirstLog was chosen; the other candidates are kept here for reference. Check app stores, GitHub and trademark databases before launch.

| Name | Idea behind it |
| --- | --- |
| **FirstLog** (chosen) | Simple; says what it does |
| Handover | Centred on the transfer to EMS |
| TriageScribe | Clear for multi-casualty use |
| OpenAid | Signals free and open source |
| AidWitness | An impartial record of what happened |
| CareChain | Continuity from first aider to EMS |
| Vigil | Short; works in English, French, Spanish and more |

"Peak Response" is already in use and is not an option.

## Sources

- [First Due – AI-Powered ePCR Training Guide](https://support.firstduesizeup.com/hc/en-us/articles/44013093424411-AI-Powered-ePCR-Training-Guide)
- [ParaScribe – App Store](https://apps.apple.com/app/id6752537034)
- [NIST PSCR – Peak Response](https://www.nist.gov/ctl/pscr/peak-response)
- [Peak Response – Prototype to Product](https://medium.com/peakresponseinc/prototype-to-product-608fe9920a9)
- [JMIR 2024 – Evaluation of an App-Based Mobile Triage System for Mass Casualty Incidents](https://www.jmir.org/2024/1/e65728)
- [SALT Triage – App Store](https://apps.apple.com/us/app/id1216703981)
- [GoCanvas – First Aid Form](https://cdn.gocanvas.com/mobile-forms-apps/1640-First-Aid-Form-Safety-Link)
- [St John First Responder (WA) – AppFollow](https://appfollow.io/ios/st-john-first-responder/1174762431?country=au)
