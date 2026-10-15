import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';
import 'editors.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, required this.onNavigate, required this.onFocusNode});
  final ValueChanged<AppSection> onNavigate;
  final ValueChanged<String> onFocusNode;
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _filter = 'All projects';
  String _query = '';
  final _searchController = TextEditingController();
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final projects = app.data.projects.where((item) {
      final matchesQuery = '${item.name} ${item.description} ${item.category} ${item.tags.join(' ')}'.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = _filter == 'All projects' || (_filter == 'Active' ? !['Archived', 'Paused'].contains(item.status) : item.status == _filter);
      return matchesQuery && matchesFilter;
    }).toList();
    final active = app.data.projects.where((item) => !['Paused', 'Archived'].contains(item.status)).length;
    final live = app.data.projects.where((item) => ['Production', 'Maintenance'].contains(item.status)).length;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      final pad = compact ? 16.0 : 28.0;
      return SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, compact ? 18 : 27, pad, 30), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(eyebrow: 'WORKSPACE / PROJECTS', title: 'Your projects', subtitle: 'Keep every initiative moving in the right direction.', count: app.data.projects.length.toString().padLeft(2, '0'), actions: compact ? null : Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () => widget.onNavigate(AppSection.mindMap), icon: const Icon(Icons.hub_rounded, size: 15), label: const Text('View mind map')), PrimaryAction(label: 'New project', onPressed: () => showProjectEditor(context, app))])),
        _ProjectSummaryStrip(total: app.data.projects.length, active: active, live: live),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All projects', 'Active', 'Idea', 'Planning', 'Development', 'Production', 'Paused'].map((item) => Padding(padding: const EdgeInsets.only(right: 6), child: _FilterChip(label: item, selected: _filter == item, count: item == 'All projects' ? app.data.projects.length : null, onTap: () => setState(() => _filter = item)))).toList()))), if (!compact) const SizedBox(width: 12), if (!compact) SizedBox(width: 205, child: _SearchBox(controller: _searchController, hint: 'Search projects', onChanged: (value) => setState(() => _query = value)))]),
        if (compact) Padding(padding: const EdgeInsets.only(top: 11), child: _SearchBox(controller: _searchController, hint: 'Search projects', onChanged: (value) => setState(() => _query = value))),
        const SizedBox(height: 15),
        if (projects.isEmpty) EmptyState(icon: Icons.folder_copy_outlined, title: _query.isEmpty ? 'No projects yet' : 'No matching projects', description: _query.isEmpty ? 'Create your first project to start building your digital ecosystem.' : 'Try another search or change the selected filter.', actionLabel: 'New project', onAction: () => showProjectEditor(context, app))
        else LayoutBuilder(builder: (context, gridConstraints) {
          final columns = gridConstraints.maxWidth > 1120 ? 3 : gridConstraints.maxWidth > 720 ? 2 : 1;
          return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: projects.length + 1, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: 293, crossAxisSpacing: 13, mainAxisSpacing: 13), itemBuilder: (context, index) {
            if (index == projects.length) return _NewProjectCard(onTap: () => showProjectEditor(context, app));
            return _ProjectCard(project: projects[index], index: index, projects: app.data.projects, assets: app.data.assets, tasks: app.data.tasks, onOpen: () => _showDetails(context, projects[index], app), onEdit: () => showProjectEditor(context, app, projects[index]), onDelete: () => _deleteProject(context, app, projects[index]), onFocus: () => widget.onFocusNode('node-${projects[index].id}'));
          });
        }),
      ]))));
    });
  }

  Future<void> _showDetails(BuildContext context, ProjectItem project, AppController app) => showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).colorScheme.surface, showDragHandle: true, builder: (sheetContext) {
    final current = app.data.projects.where((item) => item.id == project.id).firstOrNull ?? project;
    final assets = app.data.assets.where((item) => item.projectId == project.id).toList();
    final tasks = app.data.tasks.where((item) => item.projectId == project.id && item.status != 'Done').toList();
    return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 3, 20, 24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(current.category.isEmpty ? 'PROJECT' : current.category.toUpperCase(), style: TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)), const SizedBox(height: 7), Text(current.name, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 7), Text(current.description, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 14),
      Row(children: [StatusBadge(current.status), const SizedBox(width: 8), _PriorityPill(current.priority), const Spacer(), Text('${current.progress}% complete', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))]), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(7), child: LinearProgressIndicator(value: current.progress / 100, minHeight: 6, color: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).dividerColor)), const SizedBox(height: 18),
      _DetailPair(label: 'Current phase', value: current.currentPhase.isEmpty ? current.status : current.currentPhase), _DetailPair(label: 'Next action', value: current.nextAction.isEmpty ? 'Not set' : current.nextAction), _DetailPair(label: 'Blockers', value: current.blockers.isEmpty ? 'None' : current.blockers, warning: current.blockers.isNotEmpty), _DetailPair(label: 'Target date', value: _formatDate(current.targetDate)),
      const SizedBox(height: 14), Text('Connected assets', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 7), if (assets.isEmpty) const Text('No assets connected yet.', style: TextStyle(color: VaultColors.muted, fontSize: 11)) else ...assets.take(5).map((asset) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: _AssetGlyph(type: asset.type, size: 32), title: Text(asset.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), subtitle: Text(asset.type, style: const TextStyle(fontSize: 9)), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12), onTap: () { Navigator.pop(sheetContext); widget.onNavigate(AppSection.assets); })),
      const SizedBox(height: 12), Text('Open tasks · ${tasks.length}', style: Theme.of(context).textTheme.titleMedium), if (tasks.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No open tasks.', style: TextStyle(fontSize: 10, color: VaultColors.muted))) else ...tasks.take(4).map((task) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.circle_outlined, color: statusColor(task.status), size: 17), title: Text(task.title, style: const TextStyle(fontSize: 11)), subtitle: Text('Due ${_formatDate(task.dueDate)}', style: const TextStyle(fontSize: 9)), onTap: () { Navigator.pop(sheetContext); widget.onNavigate(AppSection.tasks); })),
      const SizedBox(height: 16), Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); widget.onFocusNode('node-${current.id}'); }, icon: const Icon(Icons.hub_rounded, size: 15), label: const Text('Open in mind map')), FilledButton.icon(onPressed: () { Navigator.pop(sheetContext); showProjectEditor(context, app, current); }, icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Edit project'))]),
    ])))));
  });

  Future<void> _deleteProject(BuildContext context, AppController app, ProjectItem project) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete project?'), content: Text('“${project.name}” will be removed. Its assets and tasks will stay in your workspace but will be unlinked.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))]));
    if (confirmed == true) app.deleteProject(project);
  }
}

