# Daily Task Pro — Flutter MVP (v0.1)

This is an **initial offline prototype**, NOT a production-ready financial app or Play Store release.

## Implemented
- Material 3 dashboard with monthly income, spending, investment and savings summaries (PKR)
- Local expense/income/investment entry with category, amount, cash/online, tags/notes
- Loan given/taken records with beneficiary, amount, payment method, due date, settlement checkbox
- Task creation with priorities and completion tracking
- English/Urdu labels (partial), light/dark theme
- Local persistence using `shared_preferences` JSON (for demo only)

## Not implemented yet
- Firebase authentication, Google sign-in, cloud sync, email/Google Drive backups
- Encrypted local database, biometric/PIN lock, full Urdu localization
- Attachments/receipt images, loan repayment ledger, recurring tasks
- Local/push/email reminders, report exports, charts, privacy policy
- Automated tests and production Android signing

## Run
1. Install Flutter SDK and Android Studio, then run `flutter doctor`.
2. From the extracted directory run `flutter create --platforms android .` (generates Android platform files).
3. Run `flutter pub get`.
4. Run `flutter run` with an Android device connected.
5. After implementing and testing all production features, generate a signed Android App Bundle with `flutter build appbundle --release`.

## Production architecture plan
- Flutter + Riverpod state management and go_router
- Drift + SQLCipher-backed SQLite or equivalent encrypted database for offline storage
- Firebase Authentication (Google/email), Cloud Firestore, Cloud Storage, Firebase Cloud Messaging
- Security rules scoped to `request.auth.uid`, App Check, minimal permissions, encryption key in Android Keystore
- Cloud Functions for trusted notification delivery and scheduling
- Explicit user consent and OAuth for Google Drive/Gmail backups; never store Gmail passwords
- Separate financial transaction, repayment, loan, task, attachment and sync metadata models
- Offline sync conflict resolution, idempotency, backup restore and migration tests
- GDPR-style data export/delete, privacy policy, Play Data Safety disclosures

## Important
Do not enter real sensitive financial data into this prototype: local shared_preferences are not encrypted. Financial calculations are simplified; settlement and repayment modeling needs implementation before release. Android SDK/Flutter are not installed in this authoring environment, so this source has not been compiled or device-tested.
