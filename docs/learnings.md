# Project Learnings & Critical Findings

A running log of non-obvious bugs, gotchas, and best practices discovered during development of the FOLK Auto Dialer app. Add new entries at the top so the most recent findings are always first.

---

## 🔴 [2026-06-10] `auth.token.phone_number` May Not Be Available in Firebase Data Connect Auth Expressions

### What Happened
The `MigrateUserIdentity` mutation and `GetUserByPhone` query used `auth.token.phone_number == vars.phone` in their `@auth` expressions. When an enabler logged in via Phone Auth (OTP) and tried to auto-migrate their pre-created dummy profile, the mutation silently failed with a "Failed to invoke operation" error. This caused the registration form to display, which then also failed due to the `@unique` phone constraint.

### Root Cause
`auth.token.phone_number` is not reliably present in the Firebase ID token claims across all phone authentication flows and SDK versions. When it's absent, the `@auth` expression evaluates to `false` and the operation is rejected.

### Fix
1. Removed `auth.token.phone_number == vars.phone` from `@auth` expressions on `MigrateUserIdentity` and `GetUserByPhone`.
2. Kept security through inner `@check` expressions that verify the phone matches the database record.
3. Made `autoMigrateDummyProfile()` rethrow errors instead of silently swallowing them.

### Rule
> **Avoid relying on `auth.token.phone_number` in Firebase Data Connect `@auth` expressions.** Use `auth.uid` for identity verification and inner `@check` directives for business-logic security. If an `@auth` expression fails, the operation is silently rejected with a generic error, making debugging very difficult.

---

## 🔴 [2026-06-10] Data Connect `@default` Not Triggered on Upsert Leading to Null Decoding Errors

### What Happened
When inserting a new `User` (Enabler) using an `upsert` mutation (`adminUpsertUser`), the `ListEnablersWithStats` query started crashing the app with the error:
```
[Data Connect/DataConnectErrorCode.other] Unable to decode data: type 'Null' is not a subtype of type 'String'
```

### Root Cause
The `User` schema had a `createdAt` field defined as `Timestamp! @default(expr: "request.time")`.
However, because the record was created via an **upsert** operation instead of a direct `insert`, Data Connect bypassed the `@default(expr: "request.time")` directive. As a result, PostgreSQL stored `NULL` for `createdAt`. 
When the generated Dart SDK queried `ListEnablersWithStats`, it received `null` for `createdAt` and threw a decoding exception because `Timestamp.fromJson` expects a non-nullable `String`.

### Fix
1. Removed `createdAt` from the `ListEnablersWithStats` and `ListEnablers` queries since the UI wasn't actively using this field.
2. Regenerated the Dart SDK with `npx -y firebase-tools@latest dataconnect:sdk:generate`.

### Rule
> **Be cautious with `@default` directives on upsert mutations in Firebase Data Connect.** If a field like `createdAt` is mandatory (`Timestamp!`), consider passing it explicitly from the client, inserting it explicitly in the mutation, or ensuring your queries/schema handle it flexibly.
> If you encounter a `type 'Null' is not a subtype of type 'X'` error, immediately check your auto-generated `.dart` query responses to see which field is `null` in the database but strictly typed in the schema.

---

## 🔴 [2026-06-09] Firebase Data Connect — Always Regenerate the Dart SDK After Changing GQL

### What Happened
After changing the `AssignContact` mutation in `dataconnect/connector/mutations.gql` from `assignment_upsert` to `assignment_upsert` (without an `id`), and then back to `assignment_insert`, the generated Dart SDK in `lib/dataconnect/` was never updated. This caused a silent schema mismatch — the Dart code was calling a mutation that no longer matched what the server expected, resulting in:

```
[Data Connect/DataConnectErrorCode.other] Failed to invoke operation
```

### Root Cause
`assignment_upsert` in Firebase Data Connect operates on the **primary key (`id`)**.  
Since `id` is auto-generated (`@default(expr: "uuidV4()")`), it was never passed in the mutation variables — so the upsert had no way to identify which row to update, causing a server-side failure.

