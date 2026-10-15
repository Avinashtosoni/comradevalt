import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';
import '../widgets/navigation.dart';
import 'activity_screen.dart';
import 'assets_screen.dart';
import 'dashboard_screen.dart';
import 'editors.dart';
import 'mind_map_screen.dart';
import 'notes_screen.dart';
import 'notifications_screen.dart';
import 'projects_screen.dart';
import 'renewals_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'vault_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _section = AppSection.mindMap;
  String? _focusNodeId;

  void _navigate(AppSection section) => setState(() => _section = section);
  void _navigateId(String id) => _navigate(AppSectionInfo.fromId(id));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final unread = _unreadNotifications(app.data).length;
    return CallbackShortcuts(bindings: {
      SingleActivator(LogicalKeyboardKey.keyK, control: true): _openSearch,
      SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openSearch,
      SingleActivator(LogicalKeyboardKey.escape): () => FocusManager.instance.primaryFocus?.unfocus(),
    }, child: Focus(autofocus: true, child: Scaffold(body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      if (!app.ready) return const _LoadingShell();
      if (constraints.maxWidth >= 1180) {
        return Row(children: [
          FullNavigation(section: _section.id, onSelect: _navigateId, onSearch: _openSearch, onQuickAdd: _showQuickActions, unreadCount: unread),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withOpacity(.6)),
          Expanded(child: Column(children: [_DesktopHeader(section: _section, isOnline: app.isOnline, unreadCount: unread, onSearch: _openSearch, onQuickAdd: _showQuickActions, onNotifications: () => _navigate(AppSection.notifications)), Expanded(child: _buildMain()), _OfflineBanner(isOnline: app.isOnline, message: app.persistenceMessage)])),
        ]);
      }
      if (constraints.maxWidth >= 760) {
        return Row(children: [
          CompactNavigation(section: _section.id, onSelect: _navigateId, onSearch: _openSearch, onQuickAdd: _showQuickActions, unreadCount: unread),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withOpacity(.6)),
          Expanded(child: Column(children: [_DesktopHeader(section: _section, isOnline: app.isOnline, unreadCount: unread, onSearch: _openSearch, onQuickAdd: _showQuickActions, onNotifications: () => _navigate(AppSection.notifications)), Expanded(child: _buildMain()), _OfflineBanner(isOnline: app.isOnline, message: app.persistenceMessage)])),
        ]);
      }
      return Column(children: [
        _MobileHeader(section: _section, isOnline: app.isOnline, unreadCount: unread, onSearch: _openSearch, onQuickAdd: _showQuickActions, onNotifications: () => _navigate(AppSection.notifications)),
        Expanded(child: _buildMain()),
        if (!app.isOnline || app.persistenceMessage != null) _OfflineBanner(isOnline: app.isOnline, message: app.persistenceMessage),
        NavigationBar(height: 62, selectedIndex: _mobileIndex(_section), onDestinationSelected: (index) {
          if (index == 4) { _showMoreSheet(); return; }
          _navigate([AppSection.mindMap, AppSection.dashboard, AppSection.projects, AppSection.vault][index]);
        }, destinations: const [
          NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub_rounded), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder_copy_rounded), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.key_outlined), selectedIcon: Icon(Icons.key_rounded), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ]),
      ]);
    })))));
  }

  Widget _buildMain() {
    switch (_section) {
      case AppSection.mindMap:
        return MindMapScreen(focusNodeId: _focusNodeId, onFocusHandled: () => setState(() => _focusNodeId = null), onNavigate: _navigate);
      case AppSection.dashboard:
        return DashboardScreen(onNavigate: _navigate);
      case AppSection.projects:
        return ProjectsScreen(onNavigate: _navigate, onFocusNode: (id) { setState(() { _focusNodeId = id; _section = AppSection.mindMap; }); });
      case AppSection.assets:
        return AssetsScreen(onNavigate: _navigate, onFocusNode: (id) { setState(() { _focusNodeId = id; _section = AppSection.mindMap; }); });
      case AppSection.notes:
        return NotesScreen(onNavigate: _navigate);
      case AppSection.vault:
        return const VaultScreen();
      case AppSection.tasks:
        return TasksScreen(onNavigate: _navigate);
      case AppSection.renewals:
        return RenewalsScreen(onNavigate: _navigate);
      case AppSection.activity:
        return const ActivityScreen();
      case AppSection.notifications:
        return NotificationsScreen(onNavigate: _navigate);
      case AppSection.settings:
        return SettingsScreen(onNavigate: _navigate);
    }
  }

  Future<void> _openSearch() async {
    final app = context.read<AppController>();
    final queryController = TextEditingController();
    await showDialog<void>(context: context, barrierColor: Colors.black.withOpacity(.68), builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) {
      final results = _searchResults(app.data, queryController.text.trim());
      return Dialog(backgroundColor: Theme.of(context).colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 590, maxHeight: 620), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 17, 18, 13), child: TextField(controller: queryController, autofocus: true, onChanged: (_) => setDialogState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded, size: 19), hintText: 'Search projects, assets, tasks, notes…', suffixIcon: IconButton(onPressed: () { queryController.clear(); setDialogState(() {}); }, icon: const Icon(Icons.close_rounded, size: 17))))),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Flexible(child: results.isEmpty ? const EmptyState(icon: Icons.manage_search_rounded, title: 'No matches yet', description: 'Try a project, domain, task, note or tag.') : ListView.builder(padding: const EdgeInsets.symmetric(vertical: 9), itemCount: results.length, itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(dense: true, leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), borderRadius: BorderRadius.circular(10)), child: Icon(result.icon, size: 16, color: Theme.of(context).colorScheme.primary)), title: Text(result.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), subtitle: Text('${result.type} · ${result.subtitle}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)), trailing: const Icon(Icons.north_west_rounded, size: 13), onTap: () { Navigator.of(dialogContext).pop(); _selectResult(result); });
        })),
        Padding(padding: const EdgeInsets.fromLTRB(15, 9, 15, 11), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 13, color: VaultColors.muted), const SizedBox(width: 7), const Expanded(child: Text('Vault secrets stay out of search. Notes are searchable but not encrypted.', style: TextStyle(fontSize: 9.5, color: VaultColors.muted))), Text('ESC', style: TextStyle(color: VaultColors.muted.withOpacity(.8), fontSize: 9, fontWeight: FontWeight.w700))])),
      ])));
    }));
    queryController.dispose();
  }

  void _selectResult(_SearchResult result) {
    if (result.nodeId != null) {
      setState(() { _focusNodeId = result.nodeId; _section = AppSection.mindMap; });
      return;
    }
    if (result.noteId != null) {
      final app = context.read<AppController>();
      final matches = app.data.notes.where((note) => note.id == result.noteId);
      final note = matches.isEmpty ? null : matches.first;
      setState(() => _section = AppSection.notes);
      if (note != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showNoteEditor(context, app, note);
        });
      }
      return;
    }
    setState(() => _section = result.section);
  }

  Future<void> _showQuickActions() async {
    final controller = context.read<AppController>();
    final action = await showModalBottomSheet<_QuickAction>(context: context, backgroundColor: Theme.of(context).colorScheme.surface, showDragHandle: true, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick create', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Add a new piece to your digital ecosystem.', style: TextStyle(fontSize: 11, color: VaultColors.muted)), const SizedBox(height: 13),
      Wrap(spacing: 9, runSpacing: 9, children: [
        _QuickActionTile('Project', Icons.folder_copy_rounded, () => Navigator.pop(context, _QuickAction.project)),
        _QuickActionTile('Domain', Icons.language_rounded, () => Navigator.pop(context, _QuickAction.domain)),
        _QuickActionTile('Repository', Icons.code_rounded, () => Navigator.pop(context, _QuickAction.github)),
        _QuickActionTile('Server', Icons.dns_rounded, () => Navigator.pop(context, _QuickAction.server)),
        _QuickActionTile('Cloudflare zone', Icons.cloud_rounded, () => Navigator.pop(context, _QuickAction.cloudflare)),
        _QuickActionTile('API', Icons.api_rounded, () => Navigator.pop(context, _QuickAction.api)),
        _QuickActionTile('Credential', Icons.key_rounded, () => Navigator.pop(context, _QuickAction.credential)),
        _QuickActionTile('Task', Icons.checklist_rounded, () => Navigator.pop(context, _QuickAction.task)),
        _QuickActionTile('Document', Icons.description_outlined, () => Navigator.pop(context, _QuickAction.document)),
        _QuickActionTile('Note', Icons.sticky_note_2_rounded, () => Navigator.pop(context, _QuickAction.note)),
      ]),
    ]))));
    if (!mounted || action == null) return;
    switch (action) {
      case _QuickAction.project: await showProjectEditor(context, controller); break;
      case _QuickAction.domain: await showAssetEditor(context, controller, null, 'Domain'); break;
      case _QuickAction.github: await showAssetEditor(context, controller, null, 'GitHub'); break;
      case _QuickAction.server: await showAssetEditor(context, controller, null, 'Server'); break;
      case _QuickAction.cloudflare: await showAssetEditor(context, controller, null, 'Cloudflare'); break;
      case _QuickAction.api: await showAssetEditor(context, controller, null, 'API'); break;
      case _QuickAction.task: await showTaskEditor(context, controller); break;
      case _QuickAction.document: await showAssetEditor(context, controller, null, 'Document'); break;
      case _QuickAction.note:
        setState(() => _section = AppSection.notes);
        await showNoteEditor(context, controller);
        break;
      case _QuickAction.credential:
        setState(() => _section = AppSection.vault);
        _showMessage('Set up or unlock your Vault to add an encrypted credential.');
        break;
    }
  }

  void _showMoreSheet() {
    showModalBottomSheet<void>(context: context, backgroundColor: Theme.of(context).colorScheme.surface, showDragHandle: true, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(bottom: 9), child: Text('Workspace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
      ...[AppSection.assets, AppSection.notes, AppSection.tasks, AppSection.renewals, AppSection.activity, AppSection.notifications, AppSection.settings].map((section) => ListTile(dense: true, leading: Icon(section.icon, size: 19, color: _section == section ? Theme.of(context).colorScheme.primary : VaultColors.muted), title: Text(section.label, style: const TextStyle(fontSize: 12)), trailing: _section == section ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary, size: 17) : null, onTap: () { Navigator.pop(context); _navigate(section); })),
    ]))));
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}


