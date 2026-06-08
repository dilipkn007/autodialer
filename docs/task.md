# FOLK Auto Dialer — Task Tracker

## Phase 1: Firebase Setup & Schema Design
- [x] Create `firebase.json` configuration
- [x] Create `.firebaserc` project config
- [x] Create `dataconnect/dataconnect.yaml`
- [x] Create `dataconnect/schema/schema.gql` (7 tables)
- [x] Create `dataconnect/connector/connector.yaml`
- [x] Create `dataconnect/connector/queries.gql`
- [x] Create `dataconnect/connector/mutations.gql`
- [x] Update `pubspec.yaml` with Firebase dependencies

## Phase 2: Firebase Auth (Phone OTP)
- [x] Create `lib/services/auth_service.dart`
- [x] Modify `lib/main.dart` — Firebase initialization
- [x] Modify login screen — wire OTP flow
- [x] Role-based routing in nav.dart
- [x] Remove self-service admin signup; new users register as enablers only
- [x] Add server-side Data Connect authorization checks for admin and enabler-owned operations

## Phase 3: Admin Screens Logic
- [x] Wire admin dashboard with live data
- [x] Create enablers management screen (integrated into assignment flow)
- [x] Wire contact assignment screen
- [x] Create events screen (integrated into campaign selector)
- [x] Create event creation screen/modal (integrated)
- [x] Create admin contacts screen (integrated into search/assign flow)
- [ ] Build polished CSV upload/import UI and duplicate-safe import service

## Phase 4: Enabler Screens Logic
- [x] Wire assigned contacts screen
- [x] Wire calling dashboard (post-call form)
- [x] Wire auto dialer session (first call launch, timer, auto-call, dynamic survey)
- [x] Reload dynamic survey questions when the queue advances to a different event

## Phase 5: Services & Infrastructure
- [ ] Create `lib/services/database_service.dart` if a separate facade becomes useful
- [ ] Create `lib/services/call_service.dart` if call handling outgrows widgets
- [ ] Create `lib/services/csv_import_service.dart`
- [x] Update navigation (routes, auth guards)
- [x] Update index.dart exports
- [x] Compile Data Connect schema/connector and regenerate Flutter SDK
- [x] Resolve Flutter analyzer warnings introduced by the implementation pass

## Phase 6: Profile & Settings
- [x] Wire profile screen with auth data & logout flow
