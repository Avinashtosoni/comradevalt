import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../services/vault_service.dart';
import '../widgets/common.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      context.read<VaultService>().lock();
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<VaultService>(builder: (context, vault, _) {
        return Listener(
          onPointerDown: (_) => vault.touch(),
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final pad = compact ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, compact ? 17 : 27, pad, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        eyebrow: 'PRIVATE STORAGE',
                        title: 'Vault',
                        subtitle: 'Your credentials, encrypted before they ever touch local storage.',
                        count: vault.isUnlocked ? vault.count.toString().padLeft(2, '0') : null,
                      ),
                      if (vault.errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: VaultColors.amber.withOpacity(.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: VaultColors.amber.withOpacity(.2))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 15, color: VaultColors.amber),
                              const SizedBox(width: 8),
                              Expanded(child: Text(vault.errorMessage!, style: const TextStyle(fontSize: 9.5, color: VaultColors.amber, height: 1.45))),
                            ],
                          ),
                        ),
                      if (!vault.hasVault)
                        _CreateVaultCard(onCreate: (passphrase) => _create(context, vault, passphrase))
                      else if (!vault.isUnlocked)
                        _UnlockVaultCard(onUnlock: (passphrase) => _unlock(context, vault, passphrase))
                      else
                        _UnlockedVault(vault: vault),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      });

  Future<void> _create(BuildContext context, VaultService vault, String passphrase) async {
    try {
      await vault.createVault(passphrase);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your encrypted vault is ready on this device.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_safeError(error))));
    }
  }

  Future<void> _unlock(BuildContext context, VaultService vault, String passphrase) async {
    try {
      await vault.unlock(passphrase);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault unlocked.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_safeError(error))));
    }
  }
}

class _CreateVaultCard extends StatelessWidget {
  const _CreateVaultCard({required this.onCreate});
  final Future<void> Function(String) onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 590),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(24, 25, 24, 22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(21),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.13), blurRadius: 25, offset: const Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [VaultColors.violet.withOpacity(.24), VaultColors.violet.withOpacity(.04)]),
                      border: Border.all(color: VaultColors.violet.withOpacity(.26)),
                    ),
                    child: const Icon(Icons.key_rounded, size: 30, color: VaultColors.violet),
                  ),
                ),
                const SizedBox(height: 18),
                Center(child: Text('Build your private vault', style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 7),
                const Text('One master passphrase protects your credentials. It never leaves this device and can’t be recovered if forgotten.', textAlign: TextAlign.center, style: TextStyle(color: VaultColors.muted, fontSize: 10.5, height: 1.6)),
                const SizedBox(height: 19),
                const _EncryptionSteps(),
                const SizedBox(height: 18),
                _PassphraseForm(buttonLabel: 'Create encrypted vault', onSubmit: onCreate, requireConfirmation: true),
                const SizedBox(height: 13),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 15, color: VaultColors.amber),
                    SizedBox(width: 7),
                    Expanded(child: Text('Choose a strong passphrase and keep a safe backup. There is no password reset and we cannot recover your data.', style: TextStyle(color: VaultColors.amber, fontSize: 9, height: 1.45))),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _UnlockVaultCard extends StatelessWidget {
  const _UnlockVaultCard({required this.onUnlock});
  final Future<void> Function(String) onUnlock;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 515),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(24, 23, 24, 22),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(21)),
            child: Column(
              children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: VaultColors.green.withOpacity(.1), borderRadius: BorderRadius.circular(21)), child: const Icon(Icons.lock_rounded, color: VaultColors.green, size: 27)),
                const SizedBox(height: 14),
                Text('Your vault is locked', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 5),
                const Text('Enter your master passphrase to decrypt credentials on this device.', textAlign: TextAlign.center, style: TextStyle(color: VaultColors.muted, fontSize: 10.5, height: 1.5)),
                const SizedBox(height: 21),
                _PassphraseForm(buttonLabel: 'Unlock Vault', onSubmit: onUnlock, requireConfirmation: false),
                const SizedBox(height: 13),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 13, color: VaultColors.green),
                    SizedBox(width: 6),
                    Text('AES-256-GCM · PBKDF2 key derivation', style: TextStyle(fontSize: 8.5, color: VaultColors.muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _EncryptionSteps extends StatelessWidget {
  const _EncryptionSteps();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
        child: const Row(
          children: [
            _StepChip('01', 'Passphrase'),
            Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 15, color: VaultColors.faint)),
            _StepChip('02', 'Key derivation'),
            Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 15, color: VaultColors.faint)),
            _StepChip('03', 'Local encryption'),
          ],
        ),
      );
}