class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.section, required this.isOnline, required this.unreadCount, required this.onSearch, required this.onQuickAdd, required this.onNotifications});
  final AppSection section;
  final bool isOnline;
  final int unreadCount;
  final VoidCallback onSearch;
  final VoidCallback onQuickAdd;
  final VoidCallback onNotifications;
  @override
  Widget build(BuildContext context) => Container(height: 66, padding: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.55)))), child: Row(children: [
    Icon(section.icon, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 9), Text(section.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), const Spacer(),
    if (!isOnline) Container(margin: const EdgeInsets.only(right: 11), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: VaultColors.amber.withOpacity(.1), borderRadius: BorderRadius.circular(9)), child: const Row(children: [Icon(Icons.cloud_off_rounded, size: 13, color: VaultColors.amber), SizedBox(width: 5), Text('Offline', style: TextStyle(fontSize: 9.5, color: VaultColors.amber, fontWeight: FontWeight.w700))])),
    OutlinedButton.icon(onPressed: onSearch, icon: const Icon(Icons.search_rounded, size: 15), label: const Text('Search', style: TextStyle(fontSize: 10.5)), style: OutlinedButton.styleFrom(foregroundColor: VaultColors.muted, side: BorderSide(color: Theme.of(context).dividerColor), padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)))),
    const SizedBox(width: 8), IconButton(tooltip: 'Notifications', onPressed: onNotifications, icon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount', style: const TextStyle(fontSize: 8)), child: const Icon(Icons.notifications_none_rounded, size: 19))),
    const SizedBox(width: 6), PrimaryAction(label: 'Quick create', onPressed: onQuickAdd, compact: true),
  ]));
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.section, required this.isOnline, required this.unreadCount, required this.onSearch, required this.onQuickAdd, required this.onNotifications});
  final AppSection section;
  final bool isOnline;
  final int unreadCount;
  final VoidCallback onSearch;
  final VoidCallback onQuickAdd;
  final VoidCallback onNotifications;
  @override
  Widget build(BuildContext context) => Container(height: 58, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.55))),), child: Row(children: [
    const BrandMark(size: 30), const SizedBox(width: 9), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(section.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), Row(children: [Container(width: 5, height: 5, decoration: BoxDecoration(color: isOnline ? VaultColors.green : VaultColors.amber, shape: BoxShape.circle)), const SizedBox(width: 5), Text(isOnline ? 'Local workspace' : 'Offline mode', style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))])])),
    IconButton(visualDensity: VisualDensity.compact, tooltip: 'Search', onPressed: onSearch, icon: const Icon(Icons.search_rounded, size: 20)),
    IconButton(visualDensity: VisualDensity.compact, tooltip: 'Notifications', onPressed: onNotifications, icon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount', style: const TextStyle(fontSize: 8)), child: const Icon(Icons.notifications_none_rounded, size: 19))),
    IconButton(visualDensity: VisualDensity.compact, tooltip: 'Quick create', onPressed: onQuickAdd, icon: Icon(Icons.add_circle_rounded, size: 23, color: Theme.of(context).colorScheme.primary)),
  ]));
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Container(width: 104, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(13), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(children: [Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600))])));
}