class _ProjectSummaryStrip extends StatelessWidget {
  const _ProjectSummaryStrip({required this.total, required this.active, required this.live});
  final int total; final int active; final int live;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [
    _SummaryMetric(icon: Icons.folder_copy_rounded, tint: VaultColors.violet, value: total, label: 'Total projects'), _SummaryDivider(), _SummaryMetric(icon: Icons.auto_awesome_rounded, tint: VaultColors.cyan, value: active, label: 'In motion'), _SummaryDivider(), _SummaryMetric(icon: Icons.check_circle_outline_rounded, tint: VaultColors.blue, value: live, label: 'Live & maintained'), const Spacer(), if (MediaQuery.sizeOf(context).width > 720) const Row(children: [Icon(Icons.hub_rounded, size: 13, color: VaultColors.cyan), SizedBox(width: 6), Text('Projects connect to your digital assets', style: TextStyle(fontSize: 9.5, color: VaultColors.muted))]),
  ]));
}
class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.icon, required this.tint, required this.value, required this.label});
  final IconData icon; final Color tint; final int value; final String label;
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: tint.withOpacity(.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 15, color: tint)), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text(label, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))])]);
}
class _SummaryDivider extends StatelessWidget { @override Widget build(BuildContext context) => Container(height: 28, width: 1, margin: const EdgeInsets.symmetric(horizontal: 17), color: Theme.of(context).dividerColor); }

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.count});
  final String label; final bool selected; final VoidCallback onTap; final int? count;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label), if (count != null) ...[const SizedBox(width: 6), Text('$count', style: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted, fontSize: 9, fontWeight: FontWeight.w800))]]), selected: selected, onSelected: (_) => onTap(), labelStyle: TextStyle(fontSize: 9.5, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted, fontWeight: selected ? FontWeight.w700 : FontWeight.w500), visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 3), side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.28) : Theme.of(context).dividerColor), backgroundColor: Theme.of(context).colorScheme.surface, selectedColor: Theme.of(context).colorScheme.primary.withOpacity(.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))));
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.hint, required this.onChanged});
  final TextEditingController controller; final String hint; final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(controller: controller, onChanged: onChanged, decoration: InputDecoration(isDense: true, hintText: hint, prefixIcon: const Icon(Icons.search_rounded, size: 16), contentPadding: const EdgeInsets.symmetric(vertical: 10), suffixIcon: controller.text.isEmpty ? null : IconButton(onPressed: () { controller.clear(); onChanged(''); }, icon: const Icon(Icons.close_rounded, size: 14))));
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.index, required this.projects, required this.assets, required this.tasks, required this.onOpen, required this.onEdit, required this.onDelete, required this.onFocus});
  final ProjectItem project; final int index; final List<ProjectItem> projects; final List<AssetItem> assets; final List<TaskItem> tasks; final VoidCallback onOpen; final VoidCallback onEdit; final VoidCallback onDelete; final VoidCallback onFocus;
  @override
  Widget build(BuildContext context) {
    final colors = [VaultColors.violet, VaultColors.cyan, VaultColors.blue, VaultColors.pink];
    final tint = colors[index % colors.length];
    final assetCount = assets.where((asset) => asset.projectId == project.id).length;
    final taskCount = tasks.where((task) => task.projectId == project.id && task.status != 'Done').length;
    return Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(17), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 35, height: 35, alignment: Alignment.center, decoration: BoxDecoration(color: tint.withOpacity(.14), borderRadius: BorderRadius.circular(11)), child: Text(project.name.split(' ').map((word) => word.isEmpty ? '' : word[0]).take(2).join().toUpperCase(), style: TextStyle(color: tint, fontSize: 10, fontWeight: FontWeight.w800))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(project.category.isEmpty ? 'Uncategorised' : project.category, style: const TextStyle(color: VaultColors.muted, fontSize: 9))])), PopupMenuButton<String>(tooltip: 'Project options', icon: const Icon(Icons.more_horiz_rounded, color: VaultColors.muted, size: 19), onSelected: (value) => value == 'edit' ? onEdit() : value == 'delete' ? onDelete() : onOpen(), itemBuilder: (_) => const [PopupMenuItem(value: 'details', child: Text('View details')), PopupMenuItem(value: 'edit', child: Text('Edit project')), PopupMenuItem(value: 'delete', child: Text('Delete project'))])]),
      const SizedBox(height: 12), Text(project.description.isEmpty ? 'Add a short project description to keep the team in context.' : project.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: VaultColors.muted, height: 1.4)),
      const SizedBox(height: 11), Row(children: [StatusBadge(project.status, compact: true), const SizedBox(width: 7), _PriorityPill(project.priority)]),
      const SizedBox(height: 14), Row(children: [const Expanded(child: Text('PROGRESS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: VaultColors.muted, letterSpacing: .8))), Text('${project.progress}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tint))]), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: project.progress / 100, minHeight: 5, backgroundColor: Theme.of(context).dividerColor, color: tint)),
      const SizedBox(height: 12), Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)), const SizedBox(width: 7), Expanded(child: Text(project.nextAction.isEmpty ? project.currentTask.isEmpty ? 'Add your next action' : project.currentTask : project.nextAction, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)))]),
      const Spacer(), Divider(height: 19, color: Theme.of(context).dividerColor), Row(children: [Icon(Icons.widgets_outlined, size: 12, color: VaultColors.muted), const SizedBox(width: 4), Text('$assetCount assets', style: const TextStyle(fontSize: 8.5, color: VaultColors.muted)), const SizedBox(width: 12), Icon(Icons.checklist_rounded, size: 12, color: VaultColors.muted), const SizedBox(width: 4), Text('$taskCount tasks', style: const TextStyle(fontSize: 8.5, color: VaultColors.muted)), const Spacer(), Icon(Icons.calendar_month_rounded, size: 12, color: VaultColors.muted), const SizedBox(width: 4), Text(project.targetDate.isEmpty ? 'No target' : _shortDate(project.targetDate), style: const TextStyle(fontSize: 8.5, color: VaultColors.muted)), const SizedBox(width: 8), InkWell(onTap: onFocus, borderRadius: BorderRadius.circular(6), child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.hub_rounded, size: 14, color: VaultColors.cyan)))]),
    ]))));
  }
}