class _StepChip extends StatelessWidget {
  const _StepChip(this.number, this.label);
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(number, style: const TextStyle(fontSize: 8, color: VaultColors.cyan, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: VaultColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PassphraseForm extends StatefulWidget {
  const _PassphraseForm({required this.buttonLabel, required this.onSubmit, required this.requireConfirmation});
  final String buttonLabel;
  final Future<void> Function(String) onSubmit;
  final bool requireConfirmation;
  @override
  State<_PassphraseForm> createState() => _PassphraseFormState();
}

class _PassphraseFormState extends State<_PassphraseForm> {
  final _form = GlobalKey<FormState>();
  final _passphrase = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_passphrase.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _passphrase,
              obscureText: _obscure,
              autofocus: !widget.requireConfirmation,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your master passphrase';
                if (widget.requireConfirmation && value.length < 12) return 'Use at least 12 characters';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Master passphrase',
                hintText: widget.requireConfirmation ? 'At least 12 characters' : 'Enter your passphrase',
                prefixIcon: const Icon(Icons.key_outlined, size: 17),
                suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 17)),
              ),
            ),
            if (widget.requireConfirmation) ...[
              const SizedBox(height: 11),
              _PassphraseStrength(value: _passphrase.text),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                validator: (value) => value != _passphrase.text ? 'Passphrases do not match' : null,
                decoration: const InputDecoration(labelText: 'Confirm passphrase', prefixIcon: Icon(Icons.verified_user_outlined, size: 17)),
              ),
            ],
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(widget.requireConfirmation ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 16),
                label: Text(_busy ? 'Working securely…' : widget.buttonLabel),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
}

