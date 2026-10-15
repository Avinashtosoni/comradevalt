# Comrade Vault

Comrade Vault is a local-first Flutter workspace for keeping project plans, digital asset metadata, tasks, renewals and their relationships in one responsive command center. A separate Vault encrypts credentials on the device before saving them.

This repository is a prototype, not a hosted service. It has no account system, remote database, synchronization service, cloud backup, email reminders or push-notification backend.

## What is included

- **Workspace overview:** dashboard, project and asset records, and a pannable mind map that links related work.
- **Operations:** task list, Kanban and agenda views; renewal tracking; local activity history; and in-app attention reminders.
- **Encrypted Vault:** passphrase-derived key, AES-256-GCM encrypted entries, reveal/copy controls and automatic locking.
- **Local data tools:** JSON workspace backup and restore, an encrypted-Vault-only archive that can be restored without replacing workspace metadata, and a CSV export of non-Vault metadata.
- **Presentation:** responsive desktop/tablet/mobile layouts, light/dark/system themes, accent choices and web-app install metadata.

The starter workspace contains sample records. Use **Settings → Reset sample workspace** to restore those records; that operation does not remove the separate Vault.

## Requirements

- Flutter **3.29 or newer** (Dart **3.7 or newer**).
- A supported Flutter target. Web is the primary target; native targets use Flutter's normal platform setup.

## Run locally

```sh
flutter pub get
flutter run -d chrome
```

Run the automated tests and static analysis with:

```sh
flutter test
flutter analyze
```

Format the Dart source with:

```sh
dart format lib test
```

Build the web app for deployment with:

```sh
flutter build web --release
```

Serve the contents of `build/web` over HTTPS in production. If the app is hosted below a URL path, set Flutter's base href to that path when building, for example `flutter build web --release --base-href /comrade-vault/`.

## Data storage and security boundaries

- Project, asset, task, renewal, activity, mind-map and preference data is saved locally through `shared_preferences`. This workspace metadata is **not encrypted by the Vault**.
- Vault entry payloads are encrypted before persistence using **AES-256-GCM**. A key is derived from the master passphrase with **PBKDF2-HMAC-SHA-256 (310,000 iterations)** and a random per-vault salt; each encrypted payload gets its own nonce. The passphrase and derived key are not written to preferences. Vault entry IDs and update timestamps remain outside the encrypted payload, but titles, categories, usernames, secrets, URLs, notes and tags are inside it.
- The Vault is device/browser-profile local. There is no password reset or recovery flow: losing the passphrase means losing access to the encrypted entries. Keep a separate backup and test that it can be restored.
- A full JSON backup contains ordinary workspace metadata in readable form and the Vault snapshot in encrypted form. The encrypted-Vault export contains only the encrypted snapshot. CSV export is limited to project, asset, task and renewal metadata and excludes Vault contents.
- Copying a value to the clipboard transfers it outside the app; the app does not promise to clear the operating system or browser clipboard.
- Local encryption does not protect an already-unlocked device, a compromised browser, browser extensions, or files exported to an unsafe location. Review and protect backups accordingly.

The connectivity indicator reports network availability only; it does not imply that data is syncing. Notification reminders are generated in the app from local records, not delivered as push notifications or email.

## Web app installation and offline use

`web/manifest.json`, the app icons, and the browser install prompt are included. Installability and offline behavior depend on the production host, browser and Flutter web build. Verify the generated build over HTTPS on the actual deployment origin before relying on installation or offline access; a production build has not been validated in this repository environment.

## Project layout

- `lib/models.dart` — workspace and record models, JSON conversion and demo data.
- `lib/app_controller.dart` — local workspace state, persistence, record actions and activity history.
- `lib/services/vault_service.dart` — encrypted Vault lifecycle and storage.
- `lib/services/backup_service.dart` — JSON/CSV exports and backup-file parsing.
- `lib/screens/` — dashboard, map, record, operations, Vault and settings screens.
- `lib/widgets/` — shared interface components and navigation.
- `test/` — model serialization and Vault encryption tests.
- `web/` — browser bootstrap, manifest and icons.

## Validation status

The Dart sources were checked with a Tree-sitter Dart parser during development. That is only a syntax-oriented check, not a replacement for Dart analysis or a Flutter build. Run `flutter pub get`, `flutter analyze`, `flutter test` and a release web build in an environment with the required Flutter SDK before shipping. In particular, verify the browser install prompt, backup/restore file flow, storage behavior and offline behavior on the intended host.
