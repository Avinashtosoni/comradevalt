import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';
import 'editors.dart';

class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key, required this.onNavigate});
  final ValueChanged<AppSection> onNavigate;
  @override
  State<RenewalsScreen> createState() => _RenewalsScreenState();
}

class _RenewalsScreenState extends State<RenewalsScreen> {
  String _filter = 'All';
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final items = app.data.renewals.where((item) {
      final days = _daysUntil(item.dueDate);
      final queryMatch = '${item.title} ${item.provider} ${item.category}'.toLowerCase().contains(_query.toLowerCase());
      final filterMatch = _filter == 'All' || (_filter == 'Next 30 days' && days >= 0 && days <= 30) || (_filter == 'Overdue' && days < 0) || (_filter == 'Auto-renew off' && !item.autoRenew);
      return queryMatch && filterMatch;
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final due30 = app.data.renewals.where((item) => _daysUntil(item.dueDate) >= 0 && _daysUntil(item.dueDate) <= 30).length;
    final overdue = app.data.renewals.where((item) => _daysUntil(item.dueDate) < 0).length;
    final autoOff = app.data.renewals.where((item) => !item.autoRenew).length;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
      final pad = compact ? 16.0 : 28.0;
      return SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, compact ? 18 : 27, pad, 30), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1370), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(eyebrow: 'OPERATIONS / RENEWALS', title: 'Renewals', subtitle: 'Stay ahead of domains, hosting, subscriptions and licenses.', count: app.data.renewals.length.toString().padLeft(2, '0'), actions: compact ? null : Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () => widget.onNavigate(AppSection.notifications), icon: const Icon(Icons.notifications_none_rounded, size: 15), label: const Text('Notifications')), PrimaryAction(label: 'Track renewal', onPressed: () => showRenewalEditor(context, app))])),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: compact ? 2 : 3, childAspectRatio: compact ? 1.7 : 2.15, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
          _RenewalStat(value: due30, label: 'Due in 30 days', caption: due30 == 0 ? 'Nothing on the horizon' : 'Plan ahead now', icon: Icons.calendar_month_rounded, tint: VaultColors.cyan),
          _RenewalStat(value: overdue, label: 'Overdue', caption: overdue == 0 ? 'All caught up' : 'Review these today', icon: Icons.warning_amber_rounded, tint: overdue == 0 ? VaultColors.green : VaultColors.red),
          _RenewalStat(value: autoOff, label: 'Auto-renew off', caption: 'Needs a manual decision', icon: Icons.autorenew_rounded, tint: VaultColors.amber),
        ]),
        const SizedBox(height: 17),
        Row(children: [
          Expanded(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final value in ['All', 'Next 30 days', 'Overdue', 'Auto-renew off'])
                Padding(padding: const EdgeInsets.only(right: 6), child: _RenewalFilter(
                  label: value,
                  selected: _filter == value,
                  count: value == 'All' ? app.data.renewals.length : null,
                  onTap: () => setState(() => _filter = value),
                )),
            ]),
          )),
          if (!compact) const SizedBox(width: 12),
          if (!compact) SizedBox(width: 220, child: _SearchField(controller: _search, query: _query, onChanged: (value) => setState(() => _query = value))),
        ]),
        if (compact) Padding(padding: const EdgeInsets.only(top: 10), child: _SearchField(controller: _search, query: _query, onChanged: (value) => setState(() => _query = value))),
        const SizedBox(height: 13),
        if (items.isEmpty)
          EmptyState(
            icon: Icons.event_available_rounded,
            title: _query.isEmpty ? 'No renewals to show' : 'No matching renewals',
            description: _query.isEmpty ? 'Track a domain, SaaS plan or server so the next date never sneaks up.' : 'Try another search or clear your filters.',
            actionLabel: 'Track a renewal',
            onAction: () => showRenewalEditor(context, app),
          )
        else if (compact)
          Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _RenewalCard(
                item: item,
                project: app.data.projects.where((project) => project.id == item.projectId).firstOrNull,
                onEdit: () => showRenewalEditor(context, app, item),
                onDelete: () => _delete(context, app, item),
              ),
            )).toList(),
          )
        else
          _RenewalTable(
            items: items,
            projects: app.data.projects,
            onEdit: (item) => showRenewalEditor(context, app, item),
            onDelete: (item) => _delete(context, app, item),
          ),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.055), borderRadius: BorderRadius.circular(13), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.14))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 9), const Expanded(child: Text('Reminders are stored with your local workspace. System notifications and email reminders need a connected notification service, which is not configured in this local build.', style: TextStyle(fontSize: 9.5, color: VaultColors.muted, height: 1.45)))])),
      ]))));
    });
  }
  Future<void> _delete(BuildContext context, AppController app, RenewalItem item) async { final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Remove renewal?'), content: Text('“${item.title}” will be removed from your reminder list.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove'))])); if (confirmed == true) app.deleteRenewal(item); }
}