class _NewProjectCard extends StatelessWidget {
  const _NewProjectCard({required this.onTap}); final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.025), borderRadius: BorderRadius.circular(17), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.25), style: BorderStyle.solid)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 43, height: 43, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.11), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary, size: 22)), const SizedBox(height: 12), const Text('Start something new', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('Add a project and connect its\ndigital ecosystem.', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: VaultColors.muted, height: 1.5)), const SizedBox(height: 13), Text('Create a project   →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary))])));
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill(this.value); final String value;
  @override
  Widget build(BuildContext context) { final color = switch (value) { 'Urgent' => VaultColors.red, 'High' => VaultColors.amber, 'Medium' => VaultColors.blue, _ => VaultColors.muted }; return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(20)), child: Text('$value priority', style: TextStyle(fontSize: 8.2, color: color, fontWeight: FontWeight.w700))); }
}

class _DetailPair extends StatelessWidget {
  const _DetailPair({required this.label, required this.value, this.warning = false}); final String label; final String value; final bool warning;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 115, child: Text(label, style: const TextStyle(fontSize: 10, color: VaultColors.muted))), Expanded(child: Text(value, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: warning ? VaultColors.amber : null)))]));
}

class _AssetGlyph extends StatelessWidget {
  const _AssetGlyph({required this.type, this.size = 34}); final String type; final double size;
  @override
  Widget build(BuildContext context) { final color = _assetColor(type); return Container(width: size, height: size, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(size * .28)), child: Icon(_assetIcon(type), color: color, size: size * .48)); }
}

