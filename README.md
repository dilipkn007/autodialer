# FOLK Auto Dialer

> Follow-up Management & Smart Calling System

## Overview

FOLK Auto Dialer is a Flutter mobile application designed to streamline the process of calling a large list of contacts (members/people) and collecting structured follow-up information. The system operates with two user personas:

1. **Admin (Folk Guide)** — The central coordinator who manages enablers, creates events, designs dynamic survey forms, uploads/assigns contacts, and views overall analytics.
2. **Enabler** — A field caller who receives an assigned list of contacts, initiates calling sessions, and records responses via dynamic forms after each call.

## Problem Statement

Currently, follow-up data is managed via large Excel spreadsheets containing 1800+ contact records with 40+ columns of member information. The manual process involves:
- Distributing contact lists to enablers
- Enablers manually calling each contact one-by-one
- Recording responses in spreadsheets
- Manually consolidating responses back to the admin

## Solution

This app automates the entire calling workflow:

1. **Admin creates/imports contacts** into a SQL database through the Data Connect contact insert mutation. A polished CSV upload UI/service is still tracked as follow-up work.
2. **Admin creates events** with custom calling survey forms (dynamic questions)
3. **Admin assigns contacts** to specific enablers for a given event
4. **Enablers log in** and see their assigned contact list
5. **Enablers click "Start Auto Dialer"** which initiates an automated calling session:
   - The app calls the first contact via the phone dialer
   - After the call ends, a dynamic response form appears
   - The enabler fills in call outcome, follow-up status, and custom survey answers
   - A configurable countdown timer (5–60 seconds) begins
   - When the timer elapses (or the enabler clicks next), the app automatically calls the next contact
6. **All responses are synced** to the database in real-time
7. **Admin views dashboards** with analytics, completion rates, and enabler performance

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) — Cross-platform mobile |
| Backend | Firebase Auth + Firebase Data Connect |
| Database | Firebase SQL Connect (Data Connect) — PostgreSQL |
| Authentication | Firebase Auth (Phone OTP) |
| State Management | Provider (from FlutterFlow) + Custom services |
| Telephony | `url_launcher` (`tel:` protocol) |

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── index.dart                   # Page exports
├── flutter_flow/                # FlutterFlow utilities (theme, nav, widgets)
├── pages/
│   ├── login/                   # Shared login screen (OTP-based)
│   └── assigned_contacts/       # Enabler: contact list view
├── auto_dialer/                 # Enabler: active calling session screen
├── calling_dashboard/           # Enabler: post-call response form
├── folk_guide_dashboard/        # Admin: analytics dashboard
├── contact_assignment/          # Admin: assign contacts to enablers
├── profile/                     # User profile screen
├── components/                  # Reusable UI components
└── services/
    └── auth_service.dart        # Firebase Auth + profile bootstrap
```

## Security Model

- New phone-auth users are registered as **Enablers** only.
- Admin users must be provisioned separately in Data Connect by setting `User.role = ADMIN`.
- Admin-only Data Connect operations perform a server-side role lookup against `auth.uid`.
- Enabler assignment and call-log operations are constrained to the authenticated enabler where the operation includes `enablerUid` or related ownership data.

## Data Model (from CSV)

The contact CSV contains 47 columns including:
- **Identity**: Name, Mobile, Email, WhatsApp, Date of Birth, Gender, FOLK ID
- **Organization**: FOLK Guide, FOLK Level, Occupation, Organization, Designation
- **Location**: Address, City, State, Country
- **Education**: Higher Qualification, Academic Institution
- **Engagement**: Current Status, Last Activity, Last Seen, Journey
- **Events**: YFH ID, Center, Stay, Stream, Source, Talents

## Screens

### Admin Screens
1. **Login** — Phone number + OTP verification. New users complete an enabler profile; admin access is provisioned separately.
2. **Dashboard** — Stats (total members, active, due today), pie chart (follow-up distribution), bar chart (members by center), recent activity feed
3. **Contacts** — Searchable contact list with phone call buttons, "Start Auto Dialer" CTA
4. **Enablers** — Enabler directory with completion rates, weekly trends, performance filters
5. **Assign Enabler** — Select target enabler, toggle members for assignment
6. **Events** — Create/manage events with RSVP tracking, custom calling survey forms
7. **Create Event** — Event name, date/time, audience selection, dynamic survey builder (question title + dropdown options)

### Enabler Screens
1. **Login** — Phone number + OTP verification
2. **Assigned Contacts** — List of contacts assigned by admin, search/filter, "Start Auto Dialer" CTA
3. **Calling Dashboard** — Current contact info, call/message/info buttons, follow-up status chips, notes, next call date
4. **Auto Dialer** — Active session with contact card, dynamic form fields, countdown timer, gap duration selector (5s–60s), pause/resume controls

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Firebase project with SQL Connect (Data Connect) enabled
- Firebase Auth with Phone provider enabled
- Existing admin profile in Data Connect for admin workflows

### Setup
```bash
# Clone the repository
git clone <repo-url>
cd autodialer

# Install dependencies
flutter pub get

# Configure Firebase
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use <PROJECT_ID>

# Run the app
flutter run
```

## License

Private — Internal use only.
