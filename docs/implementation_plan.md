# FOLK Auto Dialer — Finalizing Implementation Plan

This implementation plan covers the remaining tasks: wiring the Auto Dialer session screen (`lib/auto_dialer/auto_dialer_widget.dart`) and the User Profile screen (`lib/profile/profile_widget.dart`).

## User Review Required

> [!IMPORTANT]
> **Timer Behavior**: In the auto-dialer session, when the countdown timer hits 0, it will auto-save the form response (using the default values/whatever is filled) and launch the next contact's call. Is this correct? Or should it wait for the user to click "SAVE & NEXT CONTACT"?
> Current plan: Clicking "SAVE & NEXT CONTACT" starts the gap countdown timer. When the timer hits 0, the next call is automatically launched via `url_launcher`.

> [!IMPORTANT]
> **Profile Screen Design**: The original `ProfileWidget` from FlutterFlow was generated containing a contact profile / calling dashboard view. We will replace this entire UI with a clean, modern user profile page displaying the current enabler's name, phone, role, and a prominent "Sign Out" button.

## Open Questions

> [!NOTE]
> None at this stage. We have full access to local Firebase emulators and database operations, and the database schema is already compiles and runs.

---

## Proposed Changes

### Component: Enabler Screen Logic

---

#### [MODIFY] [auto_dialer_widget.dart](file:///Users/pavan/Developer/autodialer/lib/auto_dialer/auto_dialer_widget.dart)

Implement the auto-dialer session runner:
1. **Pending Assignments List**:
   - Define a static list: `static List<ListAllAssignmentsForEnablerAssignments> pendingAssignments = [];`.
2. **State Properties**:
   - `int _currentIndex = 0;` (index in `pendingAssignments`).
   - `List<GetEventWithSurveyEventSurveyQuestionsOnEvent> _surveyQuestions = [];` (questions loaded dynamically).
   - `Map<String, String> _surveyAnswers = {};` (responses by question ID).
   - `bool _loadingSurvey = false;`
   - `bool _saving = false;`
   - `int _gapDuration = 20;` (default countdown duration in seconds).
   - `int _secondsRemaining = 20;`
   - `bool _timerRunning = false;`
   - `Timer? _countdownTimer;`
   - `bool _isCallStateActive = false;` (shows call details vs. gap timer details).
3. **Timer Logic**:
   - `_startTimer()`: decrement `_secondsRemaining` every second.
   - When `_secondsRemaining == 0`: stop timer, trigger `_makeCall()`.
   - `_pauseTimer()` and `_resumeTimer()` to toggle state.
   - Option chips (5s, 10s, 20s, 30s, 60s) update `_gapDuration`, reset `_secondsRemaining`, and restart the timer if active.
4. **Call Flow**:
   - Tap 'Start Session' or Timer ends → trigger direct phone call using `url_launcher` to `tel:phone_number`.
   - Register an app lifecycle observer (`WidgetsBindingObserver`). When the app resumes from the background (user ends the call and returns to the app):
     - Display the form inputs.
     - Stop/reset the timer.
5. **Form Data**:
   - Render static outcome dropdown (Answered, Busy, No Response, Switched Off, Wrong Number).
   - Render follow-up status dropdown (New, Active, Pending, Contacted, Interested, Not Interested, Joined, Dormant).
   - Render next follow-up date picker.
   - Render notes text controller.
   - Render **Dynamic Survey Form**:
     - Loop through `_surveyQuestions`.
     - For `QuestionType.DROPDOWN`: render option dropdown populated by splitting the comma-separated options.
     - For `QuestionType.TEXT` or `QuestionType.DATE`: render appropriate input widgets.
6. **Save Logic**:
   - Clicking `SAVE & NEXT CONTACT` (or auto-saving when a contact is skipped/completed):
     - Call `RecordCallLog` mutation.
     - Call `RecordSurveyResponse` mutation for each survey answer.
     - Call `UpdateAssignmentStatus` mutation to set status to `COMPLETED`.
     - Move to next contact index.
     - If end of list, show success message and pop screen. Else, start gap countdown.

---

### Component: Profile & Settings

---

#### [MODIFY] [profile_widget.dart](file:///Users/pavan/Developer/autodialer/lib/profile/profile_widget.dart)

Replace the contact-editing UI with a true enabler user profile view:
1. **User Details**:
   - Fetch logged-in user profile from `AuthService.instance.currentUser` and database user details.
   - Display initials avatar, user name, mobile number, role ("Enabler" / "Admin").
2. **Sign Out Action**:
   - Implement "Sign Out" button.
   - On tap, show confirmation dialog. On confirmation, call `AuthService.instance.signOut()` and redirect back to login.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to verify code correctness and clean up any lint warnings/errors.
- Compile and build debug version.

### Manual Verification
1. Open local emulator, log in via phone auth.
2. Select Assigned Contacts → click "Start Auto Dialer".
3. Verify the first assigned contact's information is shown.
4. Initiate a call, verify the app lifecycle listener opens the feedback form on resume.
5. Fill out dynamic survey questions and notes, then click "SAVE & NEXT CONTACT".
6. Verify the gap timer displays, counts down, and triggers the next contact's call.
7. Click "Profile" in the main navigation, verify information loads correctly and "Sign Out" signs out the user.