class _PassphraseStrength extends StatelessWidget {
  const _PassphraseStrength({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final score = _strength(value);
    final color = score < 2 ? VaultColors.red : score < 4 ? VaultColors.amber : VaultColors.green;
    final label = score < 2 ? 'Weak' : score < 4 ? 'Getting stronger' : 'Strong passphrase';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(children: [for (var index = 0; index < 4; index++) Expanded(child: Container(height: 3, margin: EdgeInsets.only(right: index == 3 ? 0 : 4), color: score > index ? color : Theme.of(context).dividerColor))]),
            ),
          ),
          const SizedBox(width: 8),
          Text(value.isEmpty ? 'Aim for 12+ characters' : label, style: TextStyle(fontSize: 8.5, color: value.isEmpty ? VaultColors.muted : color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _UnlockedVault extends StatefulWidget {
  const _UnlockedVault({required this.vault});
  final VaultService vault;
  @override
  State<_UnlockedVault> createState() => _UnlockedVaultState();
}

class _UnlockedVaultState extends State<_UnlockedVault> {
  String _filter = 'All';
  String _query = '';
  final _search = TextEditingController();
  bool _revealAll = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vault = widget.vault;
    final categories = <String>{'All', ...vault.items.map((item) => item.category)}.toList();
    final items = vault.items.where((item) => (_filter == 'All' || item.category == _filter) && '${item.title} ${item.category} ${item.username} ${item.website} ${item.tags.join(' ')}'.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B2830), Color(0xFF191928)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: VaultColors.cyan.withOpacity(.17))),
          child: Row(
            children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: VaultColors.green.withOpacity(.13), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.verified_user_rounded, size: 19, color: VaultColors.green)),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Encrypted on this device', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Master passphrase is never stored. Vault locks automatically after inactivity.', style: TextStyle(fontSize: 9, color: VaultColors.muted)),
                  ],
                ),
              ),
              IconButton(tooltip: 'Lock Vault now', onPressed: vault.lock, icon: const Icon(Icons.lock_rounded, size: 18, color: VaultColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(child: _VaultMetric(icon: Icons.key_rounded, value: vault.count, label: 'Encrypted items', tint: VaultColors.violet)),
            const SizedBox(width: 9),
            Expanded(child: _VaultMetric(icon: Icons.category_outlined, value: categories.length - 1, label: 'Categories', tint: VaultColors.cyan)),
            const SizedBox(width: 9),
            Expanded(child: _VaultMetric(icon: Icons.timer_outlined, value: vault.autoLockMinutes, label: 'Min auto-lock', tint: VaultColors.amber)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Text('Your credentials', style: Theme.of(context).textTheme.titleMedium)),
            OutlinedButton.icon(
              onPressed: () => setState(() => _revealAll = !_revealAll),
              icon: Icon(_revealAll ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 14),
              label: Text(_revealAll ? 'Hide all' : 'Show secrets', style: const TextStyle(fontSize: 9)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
            ),
            const SizedBox(width: 7),
            FilledButton.icon(
              onPressed: () => _showSecretEditor(context, vault),
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text('Add item', style: TextStyle(fontSize: 9.5)),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search_rounded, size: 16), hintText: 'Search unlocked items'),
              ),
            ),
            const SizedBox(width: 9),
            PopupMenuButton<String>(
              tooltip: 'Filter category',
              icon: const Icon(Icons.tune_rounded, size: 18),
              onSelected: (value) => setState(() => _filter = value),
              itemBuilder: (_) => categories.map((category) => PopupMenuItem(value: category, child: Text(category, style: const TextStyle(fontSize: 11)))).toList(),
            ),
          ],
        ),
        const SizedBox(height: 11),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: EmptyState(
              icon: Icons.key_off_rounded,
              title: vault.count == 0 ? 'Your vault is empty' : 'No matching credentials',
              description: vault.count == 0 ? 'Add a credential to start building your encrypted vault.' : 'Try a different search or category filter.',
              actionLabel: vault.count == 0 ? 'Add credential' : null,
              onAction: vault.count == 0 ? () => _showSecretEditor(context, vault) : null,
            ),
          )
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _SecretCard(
                  item: item,
                  reveal: _revealAll,
                  onEdit: () => _showSecretEditor(context, vault, item),
                  onDelete: () => _deleteSecret(context, vault, item),
                  onTouch: vault.touch,
                ),
              )),
        const SizedBox(height: 10),
        Center(child: TextButton.icon(onPressed: vault.lock, icon: const Icon(Icons.lock_outline_rounded, size: 15), label: const Text('Lock Vault now', style: TextStyle(fontSize: 10)))),
        const Center(child: Text('Copied secrets stay in your clipboard until replaced.', style: TextStyle(fontSize: 8.5, color: VaultColors.faint))),
      ],
    );
  }

  Future<void> _showSecretEditor(BuildContext context, VaultService vault, [VaultSecret? existing]) async {
    final result = await showDialog<VaultSecret>(context: context, builder: (_) => _SecretEditor(existing: existing));
    if (result == null) return;
    try {
      await vault.saveSecret(result);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credential encrypted and saved.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this credential. Try again.')));
    }
  }

  Future<void> _deleteSecret(BuildContext context, VaultService vault, VaultSecret item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete credential?'),
        content: Text('“${item.title}” will be permanently removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await vault.deleteSecret(item.id);
      } catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not remove this item.')));
      }
    }
  }
}