### Fix
1. Reverted `AssignContact` to use `assignment_insert`.
2. Added a new `ReassignContact` mutation that atomically **deletes** any existing assignment for `(contactId, eventId)` and **inserts** the new one — handling re-assignment cleanly.
3. **Ran SDK regeneration:**
   ```bash
   npx -y firebase-tools@latest dataconnect:sdk:generate
   ```
4. Updated all Flutter call sites to use `reassignContact(...)` instead of `assignContact(...)`.

### Rule
> **Whenever any `.gql` file in `dataconnect/connector/` is changed (mutations or queries), always run:**
> ```bash
> npx -y firebase-tools@latest dataconnect:sdk:generate
> ```
> Without this, the generated Dart SDK in `lib/dataconnect/` silently diverges from the GQL schema and causes runtime failures.

---

## 🔴 [2026-06-09] Firebase App Check — 403 on Debug Token Exchange

### What Happened
The app threw a `403 PERMISSION_DENIED` error:
```
Unable to get app check token: [firebase_app_check/unknown]
Failed to invoke operation: App attestation failed.
URL: https://firebaseappcheck.googleapis.com/v1/projects/autodailer-folk/apps/.../exchangeDebugToken
```

### Root Cause
Two issues compounded:
1. App Check was being **skipped entirely** in debug mode (`if (!kDebugMode)`), but the SDK was still internally trying to exchange a debug token.
2. The debug token auto-generated by the iOS simulator had **never been registered** in the Firebase Console, so it was rejected with 403.

### Fix

**Code (`lib/main.dart`):**  
Use `AppleDebugProvider()` in debug mode instead of skipping App Check entirely:
```dart
await FirebaseAppCheck.instance.activate(
  providerApple: kDebugMode
      ? const AppleDebugProvider()
      : const AppleDeviceCheckProvider(),
  providerAndroid: kDebugMode
      ? const AndroidDebugProvider()
      : const AndroidPlayIntegrityProvider(),
);
```

**Firebase Console (one-time per simulator/device):**
1. Hot-restart the app — look for a log line like:
   ```
   [AppCheckCore] Firebase App Check Debug Token: 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
   ```
2. Go to **Firebase Console → App Check → Apps → iOS App → Manage debug tokens**
3. Add the token UUID.

### Rule
> Each simulator or physical device auto-generates a unique debug token. It must be registered **once** in the Firebase Console. Every new simulator will need its own token registered.

---

## 🔴 [2026-06-09] Firebase App Check API Must Be Enabled in Google Cloud

### What Happened
Even after App Check was correctly set up in code, the app threw:
```
Firebase App Check API has not been used in project 37688006610 before or it is disabled.
Enable it by visiting https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=37688006610
```

### Fix
Manually enable the **Firebase App Check API** in Google Cloud Console for the project. It is not auto-enabled when you enable App Check in the Firebase Console.

### Rule
> After enabling App Check in the Firebase Console, **also enable the Firebase App Check API** in Google Cloud Console. These are separate steps.

---

## 🟡 [2026-06-09] Data Connect `assignment_upsert` Requires Explicit Primary Key

### Finding
The auto-generated `assignment_upsert` mutation in Firebase Data Connect will only update an existing row if the **primary key (`id`)** is included in the data payload. Without it, the operation always inserts a new row — which then fails on any `@unique` constraint.

### Workaround
For tables where you want "upsert by business key" (e.g., unique on `contactId + eventId`), the correct pattern is:
```graphql
# In a @transaction mutation:
assignment_deleteMany(where: { contactId: { eq: $contactId }, eventId: { eq: $eventId } })
assignment_insert(data: { ... })
```
This is effectively an upsert by business key.

---

## 🟡 [2026-06-09] Contact Assignment — Selection Must Clear on Enabler/Event Switch

### Finding
When an admin selects contacts and then switches to a different enabler or event, the previously selected contact IDs remain in `_selectedContactIds`. This causes the wrong contacts to be assigned to the new target enabler.

### Fix
Call `_selectedContactIds.clear()` inside every `setState` block that changes `_selectedEnabler` or `_selectedEvent`. Applied in both `contact_assignment_widget.dart` and `enabler_assignment_widget.dart`.

---

*Add new learnings above this line, newest first.*
