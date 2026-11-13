# Safari ya Mama · Mother & caregiver app (Flutter)

Offline-first companion from pregnancy month 1 to baby month 9, in Kiswahili and English.

```bash
flutter pub get
flutter run                                   # offline demo (no backend configured: nothing leaves the phone)
flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon key>
flutter analyze && flutter test               # app tests incl. 423 rule-parity cases
node supabase/tests/community_check.test.ts   # server community rules (same cases as the app)
flutter build appbundle --release --dart-define=...   # Play Store / internal testing
```

Web demo: `flutter build web` then open with `?demo=pregnant` or `?demo=baby` (`&lang=sw`, `&a11y=1`).

Structure: `lib/app` (app root, GoRouter routes and guards, Riverpod providers), `lib/core` (rules, content, design tokens in `core/theme`, shared widgets in `core/widgets`, encrypted Doctor's Note), `lib/data` (Hive store, outbox, Supabase sync, phone reminders, voice input), `lib/state` (AppState, owned by Riverpod and read with `context.app`), `lib/ui` (screens), `lib/features/<feature>/{domain,data,ui}` (feature-first folders for new features: `community` = Mothers' circle, `telemedicine` = appointments and video calls; put new features here). Server functions this app adds are in `supabase/migrations`. Visual audit: `flutter test test_screens/audit_test.dart --update-goldens` writes a screenshot of every screen to `test_screens/shots/`. Do not edit `*.g.dart`.

## The paper booklet: "My daily check book"

📘 [booklet/safari-ya-mama-booklet-en.pdf](booklet/safari-ya-mama-booklet-en.pdf) (English, 52 pages, A4, print-ready)

### Why it matters

Many mothers have no smartphone, have no data, or share one basic phone with the family. They are often the ones most at risk, and an app alone cannot reach them. Dangerous signs also tend to appear **between** clinic visits, when no health worker is watching.

The booklet brings the app's daily check-in to these mothers on paper. Any phone can send an SMS, so the clinic still sees how she is doing each day. It also teaches her to recognise danger signs and to act on them at once.

### How it works (1 minute a day)

1. **Look** at the sign pictures and find the signs she has today.
2. **Write** their numbers on today's date line.
3. **Circle** the worst colour she wrote.
4. **Send an SMS** to the clinic from any phone.

| Colour | Meaning |
|---|---|
| ● **Green** | Normal. Keep going. |
| ▲ **Orange** | Call or visit your clinic today. |
| ■ **Red** | Danger. Go to the health facility **now**. Do not wait for an SMS reply. |

The colours use shapes as well (● ▲ ■), so a mother with colour blindness or a black-and-white copy can still read them. These three levels are the same green / amber / red levels the app uses.

### What's inside

| Section | Letter | Pages |
|---|---|---|
| Me and emergencies: name, clinic, clinic SMS number, emergency transport, national emergency 112 | | 3 |
| How to send the SMS | | 4 |
| **Me, pregnant**: numbered signs (green 10–17, orange 21–29, red 31–39) and a daily log | **A** | 5–25 |
| **Me, after birth**: numbered signs and a daily log | **M** | 27–31 |
| **My baby**: numbered signs and a daily log | **B** | 33–51 |
| Notes pages | | 26, 32 |

Each section also has a **"These together"** box for signs that are worse in combination. For example, severe headache (21) with blurred vision (22) = **red**. Fever in a baby under 2 months = **red**.

### The SMS format

```
<booklet number> <section letter> <sign numbers>

4821 A 10          Pregnant, well, no signs
4821 A 12 23       Pregnant: heartburn and a swollen face
4821 M 11 B 10     After birth: mother and baby in one SMS
```

A short code made of numbers works on any basic phone. It costs one SMS, and it shows nothing private to someone who picks up the phone. The booklet also tells mothers to delete the SMS after sending it if others use their phone.

### How it will be used

- **Given out at the clinic.** The clinic gives the booklet to mothers without a smartphone, writes in the booklet number and the clinic's SMS number, and links the booklet number to the mother's record.
- **Used daily at home.** The mother checks her signs, logs them and sends the SMS. After birth she logs herself (M) and her baby (B). For twins, the clinic gives a second book.
- **Seen by clinic staff.** Daily check-ins reach the facility, so staff can follow up with mothers who report orange signs or who stop sending.
- **Brought to every visit.** The booklet **does not replace the clinic card**. The mother brings both to every visit, and the health worker reviews the log with her.
- **Safety first.** For any red sign she goes to the facility immediately. The SMS is a record, not a way to ask for help in an emergency.

## Website and staff dashboard

This repository holds the mobile app only. The public website and the staff dashboard live in their own repositories and share this app's Supabase backend.

| | Link | For |
|---|---|---|
| **Website** | [safariyamama.com](https://safariyamama.com) | The public: about the programme, contact form |
| **Staff dashboard** | [DASHBOARD_LINK](DASHBOARD_LINK) | Health workers, facility admins and programme admins: mothers, check-ins, bookings, community moderation, content and website CMS, KPIs |

**Dashboard access for grant reviewers and partners:** the dashboard is invite-only because it holds health data. To request a review account, email **megdad.elfaki@gmail.com** with your name, organisation and the reason for access. You will get an invite with the right role.

`test/fixtures/rules_cases.json` is a copy of the shared rule cases (generated from the reference rules by `node tools/gen_rules_cases.mjs`);
refresh it whenever `rules_version` changes so `rules_parity_test.dart` keeps the phone's warning levels identical to the server's.

Product and technical docs: [docs/PRD.md](docs/PRD.md), [docs/TRD.md](docs/TRD.md), [docs/BACKEND_SCHEMA.md](docs/BACKEND_SCHEMA.md), [docs/USER_FLOWS.md](docs/USER_FLOWS.md).
