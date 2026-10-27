# Driving School Manager — Antigravity Project Brief

> Paste this entire file into Antigravity as the project instruction.
> Build the frontend MVP only. Do not implement a backend.

## 1. Your first task

Before changing anything:
1. Inspect the existing repository and identify whether a Flutter project already exists.
2. Read the current project structure, `pubspec.yaml`, existing conventions, and any instructions in the repository.
3. Do not overwrite working code or replace the project wholesale.
4. If no Flutter project exists, report that and create a new Flutter project only if the environment supports it.
5. Implement **Phase 1 only** first. Explain what you found, what you plan to change, and then make the changes.

## 2. Product overview

Build **Driving School Manager**, an Android-first Flutter SaaS frontend for small driving schools.

The product helps a driving school manage:
- Student enrolment and profiles
- Driving class schedules and attendance
- Learner's licence (LLR) details and expiry dates
- Driving test appointments and outcomes
- Course fees, installments, payments, and balances
- Reminders for school staff and students
- A student portal where each student sees only their own information

### MVP constraints
- Flutter Android app first.
- Frontend only: **no backend, API server, production database, or real authentication**.
- Use realistic mock data and functional local state.
- Student and staff actions should update the mock state during the app session.
- Clearly label simulated login and simulated notifications as demo behaviour.
- Do not claim a WhatsApp message was sent unless a real integration exists. For this MVP, preview messages and simulate/manual-record reminder status only.
- Keep the architecture ready for a future API without implementing that API now.

## 3. User roles

### Owner
- View the full school dashboard.
- Manage students, classes, licence/test records, fees, reminders, staff, and school settings.
- View school-wide operational summaries.

### Office staff
- Manage student records, classes, licence/test dates, payments, and reminders.
- Staff permissions may be simplified in the mock MVP, but keep role checks centralised and ready to refine later.

### Student
- Sign in through a simulated demo flow.
- View their own home dashboard, classes, licence/test information, fee balance/history, reminders, and profile.
- Request a class reschedule/change; staff must confirm the change.
- Students cannot edit official licence records, change their fee balance, record payments, or mark their own lessons complete.
- Ensure the UI scopes student data to the simulated signed-in student's stable ID.

Important: frontend role checks are for prototype UX only. Production security must be enforced by a future backend.

## 4. Main staff workflow

1. Open dashboard and review today's classes, upcoming tests, approaching LLR expiry, and outstanding fees.
2. Register a student with personal/contact details, enrolment date, course package, and agreed fee.
3. Add LLR details and test appointments when available; these details may be unknown at enrolment.
4. Schedule lessons, optionally assign an instructor and vehicle, and track attendance.
5. Record fee payments and installment due dates.
6. Review reminders and preview WhatsApp messages for students.
7. Track course completion and test outcomes.

Support exceptions: missed/cancelled classes, rescheduled tests, partial payments, students without an LLR yet, and students on hold.

## 5. Main student workflow

1. Sign in using a simulated demo account.
2. View the next lesson, upcoming test, and outstanding fee balance.
3. View upcoming and completed lessons.
4. View recorded licence and test details.
5. View fee amount, payments, and outstanding installments.
6. View personal reminders and WhatsApp message previews.
7. Request a class schedule change.

## 6. Screen inventory

### Staff/owner experience
- Demo login / role selection
- Dashboard
- Students list, search, filters, and registration form
- Student detail/profile
- Classes schedule (daily/weekly or a practical simplified view)
- Add/edit/reschedule lesson and mark attendance
- Licence & Tests list/detail and edit forms
- Fees overview
- Add payment and payment history
- Installment schedule
- Reminders centre
- WhatsApp message preview
- Staff & Roles (basic mock screen if included in Phase 1 navigation; deeper management can wait)
- School settings/profile

### Student experience
- Student home
- My Classes
- My Licence & Tests
- My Fees
- My Reminders
- My Profile
- Reschedule request flow

Use role-specific navigation. Prefer a simple, consistent Android bottom navigation for the main destinations and a More/settings area where appropriate. Do not expose staff management screens to students.

## 7. Dashboard content

Staff dashboard should surface:
- Active student count
- Today's scheduled classes
- Upcoming driving tests
- LLR expiry alerts
- Total outstanding fees / overdue installments
- A “Needs attention” section with actionable alerts
- Quick actions: Add Student, Schedule Class, Record Payment

Student dashboard should surface:
- Next class
- Upcoming test (if any)
- LLR status/expiry (if available)
- Outstanding balance
- Recent payments or class history
- Personal reminders

Use clearly marked fictional sample numbers and realistic mock records. Avoid presenting hardcoded demo figures as live data.

## 8. Core business rules

### Students
- Use stable IDs, never names or phone numbers as primary identifiers.
- Suggested statuses: Enquiry, Active, On Hold, Completed, Cancelled.
- A student may not yet have an LLR or test date.
- Support search by name/phone and status filters.

### Lessons
- Fields: ID, school ID, student ID, date, start/end time, optional instructor ID, optional vehicle ID, status, notes.
- Statuses: Scheduled, Completed, Cancelled, Missed.
- Only mark a lesson complete when explicitly confirmed.
- Rescheduling must preserve relevant history rather than silently rewriting completed lessons.
- Add overlap validation for the same instructor/vehicle when those resources are assigned.

### Licence and tests
- Keep licence records separate from test appointments.
- Allow missing/unknown dates.
- Track LLR issue/expiry dates and driving test appointment dates/outcomes.
- Test states can include Not Scheduled, Scheduled, Passed, Failed, Rescheduled.
- Preserve prior test attempts where practical.
- Show approaching and expired dates clearly; do not imply an expired LLR can legally be used.

