import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';
import 'editors.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.onNavigate});
  final ValueChanged<AppSection> onNavigate;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _view = 'List';
  String _filter = 'All tasks';
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final data = app.data;
    final filtered = data.tasks.where((task) => '${task.title} ${task.description} ${task.tags.join(' ')}'.toLowerCase().contains(_query.toLowerCase()) && (_filter == 'All tasks' || task.status == _filter)).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final open = data.tasks.where((task) => task.status != 'Done').length;
    final overdue = data.tasks.where((task) => task.status != 'Done' && _daysUntil(task.dueDate) < 0).length;
    final today = data.tasks.where((task) => task.status != 'Done' && _daysUntil(task.dueDate) == 0).length;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final pad = compact ? 16.0 : 28.0;
      return SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, compact ? 18 : 27, pad, 29), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(eyebrow: 'OPERATIONS / TASKS', title: 'Tasks', subtitle: 'Turn good intentions into a clear next action.', count: open.toString().padLeft(2, '0'), actions: compact ? null : Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () => widget.onNavigate(AppSection.projects), icon: const Icon(Icons.folder_copy_outlined, size: 15), label: const Text('Project plans')), PrimaryAction(label: 'New task', onPressed: () => showTaskEditor(context, app))])),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: compact ? 2 : 4, childAspectRatio: compact ? 1.7 : 1.9, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
          _TaskSummary(value: open, label: 'Open tasks', note: 'Across your projects', icon: Icons.checklist_rounded, tint: VaultColors.violet),
          _TaskSummary(value: overdue, label: 'Overdue', note: overdue == 0 ? 'All clear' : 'Needs attention', icon: Icons.warning_amber_rounded, tint: overdue == 0 ? VaultColors.green : VaultColors.amber),
          _TaskSummary(value: today, label: 'Due today', note: today == 0 ? 'Room to focus' : 'On your list', icon: Icons.event_rounded, tint: VaultColors.cyan),
          if (!compact) const _TaskFocusCard(),
        ]),
        if (compact) const Padding(padding: EdgeInsets.only(top: 10), child: _TaskFocusCard()),
        const SizedBox(height: 15),
        _TaskToolbar(view: _view, onView: (value) => setState(() => _view = value), filter: _filter, onFilter: (value) => setState(() => _filter = value), search: _search, query: _query, onQuery: (value) => setState(() => _query = value), onAdd: () => showTaskEditor(context, app), compact: compact),
        const SizedBox(height: 13),
        if (filtered.isEmpty) EmptyState(icon: Icons.checklist_rounded, title: _query.isEmpty ? 'No tasks to show' : 'No matching tasks', description: _query.isEmpty ? 'Create a task to give your projects a clear next step.' : 'Try another search or remove the status filter.', actionLabel: 'Create task', onAction: () => showTaskEditor(context, app))
        else switch (_view) {
          'Kanban' => _KanbanBoard(tasks: filtered, projects: data.projects, onStatus: app.updateTaskStatus, onEdit: (task) => showTaskEditor(context, app, task)),
          'Calendar' => _AgendaView(tasks: filtered, projects: data.projects, onEdit: (task) => showTaskEditor(context, app, task)),
          _ => _TaskList(tasks: filtered, projects: data.projects, onStatus: app.updateTaskStatus, onEdit: (task) => showTaskEditor(context, app, task), onDelete: (task) => _delete(context, app, task)),
        },
      ]))));
    });
  }

  Future<void> _delete(BuildContext context, AppController app, TaskItem task) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete task?'), content: Text('“${task.title}” will be removed from your task list.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))]));
    if (confirmed == true) app.deleteTask(task);
  }
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.value, required this.label, required this.note, required this.icon, required this.tint}); final int value; final String label; final String note; final IconData icon; final Color tint;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(15)), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: tint.withOpacity(.13), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: tint)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: VaultColors.muted))]))]));
}
class _TaskFocusCard extends StatelessWidget { const _TaskFocusCard(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(.12), VaultColors.cyan.withOpacity(.06)]), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.18)), borderRadius: BorderRadius.circular(15)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [const TinyLabel('A SMALL REMINDER'), const SizedBox(height: 5), const Text('Progress over perfection.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('Choose one next step and give it your attention.', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8.5))])), Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 24)])); }

class _TaskToolbar extends StatelessWidget {
  const _TaskToolbar({required this.view, required this.onView, required this.filter, required this.onFilter, required this.search, required this.query, required this.onQuery, required this.onAdd, required this.compact});
  final String view; final ValueChanged<String> onView; final String filter; final ValueChanged<String> onFilter; final TextEditingController search; final String query; final ValueChanged<String> onQuery; final VoidCallback onAdd; final bool compact;
  @override
  Widget build(BuildContext context) {
    final views = ['List', 'Kanban', 'Calendar'];
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(children: views.map((item) => _ViewChip(label: item, selected: view == item, onTap: () => onView(item))).toList()),
            ),
            const Spacer(),
            if (!compact) SizedBox(width: 200, child: _TaskSearch(search: search, query: query, onQuery: onQuery)),
            const SizedBox(width: 9),
            if (!compact) _TaskStatusFilter(filter: filter, onFilter: onFilter),
            if (!compact) const SizedBox(width: 9),
            PrimaryAction(label: 'Add task', onPressed: onAdd, compact: true),
          ],
        ),
        if (compact)
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Row(
              children: [
                Expanded(child: _TaskSearch(search: search, query: query, onQuery: onQuery)),
                const SizedBox(width: 8),
                _TaskStatusFilter(filter: filter, onFilter: onFilter),
              ],
            ),
          ),
      ],
    );
  }
}
class _ViewChip extends StatelessWidget { const _ViewChip({required this.label, required this.selected, required this.onTap}); final String label; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) { final icon = switch (label) { 'List' => Icons.view_list_rounded, 'Kanban' => Icons.view_kanban_rounded, _ => Icons.calendar_month_rounded }; return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.12) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(icon, size: 14, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 9.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted))]))); } }
class _TaskSearch extends StatelessWidget { const _TaskSearch({required this.search, required this.query, required this.onQuery}); final TextEditingController search; final String query; final ValueChanged<String> onQuery; @override Widget build(BuildContext context) => TextField(controller: search, onChanged: onQuery, decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search_rounded, size: 15), hintText: 'Search tasks', suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { search.clear(); onQuery(''); }, icon: const Icon(Icons.close_rounded, size: 14)))); }
class _TaskStatusFilter extends StatelessWidget { const _TaskStatusFilter({required this.filter, required this.onFilter}); final String filter; final ValueChanged<String> onFilter; @override Widget build(BuildContext context) => SizedBox(width: 130, child: DropdownButtonFormField<String>(value: filter, isDense: true, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 9, vertical: 11)), items: ['All tasks', 'Todo', 'In Progress', 'Blocked', 'Done'].map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (value) { if (value != null) onFilter(value); })); }

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.projects, required this.onStatus, required this.onEdit, required this.onDelete}); final List<TaskItem> tasks; final List<ProjectItem> projects; final void Function(TaskItem, String) onStatus; final ValueChanged<TaskItem> onEdit; final ValueChanged<TaskItem> onDelete;
  @override Widget build(BuildContext context) => Container(clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(children: [
    Container(height: 37, padding: const EdgeInsets.symmetric(horizontal: 15), color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B1E29) : const Color(0xFFF7F8FB), child: const Row(children: [Expanded(flex: 4, child: _TableHead('TASK')), Expanded(flex: 2, child: _TableHead('PROJECT')), Expanded(flex: 1, child: _TableHead('PRIORITY')), Expanded(flex: 1, child: _TableHead('DUE DATE')), SizedBox(width: 112, child: _TableHead('STATUS')), SizedBox(width: 31)])),
    ...tasks.map((task) => _TaskRow(task: task, project: projects.where((project) => project.id == task.projectId).firstOrNull, onStatus: (status) => onStatus(task, status), onEdit: () => onEdit(task), onDelete: () => onDelete(task))),
  ]));
}
class _TableHead extends StatelessWidget { const _TableHead(this.value); final String value; @override Widget build(BuildContext context) => Text(value, style: const TextStyle(fontSize: 7.5, letterSpacing: .9, fontWeight: FontWeight.w800, color: VaultColors.faint)); }
class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.project, required this.onStatus, required this.onEdit, required this.onDelete}); final TaskItem task; final ProjectItem? project; final ValueChanged<String> onStatus; final VoidCallback onEdit; final VoidCallback onDelete;
  @override Widget build(BuildContext context) { final overdue = task.status != 'Done' && _daysUntil(task.dueDate) < 0; return InkWell(onTap: onEdit, child: Container(height: 62, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.65)))), child: Row(children: [
    Expanded(flex: 4, child: Row(children: [InkWell(onTap: () => onStatus(task.status == 'Done' ? 'Todo' : 'Done'), borderRadius: BorderRadius.circular(20), child: Container(width: 17, height: 17, decoration: BoxDecoration(shape: BoxShape.circle, color: task.status == 'Done' ? VaultColors.green : Colors.transparent, border: Border.all(color: task.status == 'In Progress' ? VaultColors.violet : VaultColors.faint, width: 1.3)), child: task.status == 'Done' ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : task.status == 'In Progress' ? const Icon(Icons.more_horiz_rounded, size: 11, color: VaultColors.violet) : null)), const SizedBox(width: 9), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, decoration: task.status == 'Done' ? TextDecoration.lineThrough : null, color: task.status == 'Done' ? VaultColors.muted : null)), const SizedBox(height: 3), Text(task.description.isEmpty ? task.tags.map((tag) => '#$tag').join('  ') : task.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.3, color: VaultColors.muted))]))])),
    Expanded(flex: 2, child: Text(project?.name ?? 'Unassigned', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: VaultColors.muted))),
    Expanded(flex: 1, child: Row(children: [Container(width: 5, height: 5, decoration: BoxDecoration(color: _priorityColor(task.priority), shape: BoxShape.circle)), const SizedBox(width: 5), Flexible(child: Text(task.priority, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted), overflow: TextOverflow.ellipsis))])),
    Expanded(flex: 1, child: Text(_shortDate(task.dueDate), style: TextStyle(fontSize: 8.5, color: overdue ? VaultColors.red : VaultColors.muted, fontWeight: overdue ? FontWeight.w700 : FontWeight.w500))),
    SizedBox(width: 112, child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: task.status, isDense: true, isExpanded: true, borderRadius: BorderRadius.circular(12), items: ['Todo', 'In Progress', 'Blocked', 'Done'].map((status) => DropdownMenuItem(value: status, child: StatusBadge(status, compact: true))).toList(), onChanged: (value) { if (value != null) onStatus(value); }))),
    SizedBox(width: 31, child: PopupMenuButton<String>(padding: EdgeInsets.zero, iconSize: 16, icon: const Icon(Icons.more_horiz_rounded, color: VaultColors.muted), onSelected: (value) => value == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit task')), PopupMenuItem(value: 'delete', child: Text('Delete task'))])),
  ]))); }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({required this.tasks, required this.projects, required this.onStatus, required this.onEdit});
  final List<TaskItem> tasks;
  final List<ProjectItem> projects;
  final void Function(TaskItem, String) onStatus;
  final ValueChanged<TaskItem> onEdit;

  @override
  Widget build(BuildContext context) {
    const statuses = ['Todo', 'In Progress', 'Blocked', 'Done'];
    final columns = statuses.map((status) {
      final group = tasks.where((task) => task.status == status).toList();
      return Container(
        width: 248,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF12151E) : const Color(0xFFEDF0F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor(status), shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Text(status, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                CountTag(group.length, color: statusColor(status)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add task in $status',
                  onPressed: () => showTaskEditor(context, context.read<AppController>(), null, status),
                  icon: const Icon(Icons.add_rounded, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (group.isEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 7),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(11)),
                child: Text('No ${status.toLowerCase()} tasks', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: VaultColors.faint)),
              ),
            ...group.map((task) => _KanbanCard(
                  task: task,
                  project: projects.where((item) => item.id == task.projectId).firstOrNull,
                  onTap: () => onEdit(task),
                  onStatus: (value) => onStatus(task, value),
                )),
          ],
        ),
      );
    }).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns),
    );
  }
}