enum _QuickAction { project, domain, github, server, cloudflare, api, credential, task, document, note }

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isOnline, this.message});
  final bool isOnline;
  final String? message;
  @override
  Widget build(BuildContext context) {
    if (isOnline && message == null) return const SizedBox.shrink();
    final isStorageError = message != null;
    return Container(width: double.infinity, color: isStorageError ? VaultColors.red.withOpacity(.1) : VaultColors.amber.withOpacity(.1), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7), child: Row(children: [Icon(isStorageError ? Icons.warning_amber_rounded : Icons.cloud_off_rounded, size: 14, color: isStorageError ? VaultColors.red : VaultColors.amber), const SizedBox(width: 7), Expanded(child: Text(message ?? 'Network unavailable. This workspace is stored locally; it is not syncing.', style: TextStyle(fontSize: 10, color: isStorageError ? VaultColors.red : VaultColors.amber))), if (!isStorageError) const Text('SYNC PAUSED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .8, color: VaultColors.amber))]));
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const BrandMark(size: 52), const SizedBox(height: 18), const SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 2)), const SizedBox(height: 11), Text('Preparing your workspace…', style: Theme.of(context).textTheme.bodySmall)]));
}

class _SearchResult {
  const _SearchResult({required this.title, required this.subtitle, required this.type, required this.icon, required this.section, this.nodeId, this.noteId});
  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final AppSection section;
  final String? nodeId;
  final String? noteId;
}