### Fees
- Store agreed course fee and payment transactions separately.
- Payment fields: ID, student ID, amount, date, method, optional reference/receipt number.
- Installment fields: ID, student ID, amount due, due date, status.
- Balance = agreed course fee − sum of valid recorded payments.
- Reject zero/negative payment amounts and invalid values.
- Avoid duplicate payment creation from repeated taps.
- Preserve transaction history; do not silently overwrite payments.
- Clearly distinguish an installment schedule from actual payment transactions.

### Reminders
- Reminder types: class, LLR expiry, driving test, installment due/overdue, rescheduled/cancelled class.
- Include student, type, scheduled date/time, urgency, recipient, and status.
- Support staff review and message preview.
- For this frontend MVP, reminders can be generated from mock records or represented by mock reminder records.
- No real background scheduling or WhatsApp delivery is required now.

### Multi-school readiness
- Include `schoolId` on school-owned entities in the model design.
- Do not implement production multi-tenant isolation or backend authorisation yet.
- Keep school context centralised so a future backend can enforce tenant boundaries.

## 9. Architecture and technology

Use **feature-first Clean Architecture**, **Riverpod** for state management/dependency injection, and **go_router** for navigation, unless the existing repository already has sound alternatives that should be retained.

Suggested structure:

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    errors/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
    students/
    scheduling/
    licences_tests/
    fees/
    reminders/
    staff/
    settings/
  shared/
    models/
    providers/
```

For substantial features, use:
- `presentation/`: screens, widgets, form validation UI, Riverpod providers
- `domain/`: entities, repository contracts, use cases, business rules
- `data/`: mock data source, data models, repository implementations

Do not create empty abstraction layers for every trivial component. Keep the code maintainable and proportional to the feature.

### Repository pattern
- Define repository contracts where they provide real value.
- Implement mock repositories/data sources for this MVP.
- Keep widgets independent of mock data implementation details.
- Make it possible to swap mock repositories for API-backed repositories later.
- Use in-memory state initially. Add local persistence only if needed and explain its trade-offs.

### Code quality
- Use null-safe Dart and immutable models where practical.
- Use clear naming and small, focused widgets.
- Keep business rules out of UI widgets.
- Avoid duplicating calculations across screens.
- Include loading, empty, validation-error, and failure states where relevant.
- Do not add dependencies without a clear need.
- Follow the existing formatter/linter configuration.

## 10. WhatsApp reminder UX

In this MVP:
1. Display the reminder in the app.
2. Let staff open a preview of the intended message.
3. Optionally provide a clearly labelled “Open WhatsApp” action using a prefilled message URL if feasible and safe.
4. Record only a manual/demo status such as Draft, Ready to Send, or Marked Sent.
5. Clearly communicate that the message has not been automatically delivered.

Do not implement a fake WhatsApp API, credentials, automatic delivery, or fabricated delivery receipts. Real WhatsApp Business Platform integration belongs to a later phase.

## 11. Implementation phases

### Phase 1 — Foundation (implement first)
- Inspect repository and current dependencies.
- Establish/retain project structure.
- Configure app entry point, Material 3 theme, typography, spacing, reusable widgets.
- Configure `go_router`.
- Add a central demo role/session state using Riverpod.
- Add simulated role selection/login for Owner, Office Staff, and Student.
- Add role-specific navigation shells with placeholder destination screens.
- Ensure the project builds and launches on Android.

### Phase 2 — Students
- Student list, search/filter, registration/edit form, profile.
- Mock repository and state updates.

### Phase 3 — Classes
- Schedule, reschedule/cancel, attendance and completion.
- Validate instructor/vehicle overlap where applicable.

### Phase 4 — Licence and tests
- Licence records, expiry indicators, test appointments and outcomes.

### Phase 5 — Fees
- Payments, installment schedules, payment history and correct balances.

### Phase 6 — Reminders and student portal
- Personal student views, reminder centre, message previews, demo reminder states.

### Phase 7 — Integration and QA
- Connect dashboard summaries to mock repositories.
- Test role-specific routing and student data scoping.
- Test calculations, validation, empty states, and Android layouts.
- Document the demo flow and remaining limitations.

**Do not attempt all phases at once. Complete Phase 1 first, report the outcome, and wait for the next instruction before proceeding to Phase 2.**

## 12. Phase 1 acceptance criteria

Phase 1 is complete only when:
- The repository and current setup have been inspected.
- The app launches successfully on Android or any environment limitation is reported accurately.
- Material 3 theme and shared styling are centralised.
- `go_router` navigation works.
- Riverpod holds the simulated role/session state.
- Owner, Office Staff, and Student can enter their respective demo experience.
- Staff and student navigation destinations are visibly different.
- Placeholder screens exist for the planned destinations.
- No backend, API client, production authentication, or real WhatsApp delivery has been added.
- Code is formatted and obvious analyzer/build errors are addressed.
- The final response lists files changed, commands/tests run, results, and known limitations.

## 13. Working instructions for Antigravity

- Inspect first; do not assume the repository is empty.
- Make small, coherent changes.
- Preserve existing working functionality.
- Do not fabricate successful build/test results.
- If a command fails, report the failure and diagnose it.
- Ask before destructive changes or adding costly/external services.
- Do not add real credentials or secrets.
- Use realistic mock data, including edge cases.
- Keep the UI accessible, readable, and appropriate for Android phones.
- Do not implement backend features just because a future production version will need them.

**Start now with repository inspection and Phase 1 only.**
