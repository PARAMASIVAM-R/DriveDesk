# DriveDesk

Android-first Flutter app for small driving schools: student enrolment, class scheduling and attendance, learner's licence (LLR) and driving-test tracking, fees and installments, and reminders with WhatsApp message previews.

> **Offline MVP.** No backend, no real authentication, no real WhatsApp delivery. Data starts as fictional sample records and every change is saved on the device, so it survives restarts. The owner can restore the sample data from *More → Reset demo data*.

Charcoal-and-amber "instrument panel" design with raised 3D cards, ring-style icon dials, speedometer gauges and amber pill actions. Comes in **dark** (default) and **light** themes; switch under *More → Appearance* (System / Light / Dark). The choice is saved on the device.

## Run it

```bash
flutter pub get
flutter run            # on an Android device/emulator
flutter test           # unit, state and widget tests
flutter build apk      # Android build
```

Requires Flutter 3.47+ / Dart 3.13+.

## Demo flow

On the login screen pick a role (simulated, no password):

| Role | What to try |
| --- | --- |
| **Owner** (Ramesh Kumar) | Dashboard → "Needs attention" → approve Divya's reschedule request; mark today's classes complete; void a payment (owner only); add/edit staff and vehicles; edit school settings; reset demo data |
| **Office staff** (Priya Sundaram) | Register a student, schedule a class (try double-booking an instructor), record a payment, add an installment, book/reschedule a driving test, preview a reminder and mark it sent |
| **Student** (choose an account) | Home summary, My classes → *Request change*, licence & test status, fee balance and history, reminders |

Seed data is generated relative to today and covers edge cases: a student with no LLR, an expired and an expiring LLR, failed and rescheduled tests, partial, voided and full payments, overdue installments, missed and cancelled classes, and students who are on hold, enquiries, completed or cancelled.

## Architecture

Feature-first clean architecture with **Riverpod** (state + DI) and **go_router**.

```text
lib/
  app/            app widget, router (role-based redirects), shells, theme
  core/           formatters, validators, errors, shared widgets
  shared/         mock database + JSON snapshot persistence (LocalStore, SnapshotSaver), clock provider, base list notifier
  features/
    auth/         demo session, centralised Permissions
    dashboard/    staff dashboard + "needs attention" feed
    students/     list/search/filter, profile, register/edit
    scheduling/   lessons, overlap rules, reschedule (history-preserving), requests
    licences_tests/ LLR records, expiry state, test attempts and outcomes
    fees/         payments (idempotent, voidable), installments, FeeCalculator
    reminders/    ReminderGenerator, demo status, WhatsApp preview
    staff/, settings/  staff & vehicles (owner-editable), school profile, demo-data reset
    student_portal/   student-only screens, scoped to the signed-in student ID
```

Each substantial feature has `domain/` (entities, rules, repository contracts), `data/` (mock repositories) and `presentation/` (providers, screens). Widgets never touch mock data directly; to move to a real API, implement the repository interfaces and override the `*RepositoryProvider`s.

### Business rules worth knowing

- **Balance** = agreed course fee − sum of non-voided payments, computed only in `FeeCalculator`. Installment status (paid / part paid / upcoming / overdue) is derived by applying payments to the schedule oldest-first.
- **Payments** are never edited or deleted; mistakes are voided with a reason. Each payment form generates its ID once, so repeated taps cannot create duplicates.
- **Lessons**: completion/missed/cancel need explicit confirmation. Rescheduling cancels the original (kept, linked) and creates a new lesson. Overlaps for the same student, instructor or vehicle are rejected.
- **Tests**: rescheduling or failing keeps the earlier record; outcomes can't be recorded before the test date.
- **Students** can view only their own data and can only *request* class changes; staff approve them.

## Known limitations

- Role checks are for the prototype's UX only; real authorisation must be enforced by a future backend.
- Persistence is local to one device (a JSON snapshot in the app documents folder, saved ~300 ms after each change and when the app is backgrounded). There is no sync or backup.
- Seed dates are generated relative to the first launch; after that they stay fixed like real records.
- WhatsApp: the app shows a preview and can open a prefilled `wa.me` chat. Nothing is sent automatically, and "Marked sent" is a manual note, not a delivery receipt.
- Course packages are read-only. Staff and vehicles can be added and edited but not deleted (past classes reference them). Instructors have no login of their own.
- `schoolId` exists on all school-owned entities, but multi-school tenancy is not implemented.