class _RenewalStat extends StatelessWidget { const _RenewalStat({required this.value, required this.label, required this.caption, required this.icon, required this.tint}); final int value; final String label; final String caption; final IconData icon; final Color tint; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(15)), child: Row(children: [Container(width: 33, height: 33, decoration: BoxDecoration(color: tint.withOpacity(.13), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: tint, size: 16)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.4, color: VaultColors.muted))]))])); }
class _RenewalFilter extends StatelessWidget { const _RenewalFilter({required this.label, required this.selected, required this.onTap, this.count}); final String label; final bool selected; final VoidCallback onTap; final int? count; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label), if (count != null) ...[const SizedBox(width: 5), Text('$count', style: const TextStyle(fontSize: 9, color: VaultColors.muted, fontWeight: FontWeight.w800))]]), selected: selected, onSelected: (_) => onTap(), visualDensity: VisualDensity.compact, labelStyle: TextStyle(fontSize: 9.5, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted, fontWeight: selected ? FontWeight.w700 : FontWeight.w500), side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.28) : Theme.of(context).dividerColor), backgroundColor: Theme.of(context).colorScheme.surface, selectedColor: Theme.of(context).colorScheme.primary.withOpacity(.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)))); }
class _SearchField extends StatelessWidget { const _SearchField({required this.controller, required this.query, required this.onChanged}); final TextEditingController controller; final String query; final ValueChanged<String> onChanged; @override Widget build(BuildContext context) => TextField(controller: controller, onChanged: onChanged, decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search_rounded, size: 16), hintText: 'Search renewals', suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { controller.clear(); onChanged(''); }, icon: const Icon(Icons.close_rounded, size: 14)))); }