IconData _assetIcon(String type) => switch (type) { 'Domain' => Icons.language_rounded, 'GitHub' => Icons.code_rounded, 'Cloudflare' => Icons.cloud_rounded, 'Server' || 'VPS' || 'Hosting' => Icons.dns_rounded, 'Database' => Icons.storage_rounded, 'API' => Icons.api_rounded, 'SaaS' => Icons.apps_rounded, 'Email' => Icons.alternate_email_rounded, 'Social Account' => Icons.people_alt_rounded, 'Payment Gateway' => Icons.payments_outlined, 'Storage' => Icons.folder_open_rounded, 'Device' => Icons.devices_rounded, 'Document' => Icons.description_outlined, _ => Icons.widgets_rounded};
Color _assetColor(String type) => switch (type) { 'Domain' => VaultColors.cyan, 'GitHub' => VaultColors.text, 'Cloudflare' => VaultColors.amber, 'Server' || 'VPS' || 'Hosting' => VaultColors.blue, 'Database' => VaultColors.violet, 'API' => VaultColors.pink, 'Email' => VaultColors.cyan, 'Document' => VaultColors.blue, _ => VaultColors.violet};
String _formatDate(String value) { final date = DateTime.tryParse(value); if (date == null) return 'Not set'; return '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}'; }
String _shortDate(String value) { final date = DateTime.tryParse(value); if (date == null) return 'No target'; return '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]}'; }
extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty ? null : first; }