class _KanbanCard extends StatelessWidget { const _KanbanCard({required this.task, required this.project, required this.onTap, required this.onStatus}); final TaskItem task; final ProjectItem? project; final VoidCallback onTap; final ValueChanged<String> onStatus; @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: _priorityColor(task.priority), shape: BoxShape.circle)), const SizedBox(width: 5), Text(task.priority.toUpperCase(), style: const TextStyle(fontSize: 7.5, color: VaultColors.muted, fontWeight: FontWeight.w800, letterSpacing: .7)), const Spacer(), IconButton(visualDensity: VisualDensity.compact, onPressed: onTap, icon: const Icon(Icons.edit_outlined, size: 13, color: VaultColors.muted))]), InkWell(onTap: onTap, child: Text(task.title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800))), if (task.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))), const SizedBox(height: 9), Row(children: [Expanded(child: Text(project?.name ?? 'No project', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))), Text(_shortDate(task.dueDate), style: TextStyle(fontSize: 8.2, color: _daysUntil(task.dueDate) < 0 && task.status != 'Done' ? VaultColors.red : VaultColors.muted))]), const SizedBox(height: 8), DropdownButtonHideUnderline(child: DropdownButton<String>(value: task.status, isDense: true, isExpanded: true, items: ['Todo', 'In Progress', 'Blocked', 'Done'].map((value) => DropdownMenuItem(value: value, child: Text('Move to $value', style: const TextStyle(fontSize: 9)))).toList(), onChanged: (value) { if (value != null) onStatus(value); }))])); }

