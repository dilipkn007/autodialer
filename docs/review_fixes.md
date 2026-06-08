# Review Fix Tracker

Date: 2026-06-08

This document tracks the README/docs cross-verification issues found in the review pass and the fixes applied.

## Fixed

### RF-001: Self-service admin escalation
- Severity: Critical
- Status: Fixed
- Problem: New users could select `Admin (Guide)` during client-side registration, and Data Connect mutations accepted a client-provided role.
- Fix:
  - Removed role selection from the login registration UI.
  - Updated `UpsertUser` so self-registration always writes `role: ENABLER`.
  - Added server-side Data Connect role checks to admin-only operations.
- Files:
  - `lib/pages/login/login_widget.dart`
  - `lib/services/auth_service.dart`
  - `dataconnect/connector/queries.gql`
  - `dataconnect/connector/mutations.gql`
  - `lib/dataconnect/`

### RF-002: Enabler data ownership gaps
- Severity: High
- Status: Fixed
- Problem: Some enabler-facing operations accepted identifiers without tying access back to `auth.uid`.
- Fix:
  - Added `auth.uid` checks for enabler assignment and call-log list queries.
  - Added ownership lookups for contact details, event survey access, assignment status updates, call-log response reads, and survey-response writes.
- Files:
  - `dataconnect/connector/queries.gql`
  - `dataconnect/connector/mutations.gql`
  - `lib/dataconnect/`

### RF-003: Auto Dialer reused stale survey questions
- Severity: High
- Status: Fixed
- Problem: The Auto Dialer loaded survey questions only for the first assignment. A queue containing multiple events could save answers against the wrong event survey.
- Fix:
  - Track the loaded survey event ID.
  - Clear answers and reload survey questions when advancing to an assignment from a different event.
- File: `lib/auto_dialer/auto_dialer_widget.dart`

### RF-004: README described first auto call but code waited
- Severity: Medium
- Status: Fixed
- Problem: README said starting the Auto Dialer calls the first contact, but the screen only loaded data and waited for a button tap.
- Fix:
  - Auto Dialer now launches the first call after the screen opens with pending assignments.
- File: `lib/auto_dialer/auto_dialer_widget.dart`

### RF-005: Contact mutation was named upsert but inserted only
- Severity: Medium
- Status: Fixed by making behavior explicit
- Problem: The contact mutation was called `UpsertContact` while using `contact_insert`. SQL Connect upsert requires the primary key `id`, so a true `folkId`-based upsert is not currently available with the existing schema shape.
- Fix:
  - Renamed the operation to `InsertContact`.
  - Regenerated the Data Connect Flutter SDK.
- Follow-up:
  - Design duplicate-safe CSV import using a stable contact ID strategy, a server-side import path, or a schema/key change.
- Files:
  - `dataconnect/connector/mutations.gql`
  - `lib/dataconnect/`

### RF-006: Docs listed incomplete services as complete
- Severity: Medium
- Status: Fixed
- Problem: `README.md` and `docs/task.md` said `database_service.dart`, `call_service.dart`, and `csv_import_service.dart` existed or were complete.
- Fix:
  - README now lists only the current `auth_service.dart`.
  - Task tracker marks the extra service files as follow-up work.
- Files:
  - `README.md`
  - `docs/task.md`

### RF-007: Stale verification results
- Severity: Low
- Status: Fixed
- Problem: `docs/walkthrough.md` claimed `flutter analyze` had no issues even though the review run found analyzer warnings.
- Fix:
  - Resolved analyzer findings.
  - Updated walkthrough verification output.
- Files:
  - `docs/walkthrough.md`
  - `lib/auto_dialer/auto_dialer_widget.dart`
  - `lib/calling_dashboard/calling_dashboard_widget.dart`
  - `lib/pages/assigned_contacts/assigned_contacts_widget.dart`
  - `lib/pages/login/login_widget.dart`
  - `lib/flutter_flow/nav/serialization_util.dart`
  - `lib/dataconnect/default.dart`

## Still Open

### RF-008: CSV upload/import product flow
- Severity: Medium
- Status: Open
- Reason: The backend has a contact insert mutation and generated SDK support, but there is no polished CSV upload UI or duplicate-safe import service.
- Suggested next step:
  - Add `lib/services/csv_import_service.dart`.
  - Decide duplicate strategy before implementation: stable imported UUIDs, admin/server import job, or schema change that makes `folkId` the contact key.

### RF-009: Admin provisioning workflow
- Severity: Medium
- Status: Open
- Reason: Admin self-registration is intentionally disabled. Admins must now be provisioned directly in Data Connect or by a future privileged backend process.
- Suggested next step:
  - Document the operational admin-provisioning command/process once the production project is finalized.

## Verification

- `firebase dataconnect:compile`: passes and regenerates `lib/dataconnect/`.
- `flutter analyze`: passes with no issues.
- `flutter test`: passes.
