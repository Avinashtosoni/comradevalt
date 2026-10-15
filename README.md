# Comrade Vault

Comrade Vault is a local-first Flutter workspace for keeping project plans, digital asset metadata, searchable notes, tasks, renewals and their relationships in one responsive command center. Notes can be created, edited, tagged, pinned and searched locally. A separate Vault encrypts credentials on the device before saving them.

This repository is a prototype, not a hosted service. It includes optional Supabase email authentication and manual workspace snapshot upload/restore, but no Supabase project is provisioned or configured in the repository. Without build-time Supabase settings it remains local-only. Cloud sync is manual, not realtime; email reminders and push notifications are not included.

## What is included

- **Workspace overview:** dashboard, project and asset records, searchable and taggable notes with pinning, and a pannable mind map that links related work.
- **Operations:** task list, Kanban and agenda views; renewal tracking; local activity history; and in-app attention reminders.
- **Encrypted Vault:** passphrase-derived key, AES-256-GCM encrypted entries, reveal/copy controls and automatic locking.
- **Optional Supabase backend:** email/password auth and owner-only, row-level-secured PostgreSQL workspace snapshots with manual upload/restore and revision conflict checks. This requires your own Supabase project and build-time public client settings.
- **Local data tools:** JSON workspace backup and restore, an encrypted-Vault-only archive that can be restored without replacing workspace metadata, and a CSV export of non-Vault metadata.
- **Presentation:** responsive desktop/tablet/mobile layouts, light/dark/system themes, accent choices and web-app install metadata.

The starter workspace contains sample records. Use **Settings → Reset sample workspace** to restore those records; that operation does not remove the separate Vault.

## Requirements

- Flutter **3.29 or newer** (Dart **3.7 or newer**).
- A supported Flutter target. Web is the primary target; native targets use Flutter's normal platform setup.

## Run locally

```sh
flutter pub get
   flutter run -d chrome \
```

### Configure Supabase (optional)

1. Create a Supabase project and run `supabase/migrations/20261015000000_workspace_cloud_sync.sql` in the Supabase SQL Editor.
2. Enable the Email auth provider. Configure the project Site URL and allowed redirect URLs for the app origin; email confirmation behavior follows the Supabase Auth settings.
3. Start or build Flutter with the project URL and **publishable/anon client key**:

   ```sh
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_CLIENT_KEY
   ```

   Pass the same `--dart-define` flags to `flutter build web --release` for deployment. The anon/publishable key is intended for client apps; the migration's Row Level Security policies are the access boundary. **Never put a `service_role` key in Flutter, a `--dart-define`, or a public repository.** No project URL or key is committed here.
4. In **Settings → Supabase cloud workspace**, create an account or sign in. Choose **Upload this device** to create/replace the cloud snapshot, or **Restore cloud copy** to replace the device's workspace. Both actions require confirmation. Refresh status after changes on another device.

The app remains usable without Supabase settings. Cloud transfer is manual rather than realtime synchronization. A cloud snapshot stores the full non-Vault `WorkspaceData` document as readable PostgreSQL `jsonb` (including notes and workspace metadata). The encrypted Vault is never uploaded. Supabase project administrators can access workspace JSON; Row Level Security isolates user accounts, but this is not end-to-end encryption. Snapshot writes use a revision check to avoid silently overwriting an intervening cloud update.

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

- Project, asset, note, task, renewal, activity, mind-map and preference data is saved locally through `shared_preferences`. Workspace metadata—including note titles, bodies and tags—is **not encrypted by the Vault**. When optional Supabase sync is configured, this same non-Vault workspace data is uploaded as readable JSONB protected by account-based Row Level Security. Notes are searchable in the app and global search; keep passwords, tokens and recovery codes in the encrypted Vault instead.
- Vault entry payloads are encrypted before persistence using **AES-256-GCM**. A key is derived from the master passphrase with **PBKDF2-HMAC-SHA-256 (310,000 iterations)** and a random per-vault salt; each encrypted payload gets its own nonce. The passphrase and derived key are not written to preferences. Vault entry IDs and update timestamps remain outside the encrypted payload, but titles, categories, usernames, secrets, URLs, notes and tags are inside it.
- The Vault is device/browser-profile local. There is no password reset or recovery flow: losing the passphrase means losing access to the encrypted entries. Keep a separate backup and test that it can be restored.
- A full JSON backup contains ordinary workspace metadata—including Notes—in readable form and the Vault snapshot in encrypted form. The encrypted-Vault export contains only the encrypted snapshot. CSV export is limited to project, asset, task and renewal metadata; it excludes Notes and Vault contents. Supabase cloud snapshots exclude the Vault entirely.
- Copying a value to the clipboard transfers it outside the app; the app does not promise to clear the operating system or browser clipboard.
- Local encryption does not protect an already-unlocked device, a compromised browser, browser extensions, or files exported to an unsafe location. Review and protect backups accordingly.

The connectivity indicator reports network availability only; it does not imply that data is syncing. Notification reminders are generated in the app from local records, not delivered as push notifications or email.

## Web app installation and offline use

`web/manifest.json`, the app icons, and the browser install prompt are included. Installability and offline behavior depend on the production host, browser and Flutter web build. Verify the generated build over HTTPS on the actual deployment origin before relying on installation or offline access; a production build has not been validated in this repository environment.

## Project layout

- `lib/models.dart` — workspace and record models, JSON conversion and demo data.
- `lib/app_controller.dart` — local workspace state, persistence, record actions and activity history.
- `lib/services/vault_service.dart` — encrypted Vault lifecycle and storage.
- `lib/services/cloud_sync_service.dart` — optional Supabase Auth and manual workspace snapshot upload/restore.
- `lib/services/backup_service.dart` — JSON/CSV exports and backup-file parsing.
- `supabase/migrations/` — PostgreSQL schema, Row Level Security policies and guarded snapshot-write function.
- `lib/screens/` — dashboard, map, notes, record, operations, Vault and settings screens.
- `lib/widgets/` — shared interface components and navigation.
- `test/` — controller persistence, relationships and note lifecycle/privacy tests; cloud-disabled configuration; model serialization; CSV export safety; and Vault encryption tests.
- `web/` — browser bootstrap, manifest and icons.

## Validation status

The Dart sources were checked with a Tree-sitter Dart parser, and the SQL migration was grammar-parsed; neither validates runtime behavior or applies the migration to a Supabase project. Flutter/Dart SDKs and live Supabase project settings were not available here, so Flutter analysis/tests/builds and an end-to-end cloud-auth/RLS test have not been run. Before shipping, run `flutter pub get`, `flutter analyze`, `flutter test`, apply the migration to a test project, verify RLS with two test accounts, and build/verify the web app on the intended host.
