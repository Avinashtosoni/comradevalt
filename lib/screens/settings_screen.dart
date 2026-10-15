import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../platform/install_prompt.dart' as install;
import '../sections.dart';
import '../services/backup_service.dart';
import '../services/vault_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onNavigate});
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) => Consumer2<AppController, VaultService>(builder: (context, app, vault, _) {
    final compact = MediaQuery.sizeOf(context).width < 850;
    final pad = compact ? 16.0 : 28.0;
    return SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, compact ? 18 : 27, pad, 30), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1250), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(eyebrow: 'PREFERENCES', title: 'Settings', subtitle: 'A little care for the workspace that keeps everything together.'),
      if (compact) ...[
        _AppearanceCard(app: app), const SizedBox(height: 13), _SecurityCard(app: app, vault: vault, onGoVault: () => onNavigate(AppSection.vault)), const SizedBox(height: 13), _DataCard(app: app, vault: vault), const SizedBox(height: 13), _InstallCard(),
      ] else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: [_AppearanceCard(app: app), const SizedBox(height: 13), _InstallCard()])), const SizedBox(width: 13),
        Expanded(child: Column(children: [_SecurityCard(app: app, vault: vault, onGoVault: () => onNavigate(AppSection.vault)), const SizedBox(height: 13), _DataCard(app: app, vault: vault)])),
      ]),
      const SizedBox(height: 15),
      _LocalArchitectureNote(),
      const SizedBox(height: 17),
      Row(children: [const BrandMark(size: 24), const SizedBox(width: 8), const Text('Comrade Vault', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)), const Spacer(), const Text('Local-first workspace · v0.1.0', style: TextStyle(fontSize: 8.5, color: VaultColors.faint))]),
    ]))));
  });
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.app}); final AppController app;
  @override Widget build(BuildContext context) => SurfaceCard(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeading(title: 'Appearance', subtitle: 'Make your command center feel like yours.'), const SizedBox(height: 15), const TinyLabel('THEME'), const SizedBox(height: 8), Wrap(spacing: 7, children: ['dark', 'light', 'system'].map((value) => _SettingChoice(label: value[0].toUpperCase() + value.substring(1), selected: app.data.theme == value, icon: value == 'dark' ? Icons.dark_mode_rounded : value == 'light' ? Icons.light_mode_rounded : Icons.settings_brightness_rounded, onTap: () => app.setTheme(value))).toList()), const SizedBox(height: 14), const TinyLabel('ACCENT COLOUR'), const SizedBox(height: 9), Row(children: [for (final entry in const [('violet', VaultColors.violet, 'Electric violet'), ('cyan', VaultColors.cyan, 'Clear cyan'), ('rose', VaultColors.pink, 'Soft rose')]) _AccentChoice(value: entry.$1, color: entry.$2, label: entry.$3, selected: app.data.accent == entry.$1, onTap: () => app.setAccent(entry.$1))]), const SizedBox(height: 14), Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(11)), child: Row(children: [Icon(Icons.animation_rounded, size: 15, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), const Expanded(child: Text('Smooth transitions are enabled. Motion follows your operating system preferences.', style: TextStyle(fontSize: 9, color: VaultColors.muted)))]))]));
}

class _SettingChoice extends StatelessWidget { const _SettingChoice({required this.label, required this.selected, required this.icon, required this.onTap}); final String label; final bool selected; final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.11) : Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(9), border: Border.all(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.35) : Theme.of(context).dividerColor)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 9, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted))]))); }
class _AccentChoice extends StatelessWidget { const _AccentChoice({required this.value, required this.color, required this.label, required this.selected, required this.onTap}); final String value; final Color color; final String label; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => Tooltip(message: label, child: Padding(padding: const EdgeInsets.only(right: 11), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(width: 31, height: 31, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent, width: 2), boxShadow: selected ? [BoxShadow(color: color.withOpacity(.3), blurRadius: 9)] : null), child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null)))); }

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.app, required this.vault, required this.onGoVault});
  final AppController app;
  final VaultService vault;
  final VoidCallback onGoVault;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: 'Security & privacy', subtitle: 'Sensitive values stay encrypted before saving.'),
            const SizedBox(height: 14),
            _SecurityItem(
              icon: Icons.key_rounded,
              title: 'Master passphrase',
              subtitle: vault.hasVault ? 'Never stored · Unlock required to decrypt' : 'Create your encrypted local vault',
              tint: VaultColors.green,
              trailing: TextButton(
                onPressed: onGoVault,
                child: Text(vault.hasVault ? (vault.isUnlocked ? 'Lock now' : 'Unlock') : 'Set up', style: const TextStyle(fontSize: 9)),
              ),
              onTap: onGoVault,
            ),
            Divider(height: 20, color: Theme.of(context).dividerColor),
            Row(
              children: [
                const Expanded(child: _SecurityItemText(title: 'Auto-lock after', subtitle: 'Lock the vault after inactivity')),
                DropdownButton<int>(
                  value: const [1, 5, 10, 15, 30].contains(app.data.autoLockMinutes) ? app.data.autoLockMinutes : 5,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(10),
                  items: const [1, 5, 10, 15, 30].map((value) => DropdownMenuItem(value: value, child: Text('$value min', style: const TextStyle(fontSize: 10)))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      app.setAutoLockMinutes(value);
                      vault.setAutoLock(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: VaultColors.amber.withOpacity(.06), borderRadius: BorderRadius.circular(11), border: Border.all(color: VaultColors.amber.withOpacity(.14))),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: VaultColors.amber),
                  SizedBox(width: 8),
                  Expanded(child: Text('This build is local-first. Server authentication, MFA, passkeys, account recovery and multi-device sessions need a configured backend and are not simulated here.', style: TextStyle(fontSize: 9, color: VaultColors.muted, height: 1.5))),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(Icons.devices_rounded, size: 15, color: VaultColors.muted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This device', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Local-only session · no server account', style: TextStyle(fontSize: 8.5, color: VaultColors.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, size: 14, color: VaultColors.green),
              ],
            ),
          ],
        ),
      );
}