class _AgendaView extends StatelessWidget {
  const _AgendaView({required this.tasks, required this.projects, required this.onEdit}); final List<TaskItem> tasks; final List<ProjectItem> projects; final ValueChanged<TaskItem> onEdit;
  @override Widget build(BuildContext context) { final grouped = <String, List<TaskItem>>{}; for (final task in tasks) { (grouped[task.dueDate] ??= []).add(task); } final dates = grouped.keys.toList()..sort(); return SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [Padding(padding: const EdgeInsets.all(17), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const TinyLabel('UPCOMING WORK'), const SizedBox(height: 5), Text('Task calendar', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('Tasks grouped by due date.', style: Theme.of(context).textTheme.bodySmall)])), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(9)), child: Row(children: [const Icon(Icons.calendar_month_rounded, size: 14, color: VaultColors.cyan), const SizedBox(width: 6), Text('${_month(DateTime.now().month)} ${DateTime.now().year}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700))]))])), const Divider(height: 1), ...dates.map((date) { final due = DateTime.tryParse(date) ?? DateTime.now(); final days = _daysUntil(date); final label = days == 0 ? 'Today' : days == 1 ? 'Tomorrow' : days < 0 ? '${-days} days overdue' : '${_weekday(due.weekday)}, ${due.day} ${_month(due.month)}'; return Padding(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(due.day.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: TextStyle(fontSize: 8.5, color: days < 0 ? VaultColors.red : VaultColors.muted, fontWeight: FontWeight.w600))])), Expanded(child: Column(children: grouped[date]!.map((task) => InkWell(onTap: () => onEdit(task), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: _priorityColor(task.priority), shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${projects.where((item) => item.id == task.projectId).firstOrNull?.name ?? 'No project'} · ${task.status}', style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))])), const Icon(Icons.arrow_forward_rounded, size: 13, color: VaultColors.faint)])))).toList()))])); })])); }
}

int _daysUntil(String value) { final date = DateTime.tryParse(value); if (date == null) return 99999; return DateUtils.dateOnly(date).difference(DateUtils.dateOnly(DateTime.now())).inDays; }
String _shortDate(String value) { final date = DateTime.tryParse(value); return date == null ? '—' : '${date.day} ${_month(date.month)}'; }
String _month(int value) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value - 1];
String _weekday(int value) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value - 1];
Color _priorityColor(String value) => switch (value) { 'Urgent' => VaultColors.red, 'High' => VaultColors.amber, 'Medium' => VaultColors.blue, _ => VaultColors.muted };
extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty ? null : first; }