List<_SearchResult> _searchResults(WorkspaceData data, String query) {
  if (query.isEmpty) return const [];
  final q = query.toLowerCase();
  final results = <_SearchResult>[];
  for (final project in data.projects) {
    if ('${project.name} ${project.description} ${project.category} ${project.tags.join(' ')}'.toLowerCase().contains(q)) results.add(_SearchResult(title: project.name, subtitle: project.status, type: 'Project', icon: Icons.folder_copy_rounded, section: AppSection.projects, nodeId: data.nodes.any((node) => node.id == 'node-${project.id}') ? 'node-${project.id}' : null));
  }
  for (final asset in data.assets) {
    if ('${asset.name} ${asset.type} ${asset.summary} ${asset.tags.join(' ')} ${asset.fields.values.join(' ')}'.toLowerCase().contains(q)) results.add(_SearchResult(title: asset.name, subtitle: asset.status, type: asset.type, icon: _assetIcon(asset.type), section: AppSection.assets, nodeId: data.nodes.any((node) => node.id == 'node-${asset.id}') ? 'node-${asset.id}' : null));
  }
  for (final task in data.tasks) {
    if ('${task.title} ${task.description} ${task.tags.join(' ')}'.toLowerCase().contains(q)) results.add(_SearchResult(title: task.title, subtitle: task.status, type: 'Task', icon: Icons.checklist_rounded, section: AppSection.tasks));
  }
  for (final renewal in data.renewals) {
    if ('${renewal.title} ${renewal.provider} ${renewal.category}'.toLowerCase().contains(q)) results.add(_SearchResult(title: renewal.title, subtitle: renewal.provider, type: 'Renewal', icon: Icons.event_repeat_rounded, section: AppSection.renewals));
  }
  for (final note in data.notes) {
    if ('${note.title} ${note.body} ${note.tags.join(' ')}'.toLowerCase().contains(q)) {
      results.add(_SearchResult(title: note.title, subtitle: note.tags.isEmpty ? 'Workspace note' : note.tags.map((tag) => '#$tag').join(' '), type: 'Note', icon: Icons.sticky_note_2_rounded, section: AppSection.notes, noteId: note.id));
    }
  }
  for (final node in data.nodes) {
    if ('${node.label} ${node.type} ${node.description}'.toLowerCase().contains(q) && !results.any((result) => result.nodeId == node.id)) results.add(_SearchResult(title: node.label, subtitle: node.status, type: node.type, icon: _assetIcon(node.type), section: AppSection.mindMap, nodeId: node.id));
  }
  return results.take(18).toList();
}