class _VaultMetric extends StatelessWidget {
  const _VaultMetric({required this.icon, required this.value, required this.label, required this.tint});
  final IconData icon;
  final int value;
  final String label;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(13)),
        child: Row(
          children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(color: tint.withOpacity(.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 15, color: tint)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: VaultColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SecretCard extends StatefulWidget {
  const _SecretCard({required this.item, required this.reveal, required this.onEdit, required this.onDelete, required this.onTouch});
  final VaultSecret item;
  final bool reveal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTouch;
  @override
  State<_SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<_SecretCard> {
  bool _show = false;
  @override
  Widget build(BuildContext context) {
    final show = _show || widget.reveal;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 9, 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: VaultColors.violet.withOpacity(.11), borderRadius: BorderRadius.circular(10)), child: Icon(_categoryIcon(widget.item.category), size: 16, color: VaultColors.violet)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(widget.item.category, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted)),
                  ],
                ),
              ),
              IconButton(tooltip: 'Edit credential', onPressed: widget.onEdit, icon: const Icon(Icons.edit_outlined, size: 15, color: VaultColors.muted)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 16, color: VaultColors.muted),
                onSelected: (value) => value == 'delete' ? widget.onDelete() : widget.onEdit(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit item')),
                  PopupMenuItem(value: 'delete', child: Text('Delete item')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (widget.item.username.isNotEmpty)
            _SecretValueRow(label: 'USERNAME', value: widget.item.username, shown: true, onCopy: () => _copy(context, widget.item.username)),
          if (widget.item.secret.isNotEmpty)
            _SecretValueRow(
              label: 'SECRET',
              value: widget.item.secret,
              shown: show,
              onToggle: () {
                widget.onTouch();
                setState(() => _show = !_show);
              },
              onCopy: () => _copy(context, widget.item.secret),
            ),
          if (widget.item.website.isNotEmpty)
            _SecretValueRow(label: 'WEBSITE', value: widget.item.website, shown: true, onCopy: () => _copy(context, widget.item.website)),
          if (widget.item.notes.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 7), child: Text(widget.item.notes, style: const TextStyle(fontSize: 9, color: VaultColors.muted))),
          if (widget.item.tags.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 7), child: Wrap(spacing: 5, runSpacing: 4, children: widget.item.tags.map((tag) => TagChip(tag)).toList())),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    widget.onTouch();
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard. Clear it when you’re done.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard access is unavailable in this browser.')));
    }
  }
}

class _SecretValueRow extends StatelessWidget {
  const _SecretValueRow({required this.label, required this.value, required this.shown, this.onToggle, this.onCopy});
  final String label;
  final String value;
  final bool shown;
  final VoidCallback? onToggle;
  final VoidCallback? onCopy;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            SizedBox(width: 62, child: Text(label, style: const TextStyle(fontSize: 7.3, color: VaultColors.faint, fontWeight: FontWeight.w800, letterSpacing: .7))),
            Expanded(child: Text(shown ? value : '••••••••••••', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: VaultColors.muted, fontFamily: 'monospace'))),
            if (onToggle != null)
              IconButton(visualDensity: VisualDensity.compact, tooltip: shown ? 'Hide secret' : 'Reveal secret', onPressed: onToggle, icon: Icon(shown ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 14, color: VaultColors.muted)),
            if (onCopy != null)
              IconButton(visualDensity: VisualDensity.compact, tooltip: 'Copy $label', onPressed: onCopy, icon: const Icon(Icons.copy_rounded, size: 13, color: VaultColors.muted)),
          ],
        ),
      );
}

class _SecretEditor extends StatefulWidget {
  const _SecretEditor({this.existing});
  final VaultSecret? existing;
  @override
  State<_SecretEditor> createState() => _SecretEditorState();
}

