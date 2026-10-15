import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../services/cloud_sync_service.dart';
import '../services/vault_service.dart';
import 'common.dart';

class CloudSyncCard extends StatefulWidget {
  const CloudSyncCard({super.key, required this.app, required this.cloud, required this.vault});
  final AppController app;
  final CloudSyncService cloud;
  final VaultService vault;

  @override
  State<CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends State<CloudSyncCard> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creatingAccount = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloud = widget.cloud;
    return SurfaceCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(title: 'Supabase cloud workspace', subtitle: 'Optional account-based cloud backup and restore.'),
          const SizedBox(height: 12),
          if (!cloud.isConfigured)
            _configurationNotice(context)
          else if (cloud.initializationError != null)
            _Notice(text: 'Supabase could not start: ${cloud.initializationError}', tone: VaultColors.red)
          else if (!cloud.isReady)
            const _Notice(text: 'Connecting to Supabase…', tone: VaultColors.cyan)
          else if (cloud.currentUser == null)
            _authForm(context, cloud)
          else
            _signedInPanel(context, cloud),
          if (cloud.errorMessage != null) ...[
            const SizedBox(height: 9),
            _Notice(text: cloud.errorMessage!, tone: VaultColors.red),
          ],
          if (cloud.infoMessage != null && cloud.currentUser == null) ...[
            const SizedBox(height: 9),
            _Notice(text: cloud.infoMessage!, tone: VaultColors.cyan),
          ],
        ],
      ),
    );
  }

  Widget _configurationNotice(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(11), border: Border.all(color: Theme.of(context).dividerColor)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cloud features are not configured in this build. The app will keep working locally.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            SizedBox(height: 5),
            Text('Add SUPABASE_URL and SUPABASE_ANON_KEY at build time, then run the SQL migration in supabase/migrations/. Never use a service_role key in the app.', style: TextStyle(fontSize: 9, color: VaultColors.muted, height: 1.45)),
          ],
        ),
      );

  Widget _authForm(BuildContext context, CloudSyncService cloud) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sign in to keep a cloud copy tied to your account. Email confirmation may be required for new accounts.', style: TextStyle(fontSize: 9.5, color: VaultColors.muted, height: 1.45)),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded, size: 16), isDense: true),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: _password,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submitAuth(cloud),
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded, size: 16), isDense: true),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: cloud.isBusy ? null : () => _submitAuth(cloud),
                icon: cloud.isBusy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_creatingAccount ? Icons.person_add_alt_1_rounded : Icons.login_rounded, size: 15),
                label: Text(_creatingAccount ? 'Create account' : 'Sign in'),
              ),
              TextButton(
                onPressed: cloud.isBusy ? null : () => setState(() => _creatingAccount = !_creatingAccount),
                child: Text(_creatingAccount ? 'I already have an account' : 'Create an account'),
              ),
            ],
          ),
        ],
      );

  Widget _signedInPanel(BuildContext context, CloudSyncService cloud) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.12), child: Icon(Icons.person_outline_rounded, size: 17, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 9),
              Expanded(child: Text(cloud.signedInEmail ?? 'Signed in', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              TextButton(onPressed: cloud.isBusy || cloud.isCheckingRemote ? null : cloud.signOut, style: TextButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('Sign out', style: TextStyle(fontSize: 9))),
            ],
          ),
          const SizedBox(height: 8),
          if (cloud.isCheckingRemote || cloud.isBusy) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
          ],
          _Notice(
            text: cloud.hasCloudSnapshot
                ? '${cloud.workspaceName ?? 'Cloud workspace'} · revision ${cloud.remoteRevision}${cloud.remoteUpdatedAt == null ? '' : ' · ${_formatDate(cloud.remoteUpdatedAt!)}'}'
                : cloud.hasCloudWorkspace
                    ? 'Your cloud workspace has no snapshot yet.'
                    : 'No cloud workspace yet. Your next upload will create one.',
            tone: cloud.hasCloudSnapshot ? VaultColors.green : VaultColors.amber,
          ),
          const SizedBox(height: 8),
          const Text('Sync is manual: upload after local edits, or restore the latest cloud snapshot on another device.', style: TextStyle(fontSize: 9, color: VaultColors.muted, height: 1.45)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton.icon(
                onPressed: cloud.isBusy || cloud.isCheckingRemote ? null : cloud.refreshRemoteState,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh', style: TextStyle(fontSize: 9)),
              ),
              FilledButton.icon(
                onPressed: cloud.isBusy || cloud.isCheckingRemote ? null : () => _confirmUpload(context, cloud),
                icon: const Icon(Icons.cloud_upload_outlined, size: 14),
                label: const Text('Upload this device', style: TextStyle(fontSize: 9)),
              ),
              OutlinedButton.icon(
                onPressed: cloud.isBusy || cloud.isCheckingRemote || !cloud.hasCloudSnapshot ? null : () => _confirmRestore(context, cloud),
                icon: const Icon(Icons.cloud_download_outlined, size: 14),
                label: const Text('Restore cloud copy', style: TextStyle(fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: VaultColors.amber.withOpacity(.055), borderRadius: BorderRadius.circular(9), border: Border.all(color: VaultColors.amber.withOpacity(.14))),
            child: const Text('Workspace records and Notes are uploaded as readable JSON. Vault credentials are not uploaded. Supabase project owners may access cloud workspace data.', style: TextStyle(fontSize: 8.5, color: VaultColors.muted, height: 1.45)),
          ),
        ],
      );

  Future<void> _submitAuth(CloudSyncService cloud) async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    if (_creatingAccount) {
      await cloud.signUp(email: _email.text, password: _password.text);
      if (mounted && cloud.errorMessage == null && cloud.currentUser == null) {
        setState(() => _creatingAccount = false);
      }
    } else {
      await cloud.signIn(email: _email.text, password: _password.text);
    }
  }

  Future<void> _confirmUpload(BuildContext context, CloudSyncService cloud) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload this workspace?'),
        content: const Text('This replaces the current cloud snapshot with this device’s projects, assets, notes, tasks, renewals and settings. Workspace metadata is readable to the Supabase project owner. Vault credentials are not included.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Upload workspace')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await cloud.uploadLocalWorkspace(widget.app);
  }

  Future<void> _confirmRestore(BuildContext context, CloudSyncService cloud) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace this device’s workspace?'),
        content: const Text('The cloud snapshot will replace local workspace data on this device, including Notes. The encrypted Vault remains separate and is not changed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore workspace')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await cloud.restoreCloudWorkspace(widget.app);
    if (mounted) widget.vault.setAutoLock(widget.app.data.autoLockMinutes);
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.tone});
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: tone.withOpacity(.06), borderRadius: BorderRadius.circular(9), border: Border.all(color: tone.withOpacity(.14))),
        child: Text(text, style: TextStyle(fontSize: 9, color: tone, height: 1.4)),
      );
}

String _formatDate(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'recently';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