class _RenewalTable extends StatelessWidget { const _RenewalTable({required this.items, required this.projects, required this.onEdit, required this.onDelete}); final List<RenewalItem> items; final List<ProjectItem> projects; final ValueChanged<RenewalItem> onEdit; final ValueChanged<RenewalItem> onDelete; @override Widget build(BuildContext context) => Container(clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(15)), child: Column(children: [Container(height: 38, padding: const EdgeInsets.symmetric(horizontal: 16), color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B1E29) : const Color(0xFFF7F8FB), child: const Row(children: [Expanded(flex: 4, child: _TableLabel('RENEWAL')), Expanded(flex: 2, child: _TableLabel('CATEGORY')), Expanded(flex: 2, child: _TableLabel('PROJECT')), Expanded(flex: 2, child: _TableLabel('RENEWAL DATE')), Expanded(flex: 2, child: _TableLabel('AUTO-RENEW')), SizedBox(width: 45)])), ...items.map((item) => _RenewalRow(item: item, project: projects.where((project) => project.id == item.projectId).firstOrNull, onEdit: () => onEdit(item), onDelete: () => onDelete(item)))])); }
class _TableLabel extends StatelessWidget { const _TableLabel(this.value); final String value; @override Widget build(BuildContext context) => Text(value, style: const TextStyle(color: VaultColors.faint, fontSize: 7.5, letterSpacing: .9, fontWeight: FontWeight.w800)); }
class _RenewalRow extends StatelessWidget { const _RenewalRow({required this.item, required this.project, required this.onEdit, required this.onDelete}); final RenewalItem item; final ProjectItem? project; final VoidCallback onEdit; final VoidCallback onDelete; @override Widget build(BuildContext context) { final days = _daysUntil(item.dueDate); final tint = days < 0 ? VaultColors.red : days <= 14 ? VaultColors.amber : VaultColors.green; return InkWell(onTap: onEdit, child: Container(height: 66, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.65)))), child: Row(children: [Expanded(flex: 4, child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: tint.withOpacity(.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.event_repeat_rounded, size: 16, color: tint)), const SizedBox(width: 9), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${item.provider.isEmpty ? item.category : item.provider}${item.amount.isEmpty ? '' : ' · ${item.amount}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))]))])), Expanded(flex: 2, child: Text(item.category, style: const TextStyle(fontSize: 9, color: VaultColors.muted))), Expanded(flex: 2, child: Text(project?.name ?? 'Unlinked', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: VaultColors.muted))), Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_formatDate(item.dueDate), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(days < 0 ? '${-days} days overdue' : days == 0 ? 'Due today' : 'In $days days', style: TextStyle(color: tint, fontSize: 8.2, fontWeight: FontWeight.w600))])), Expanded(flex: 2, child: Row(children: [Icon(item.autoRenew ? Icons.autorenew_rounded : Icons.touch_app_rounded, size: 14, color: item.autoRenew ? VaultColors.green : VaultColors.amber), const SizedBox(width: 5), Text(item.autoRenew ? 'On' : 'Manual', style: TextStyle(fontSize: 9, color: item.autoRenew ? VaultColors.green : VaultColors.amber, fontWeight: FontWeight.w600))])), SizedBox(width: 45, child: PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded, size: 17, color: VaultColors.muted), onSelected: (value) => value == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit renewal')), PopupMenuItem(value: 'remove', child: Text('Remove renewal'))]))]))); } }
class _RenewalCard extends StatelessWidget { const _RenewalCard({required this.item, required this.project, required this.onEdit, required this.onDelete}); final RenewalItem item; final ProjectItem? project; final VoidCallback onEdit; final VoidCallback onDelete; @override Widget build(BuildContext context) { final days = _daysUntil(item.dueDate); final tint = days < 0 ? VaultColors.red : days <= 14 ? VaultColors.amber : VaultColors.green; return Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(15), child: InkWell(onTap: onEdit, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: tint.withOpacity(.12), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.event_repeat_rounded, size: 18, color: tint)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), Text(days < 0 ? 'Overdue' : days == 0 ? 'Today' : '${days}d', style: TextStyle(fontSize: 9, color: tint, fontWeight: FontWeight.w800))]), const SizedBox(height: 4), Text('${item.provider.isEmpty ? item.category : item.provider} · ${project?.name ?? 'Unlinked'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.8, color: VaultColors.muted)), const SizedBox(height: 6), Row(children: [Text(_formatDate(item.dueDate), style: const TextStyle(fontSize: 8.7, fontWeight: FontWeight.w700)), const SizedBox(width: 9), Icon(item.autoRenew ? Icons.autorenew_rounded : Icons.touch_app_rounded, size: 12, color: item.autoRenew ? VaultColors.green : VaultColors.amber), const SizedBox(width: 3), Text(item.autoRenew ? 'Auto-renew on' : 'Manual renewal', style: TextStyle(fontSize: 8, color: item.autoRenew ? VaultColors.green : VaultColors.amber))])])), PopupMenuButton<String>(icon: const Icon(Icons.more_vert_rounded, size: 17, color: VaultColors.muted), onSelected: (value) => value == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit renewal')), PopupMenuItem(value: 'remove', child: Text('Remove renewal'))])])))); } }

int _daysUntil(String value) { final date = DateTime.tryParse(value); if (date == null) return 99999; return DateUtils.dateOnly(date).difference(DateUtils.dateOnly(DateTime.now())).inDays; }
String _formatDate(String value) { final date = DateTime.tryParse(value); if (date == null) return 'Date not set'; return '${date.day} ${_month(date.month)} ${date.year}'; }
String _month(int value) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value - 1];
extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty ? null : first; }