IconData _assetIcon(String type) => switch (type) {
  'Workspace' => Icons.hub_rounded, 'Project' => Icons.folder_copy_rounded, 'Domain' => Icons.language_rounded,
  'GitHub' => Icons.code_rounded, 'Cloudflare' => Icons.cloud_rounded, 'Server' || 'VPS' || 'Hosting' => Icons.dns_rounded,
  'Database' => Icons.storage_rounded, 'API' => Icons.api_rounded, 'SaaS' => Icons.apps_rounded, 'Email' => Icons.alternate_email_rounded,
  'Document' => Icons.description_outlined, 'Task' => Icons.checklist_rounded, 'Social Account' => Icons.people_alt_rounded,
  'Payment Gateway' => Icons.payments_outlined, 'Storage' => Icons.folder_open_rounded, 'Device' => Icons.devices_rounded, _ => Icons.widgets_rounded,
};

int _mobileIndex(AppSection section) => switch (section) { AppSection.mindMap => 0, AppSection.dashboard => 1, AppSection.projects => 2, AppSection.vault => 3, _ => 4 };

List<_SearchResult> _unreadNotifications(WorkspaceData data) {
  final output = <_SearchResult>[];
  for (final task in data.tasks.where((task) => task.status != 'Done' && _daysUntil(task.dueDate) <= 2)) {
    final key = 'task:${task.id}';
    if (!data.notificationsRead.contains(key)) output.add(_SearchResult(title: task.title, subtitle: 'Task due ${task.dueDate}', type: 'Task due', icon: Icons.checklist_rounded, section: AppSection.tasks));
  }
  for (final renewal in data.renewals.where((item) => _daysUntil(item.dueDate) < 0 || item.reminders.any((reminder) => _daysUntil(item.dueDate) <= reminder))) {
    final key = 'renewal:${renewal.id}';
    if (!data.notificationsRead.contains(key)) output.add(_SearchResult(title: renewal.title, subtitle: '${renewal.category} renewal · ${renewal.dueDate}', type: 'Renewal', icon: Icons.event_repeat_rounded, section: AppSection.renewals));
  }
  for (final asset in data.assets.where((item) => item.status == 'Attention' || item.status == 'Offline')) {
    final key = 'asset:${asset.id}';
    if (!data.notificationsRead.contains(key)) output.add(_SearchResult(title: asset.name, subtitle: asset.summary, type: 'Asset review', icon: Icons.warning_amber_rounded, section: AppSection.assets));
  }
  return output;
}

int _daysUntil(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return 99999;
  return DateUtils.dateOnly(date).difference(DateUtils.dateOnly(DateTime.now())).inDays;
}