class _SecurityItem extends StatelessWidget { const _SecurityItem({required this.icon, required this.title, required this.subtitle, required this.tint, required this.trailing, required this.onTap}); final IconData icon; final String title; final String subtitle; final Color tint; final Widget trailing; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Row(children: [Container(width: 33, height: 33, decoration: BoxDecoration(color: tint.withOpacity(.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: tint)), const SizedBox(width: 9), Expanded(child: _SecurityItemText(title: title, subtitle: subtitle)), trailing])); }
class _SecurityItemText extends StatelessWidget { const _SecurityItemText({required this.title, required this.subtitle}); final String title; final String subtitle; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))]); }

class _DataCard extends StatelessWidget {
  const _DataCard({required this.app, required this.vault}); final AppController app; final VaultService vault;
  @override Widget build(BuildContext context) => SurfaceCard(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeading(title: 'Data & backups', subtitle: 'Manual backups are portable and encrypted.'), const SizedBox(height: 13), _DataAction(icon: Icons.ios_share_rounded, title: 'Export full backup', detail: 'Workspace metadata + encrypted Vault archive', onTap: () => _export(context)), const SizedBox(height: 7), _DataAction(icon: Icons.table_view_outlined, title: 'Export CSV metadata', detail: 'Projects, assets, tasks & renewals · no Vault data', onTap: () => _exportCsv(context)), const SizedBox(height: 7), _DataAction(icon: Icons.lock_outline_rounded, title: 'Export encrypted Vault', detail: 'Vault ciphertext only · master passphrase excluded', onTap: () => _exportVault(context)), const SizedBox(height: 7), _DataAction(icon: Icons.vpn_key_outlined, title: 'Restore encrypted Vault', detail: 'Import a full backup or Vault-only archive', onTap: () => _restoreVault(context)), const SizedBox(height: 7), _DataAction(icon: Icons.restore_rounded, title: 'Restore full backup', detail: 'Replace this device’s workspace and Vault archive', onTap: () => _restore(context)), const SizedBox(height: 12), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.backup_outlined, size: 14, color: VaultColors.cyan), const SizedBox(width: 7), const Expanded(child: Text('Automatic cloud backup is not enabled. Keep your encrypted backup somewhere safe and test restoration before relying on it.', style: TextStyle(fontSize: 8.7, color: VaultColors.muted, height: 1.45)))])), const SizedBox(height: 11), TextButton.icon(onPressed: () => _resetWorkspace(context), icon: const Icon(Icons.restart_alt_rounded, size: 15), label: const Text('Reset sample workspace', style: TextStyle(fontSize: 9.5)), style: TextButton.styleFrom(foregroundColor: VaultColors.red, visualDensity: VisualDensity.compact))]));

  Future<void> _export(BuildContext context) async { try { await BackupService.exportFullBackup(app, vault); _message(context, 'Backup prepared. Store it in a safe place.'); } catch (_) { _message(context, 'Could not export the backup. Try again.'); } }
  Future<void> _exportCsv(BuildContext context) async { try { await BackupService.exportCsv(app); _message(context, 'CSV metadata export prepared. Vault secrets were excluded.'); } catch (_) { _message(context, 'Could not export CSV metadata. Try again.'); } }
  Future<void> _exportVault(BuildContext context) async { if (!vault.hasVault) { _message(context, 'Create a Vault before exporting an encrypted archive.'); return; } try { await BackupService.exportEncryptedVault(vault); _message(context, 'Encrypted Vault archive prepared.'); } catch (_) { _message(context, 'Could not export the encrypted Vault. Try again.'); } }
  Future<void> _restoreVault(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore encrypted Vault?'),
        content: const Text('This replaces the Vault archive on this device but leaves projects and other workspace data unchanged. The imported Vault will be locked; you will need its original master passphrase.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Choose archive')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final archive = await BackupService.pickEncryptedVaultArchive();
      if (archive == null) return;
      await vault.restoreEncrypted(archive);
      if (context.mounted) _message(context, 'Encrypted Vault restored. Unlock it with its original master passphrase.');
    } on FormatException catch (error) {
      if (context.mounted) _message(context, error.message);
    } catch (_) {
      if (context.mounted) _message(context, 'Could not restore this Vault archive. Check the file and try again.');
    }
  }

  Future<void> _restore(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Restore workspace?'), content: const Text('Restoring replaces the local workspace and Vault archive on this device. Export a backup first if you want to keep the current data.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Choose backup'))]));
    if (confirm != true) return;
    try {
      final backup = await BackupService.pickWorkspaceBackup();
      if (backup == null) return;
      await vault.restoreEncrypted(backup.encryptedVault);
      await app.replaceWorkspace(backup.workspace);
      vault.setAutoLock(backup.workspace.autoLockMinutes);
      if (context.mounted) {
        _message(context, app.persistenceMessage == null
            ? 'Backup restored. Unlock the Vault with its original passphrase.'
            : 'Backup loaded, but workspace data could not be saved on this device.');
      }
    } on FormatException catch (error) { if (context.mounted) _message(context, error.message); }
    catch (_) { if (context.mounted) _message(context, 'Could not restore this backup. Check the file and try again.'); }
  }
  Future<void> _resetWorkspace(BuildContext context) async { final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Reset sample workspace?'), content: const Text('Projects, assets, tasks, renewals and mind-map changes will be replaced with the sample workspace. Your separate Vault archive will not be changed.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reset workspace'))])); if (confirm == true) { await app.resetWorkspace(); vault.setAutoLock(app.data.autoLockMinutes); if (context.mounted) _message(context, 'Sample workspace restored.'); } }
  void _message(BuildContext context, String value) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }
}