class _SecretEditorState extends State<_SecretEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _secret;
  late final TextEditingController _website;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  late String _category;
  bool _obscure = true;

  static const categories = ['Username', 'Password', 'API Key', 'Secret Key', 'Token', 'SSH Key', 'Recovery Code', 'License Key', 'Database Credential', 'SMTP Credential', 'OAuth Credential'];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? '');
    _username = TextEditingController(text: item?.username ?? '');
    _secret = TextEditingController(text: item?.secret ?? '');
    _website = TextEditingController(text: item?.website ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
    _tags = TextEditingController(text: item?.tags.join(', ') ?? '');
    _category = item?.category ?? 'Password';
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _secret.dispose();
    _website.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = [...categories];
    if (!categoryOptions.contains(_category)) categoryOptions.insert(0, _category);
    return AlertDialog(
        title: Text(widget.existing == null ? 'Add encrypted credential' : 'Edit credential'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: VaultColors.green.withOpacity(.07), borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 14, color: VaultColors.green),
                        SizedBox(width: 7),
                        Expanded(child: Text('Only encrypted bytes are written to local storage.', style: TextStyle(fontSize: 9, color: VaultColors.green))),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _title,
                    autofocus: true,
                    validator: (value) => value == null || value.trim().isEmpty ? 'A title is required' : null,
                    decoration: const InputDecoration(labelText: 'Item name *', hintText: 'e.g. Production database'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categoryOptions.map((category) => DropdownMenuItem(value: category, child: Text(category, style: const TextStyle(fontSize: 11)))).toList(),
                    onChanged: (value) => setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username / account', prefixIcon: Icon(Icons.person_outline_rounded, size: 16))),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _secret,
                    obscureText: _obscure,
                    maxLines: 1,
                    decoration: InputDecoration(
                      labelText: 'Secret value',
                      prefixIcon: const Icon(Icons.key_outlined, size: 16),
                      suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: _website, decoration: const InputDecoration(labelText: 'Website / service URL', prefixIcon: Icon(Icons.language_rounded, size: 16))),
                  const SizedBox(height: 10),
                  TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
                  const SizedBox(height: 10),
                  TextFormField(controller: _tags, decoration: const InputDecoration(labelText: 'Tags', hintText: 'production, business')),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              final tags = _tags.text.split(',').map((tag) => tag.trim().replaceFirst(RegExp(r'^#'), '')).where((tag) => tag.isNotEmpty).toSet().toList();
              Navigator.pop(
                context,
                VaultSecret(
                  id: widget.existing?.id ?? '',
                  title: _title.text.trim(),
                  category: _category,
                  username: _username.text.trim(),
                  secret: _secret.text,
                  website: _website.text.trim(),
                  notes: _notes.text.trim(),
                  tags: tags,
                ),
              );
            },
            icon: const Icon(Icons.lock_rounded, size: 15),
            label: const Text('Encrypt & save'),
          ),
        ],
      );
  }
}

int _strength(String value) {
  if (value.isEmpty) return 0;
  var score = 0;
  if (value.length >= 12) score++;
  if (value.length >= 16) score++;
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) score++;
  if (RegExp(r'\d').hasMatch(value) && RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) score++;
  return score;
}

IconData _categoryIcon(String category) => switch (category) {
      'Password' || 'Username' => Icons.password_rounded,
      'API Key' || 'Secret Key' || 'Token' => Icons.vpn_key_rounded,
      'SSH Key' => Icons.terminal_rounded,
      'Database Credential' => Icons.storage_rounded,
      'SMTP Credential' => Icons.alternate_email_rounded,
      'Recovery Code' => Icons.verified_user_outlined,
      _ => Icons.key_rounded,
    };

String _safeError(Object error) {
  final text = error.toString();
  if (text.contains('passphrase') || text.contains('vault')) return text.replaceFirst('Bad state: ', '');
  return 'The vault could not be opened. Check your browser storage and try again.';
}