class _DataAction extends StatelessWidget { const _DataAction({required this.icon, required this.title, required this.detail, required this.onTap}); final IconData icon; final String title; final String detail; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.09), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: VaultColors.muted))])), const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: VaultColors.faint)]))); }

class _InstallCard extends StatelessWidget {
  const _InstallCard();
  @override Widget build(BuildContext context) => SurfaceCard(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeading(title: 'Install the web app', subtitle: 'Use your browser’s app window where supported.'), const SizedBox(height: 12), Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1B1D2A), Color(0xFF18272A)]), borderRadius: BorderRadius.circular(13), border: Border.all(color: VaultColors.cyan.withOpacity(.14))), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: VaultColors.cyan.withOpacity(.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.install_mobile_rounded, size: 19, color: VaultColors.cyan)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ready for your home screen', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Web manifest included · support varies by browser', style: TextStyle(fontSize: 8.5, color: VaultColors.muted))])), ValueListenableBuilder<bool>(valueListenable: install.installPromptAvailable, builder: (context, canInstall, _) => FilledButton(onPressed: () => _install(context, canInstall), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9), textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)), child: Text(canInstall ? 'Install' : 'How to install')))])), const SizedBox(height: 10), const Text('The workspace is local-first. Whether the web app can reopen offline depends on the generated service worker and browser cache; encrypted Vault values remain locked until you enter your passphrase.', style: TextStyle(fontSize: 9, color: VaultColors.muted, height: 1.5))]));
  Future<void> _install(BuildContext context, bool canInstall) async { if (canInstall) { final accepted = await install.promptInstall(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accepted ? 'Comrade Vault is being installed.' : 'Install was dismissed.'))); return; } showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Install Comrade Vault'), content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Chrome or Edge on desktop', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)), SizedBox(height: 4), Text('Use the install icon in the address bar, or choose “Install app” from the browser menu.', style: TextStyle(fontSize: 10, color: VaultColors.muted)), SizedBox(height: 12), Text('Android Chrome', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)), SizedBox(height: 4), Text('Open the browser menu and choose “Install app” or “Add to Home screen”.', style: TextStyle(fontSize: 10, color: VaultColors.muted)), SizedBox(height: 12), Text('iPhone or iPad', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)), SizedBox(height: 4), Text('In Safari, tap Share, then “Add to Home Screen”.', style: TextStyle(fontSize: 10, color: VaultColors.muted))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))])); }
}

class _LocalArchitectureNote extends StatelessWidget { const _LocalArchitectureNote(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: VaultColors.violet.withOpacity(.045), borderRadius: BorderRadius.circular(13), border: Border.all(color: VaultColors.violet.withOpacity(.13))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline_rounded, color: VaultColors.violet, size: 16), const SizedBox(width: 9), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Local-first prototype', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Projects and operational metadata are stored in this browser profile. Vault records are encrypted client-side with AES-256-GCM and PBKDF2 before persistence. No Supabase, authentication server, remote sync or cloud backup is configured in this build.', style: TextStyle(fontSize: 9, color: VaultColors.muted, height: 1.55))]))])); }
