import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final data = app.data;
    final active = data.projects.where((item) => !['Archived', 'Paused'].contains(item.status)).length;
    final live = data.projects.where((item) => ['Production', 'Maintenance'].contains(item.status)).length;
    final openTasks = data.tasks.where((item) => item.status != 'Done').length;
    final needsAttention = data.assets.where((item) => item.status == 'Attention' || item.status == 'Offline').length;
    final upcoming = [...data.renewals]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final tasks = data.tasks.where((item) => item.status != 'Done').toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final greeting = DateTime.now().hour < 12 ? 'Good morning' : DateTime.now().hour < 18 ? 'Good afternoon' : 'Good evening';
    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      final pad = mobile ? 16.0 : 28.0;
      return SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, mobile ? 16 : 26, pad, 30), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _WelcomeHero(greeting: greeting, projectCount: data.projects.length, onMap: () => onNavigate(AppSection.mindMap)),
        const SizedBox(height: 16),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: mobile ? 2 : 4, childAspectRatio: mobile ? 1.47 : 1.72, crossAxisSpacing: 11, mainAxisSpacing: 11, children: [
          _StatCard(label: 'Projects', value: data.projects.length, caption: '$active active', icon: Icons.folder_copy_rounded, tint: VaultColors.violet, onTap: () => onNavigate(AppSection.projects), spark: const _MiniSparkline(tint: VaultColors.violet)),
          _StatCard(label: 'Live projects', value: live, caption: 'In production', icon: Icons.trending_up_rounded, tint: VaultColors.cyan, onTap: () => onNavigate(AppSection.projects), spark: const _TrendHint(text: 'On track', icon: Icons.arrow_upward_rounded, tint: VaultColors.green)),
          _StatCard(label: 'Digital assets', value: data.assets.length, caption: needsAttention == 0 ? 'All systems healthy' : '$needsAttention need attention', icon: Icons.widgets_rounded, tint: VaultColors.blue, onTap: () => onNavigate(AppSection.assets), spark: _TrendHint(text: needsAttention == 0 ? 'Healthy' : 'Review', icon: needsAttention == 0 ? Icons.shield_outlined : Icons.warning_amber_rounded, tint: needsAttention == 0 ? VaultColors.green : VaultColors.amber)),
          _StatCard(label: 'Open tasks', value: openTasks, caption: 'Across all projects', icon: Icons.checklist_rounded, tint: VaultColors.amber, onTap: () => onNavigate(AppSection.tasks), spark: const _TrendHint(text: 'This week', icon: Icons.schedule_rounded, tint: VaultColors.muted)),
        ]),
        const SizedBox(height: 15),
        if (mobile) ...[
          _ProjectProgressCard(projects: data.projects, onTap: () => onNavigate(AppSection.projects)), const SizedBox(height: 13),
          _RenewalsCard(renewals: upcoming.take(3).toList(), onTap: () => onNavigate(AppSection.renewals)), const SizedBox(height: 13),
          _TasksCard(tasks: tasks.take(4).toList(), projects: data.projects, onToggle: app.updateTaskStatus, onView: () => onNavigate(AppSection.tasks)), const SizedBox(height: 13),
          _ActivityCard(activities: data.activities.take(4).toList(), onView: () => onNavigate(AppSection.activity)),
        ] else ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 6, child: _ProjectProgressCard(projects: data.projects, onTap: () => onNavigate(AppSection.projects))), const SizedBox(width: 13),
            Expanded(flex: 4, child: _RenewalsCard(renewals: upcoming.take(3).toList(), onTap: () => onNavigate(AppSection.renewals))),
          ]),
          const SizedBox(height: 13),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _TasksCard(tasks: tasks.take(4).toList(), projects: data.projects, onToggle: app.updateTaskStatus, onView: () => onNavigate(AppSection.tasks))), const SizedBox(width: 13),
            Expanded(child: _ActivityCard(activities: data.activities.take(4).toList(), onView: () => onNavigate(AppSection.activity))),
          ]),
        ],
        const SizedBox(height: 13),
        Row(children: [const Icon(Icons.lock_outline_rounded, size: 13, color: VaultColors.muted), const SizedBox(width: 7), Expanded(child: Text('Data stays on this device. Vault secrets are encrypted before they are saved.', style: Theme.of(context).textTheme.bodySmall)), TextButton.icon(onPressed: () => onNavigate(AppSection.settings), icon: const Icon(Icons.arrow_forward_rounded, size: 13), label: const Text('Privacy settings', style: TextStyle(fontSize: 10))),]),
      ]))));
    });
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.greeting, required this.projectCount, required this.onMap});
  final String greeting;
  final int projectCount;
  final VoidCallback onMap;
  @override
  Widget build(BuildContext context) => Container(height: 154, width: double.infinity, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1F1B38), Color(0xFF171A29), Color(0xFF11242A)]), border: Border.all(color: const Color(0xFF38324F))), child: Stack(children: [
    Positioned(right: 80, top: -64, child: _GlowOrb(size: 185, color: VaultColors.violet.withOpacity(.11))),
    Positioned(right: -36, bottom: -96, child: _GlowOrb(size: 230, color: VaultColors.cyan.withOpacity(.1))),
    Positioned(right: 36, top: 0, bottom: 0, child: SizedBox(width: 170, child: CustomPaint(painter: _ConstellationPainter()))),
    Padding(padding: const EdgeInsets.fromLTRB(22, 19, 20, 17), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: VaultColors.cyan, shape: BoxShape.circle)), const SizedBox(width: 7), const Text('YOUR DIGITAL ECOSYSTEM, AT A GLANCE', style: TextStyle(color: Color(0xFFAAB5CC), fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.15))]), const SizedBox(height: 10), Text('$greeting, comrade ✳', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 24)), const SizedBox(height: 5), Text('Everything you run, connected and in view.', style: const TextStyle(color: Color(0xFFAAB2C3), fontSize: 11)), const SizedBox(height: 13), OutlinedButton.icon(onPressed: onMap, icon: const Icon(Icons.hub_rounded, size: 14), label: const Text('Explore your map'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(.22)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))))])), if (projectCount > 0) Container(width: 94, height: 94, margin: const EdgeInsets.only(right: 11), decoration: BoxDecoration(color: Colors.white.withOpacity(.035), border: Border.all(color: Colors.white.withOpacity(.12)), shape: BoxShape.circle), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$projectCount', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)), const Text('PROJECTS', style: TextStyle(color: Color(0xFFAAB2C3), fontSize: 7, letterSpacing: 1.0, fontWeight: FontWeight.w700))]))]))
  ]));
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])));
}

class _ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = Colors.white.withOpacity(.14)..strokeWidth = 1;
    final nodes = [Offset(size.width * .24, size.height * .26), Offset(size.width * .65, size.height * .17), Offset(size.width * .53, size.height * .53), Offset(size.width * .85, size.height * .69), Offset(size.width * .16, size.height * .78)];
    for (final pair in [(0, 1), (0, 2), (2, 1), (2, 3), (2, 4)]) { canvas.drawLine(nodes[pair.$1], nodes[pair.$2], line); }
    for (var i = 0; i < nodes.length; i++) {
      final color = i == 2 ? VaultColors.cyan : VaultColors.violet;
      canvas.drawCircle(nodes[i], i == 2 ? 4 : 3, Paint()..color = color.withOpacity(.85));
      canvas.drawCircle(nodes[i], i == 2 ? 8 : 6, Paint()..color = color.withOpacity(.12));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.caption, required this.icon, required this.tint, required this.onTap, required this.spark});
  final String label;
  final int value;
  final String caption;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final Widget spark;
  @override
  Widget build(BuildContext context) => Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 29, height: 29, decoration: BoxDecoration(color: tint.withOpacity(.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: tint, size: 15)), const Spacer(), spark]),
    const Spacer(), Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
    Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))), Icon(Icons.arrow_outward_rounded, size: 12, color: VaultColors.faint)]),
    const SizedBox(height: 3), Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: tint, fontSize: 9, fontWeight: FontWeight.w600)),
  ]))));
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({required this.tint});
  final Color tint;
  @override
  Widget build(BuildContext context) => SizedBox(width: 47, height: 24, child: CustomPaint(painter: _SparkPainter(tint)));
}
class _SparkPainter extends CustomPainter {
  _SparkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.78, 0.58, 0.68, 0.36, 0.5, 0.27, 0.18];
    final path = Path();
    for (var i = 0; i < values.length; i++) { final point = Offset(size.width * i / (values.length - 1), size.height * values[i]); if (i == 0) path.moveTo(point.dx, point.dy); else path.lineTo(point.dx, point.dy); }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 1.7..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.color != color;
}

class _TrendHint extends StatelessWidget {
  const _TrendHint({required this.text, required this.icon, required this.tint});
  final String text;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: tint), const SizedBox(width: 3), Text(text, style: TextStyle(color: tint, fontSize: 8.5, fontWeight: FontWeight.w700))]);
}

class _ProjectProgressCard extends StatelessWidget {
  const _ProjectProgressCard({required this.projects, required this.onTap});
  final List<ProjectItem> projects;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(17, 16, 14, 14), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const TinyLabel('MOMENTUM'), const SizedBox(height: 6), Text('Project progress', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('Keep the important work moving.', style: Theme.of(context).textTheme.bodySmall)])), IconButton(onPressed: onTap, tooltip: 'View projects', icon: const Icon(Icons.arrow_forward_rounded, size: 17, color: VaultColors.muted))])),
    if (projects.isEmpty) const Padding(padding: EdgeInsets.all(24), child: EmptyState(icon: Icons.folder_copy_outlined, title: 'No projects yet', description: 'Add a project to see your progress here.')),
    ...projects.where((item) => item.status != 'Archived').take(4).map((project) => _ProjectProgressRow(project: project, index: projects.indexOf(project), onTap: onTap)),
    Padding(padding: const EdgeInsets.fromLTRB(17, 10, 17, 13), child: Row(children: [const Icon(Icons.bolt_rounded, size: 13, color: VaultColors.cyan), const SizedBox(width: 6), const Expanded(child: Text('Progress is based on your project check-ins', style: TextStyle(fontSize: 9, color: VaultColors.muted))), TextButton(onPressed: onTap, style: TextButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('All projects', style: TextStyle(fontSize: 10)))])),
  ]));
}

class _ProjectProgressRow extends StatelessWidget {
  const _ProjectProgressRow({required this.project, required this.index, required this.onTap});
  final ProjectItem project;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = [VaultColors.violet, VaultColors.cyan, VaultColors.blue, VaultColors.pink];
    final tint = colors[index % colors.length];
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.fromLTRB(17, 8, 17, 9), child: Row(children: [Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: tint.withOpacity(.14), borderRadius: BorderRadius.circular(10)), child: Text(project.name.split(' ').map((part) => part.isEmpty ? '' : part[0]).take(2).join().toUpperCase(), style: TextStyle(color: tint, fontSize: 9, fontWeight: FontWeight.w800))), const SizedBox(width: 10), Expanded(child: Column(children: [Row(children: [Expanded(child: Text(project.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))), StatusBadge(project.status, compact: true)]), const SizedBox(height: 7), ClipRRect(borderRadius: BorderRadius.circular(7), child: LinearProgressIndicator(value: project.progress / 100, minHeight: 5, backgroundColor: Theme.of(context).dividerColor, color: tint))])), const SizedBox(width: 10), SizedBox(width: 32, child: Text('${project.progress}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))) ])));
  }
}

class _RenewalsCard extends StatelessWidget {
  const _RenewalsCard({required this.renewals, required this.onTap});
  final List<RenewalItem> renewals;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(17, 16, 14, 13), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const TinyLabel('STAY AHEAD'), const SizedBox(height: 6), Text('Upcoming renewals', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('Nothing should catch you by surprise.', style: Theme.of(context).textTheme.bodySmall)])), IconButton(onPressed: onTap, tooltip: 'View renewals', icon: const Icon(Icons.arrow_forward_rounded, size: 17, color: VaultColors.muted))])),
    if (renewals.isEmpty) const Padding(padding: EdgeInsets.all(24), child: EmptyState(icon: Icons.event_available_rounded, title: 'No renewals tracked', description: 'Add a domain or subscription to get ahead of renewals.')),
    ...renewals.map((renewal) => _RenewalRow(renewal: renewal, onTap: onTap)),
    Padding(padding: const EdgeInsets.fromLTRB(17, 9, 17, 13), child: Row(children: [const Icon(Icons.circle, size: 7, color: VaultColors.amber), const SizedBox(width: 6), const Expanded(child: Text('Renewals due in the next few months', style: TextStyle(fontSize: 9, color: VaultColors.muted))), TextButton(onPressed: onTap, style: TextButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('View calendar', style: TextStyle(fontSize: 10)))])),
  ]));
}

class _RenewalRow extends StatelessWidget {
  const _RenewalRow({required this.renewal, required this.onTap});
  final RenewalItem renewal;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final days = _daysUntil(renewal.dueDate);
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: days <= 14 ? VaultColors.amber.withOpacity(.12) : VaultColors.blue.withOpacity(.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.event_repeat_rounded, size: 16, color: days <= 14 ? VaultColors.amber : VaultColors.blue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(renewal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${renewal.provider.isEmpty ? renewal.category : renewal.provider} · ${renewal.amount.isEmpty ? 'Renewal' : renewal.amount}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.8, color: VaultColors.muted))])), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), decoration: BoxDecoration(color: days <= 14 ? VaultColors.amber.withOpacity(.12) : Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(7)), child: Text(days < 0 ? 'Overdue' : days == 0 ? 'Today' : '${days}d', style: TextStyle(color: days <= 14 ? VaultColors.amber : VaultColors.muted, fontSize: 9, fontWeight: FontWeight.w800)))])));
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.tasks, required this.projects, required this.onToggle, required this.onView});
  final List<TaskItem> tasks;
  final List<ProjectItem> projects;
  final void Function(TaskItem task, String status) onToggle;
  final VoidCallback onView;
  @override
  Widget build(BuildContext context) => SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(17, 16, 14, 12), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const TinyLabel('YOUR NEXT MOVES'), const SizedBox(height: 6), Text('Tasks to focus on', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('Small steps make meaningful progress.', style: Theme.of(context).textTheme.bodySmall)])), IconButton(onPressed: onView, tooltip: 'View tasks', icon: const Icon(Icons.arrow_forward_rounded, size: 17, color: VaultColors.muted))])),
    if (tasks.isEmpty) const Padding(padding: EdgeInsets.all(24), child: EmptyState(icon: Icons.check_circle_outline_rounded, title: 'You’re all caught up', description: 'Add a task when something new needs your attention.')),
    ...tasks.map((task) {
      final project = projects.where((item) => item.id == task.projectId).firstOrNull;
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: Row(children: [InkWell(onTap: () => onToggle(task, task.status == 'Done' ? 'Todo' : 'Done'), borderRadius: BorderRadius.circular(20), child: Container(width: 17, height: 17, decoration: BoxDecoration(shape: BoxShape.circle, color: task.status == 'Done' ? VaultColors.green : Colors.transparent, border: Border.all(color: task.status == 'In Progress' ? VaultColors.violet : VaultColors.faint, width: 1.4)), child: task.status == 'Done' ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : task.status == 'In Progress' ? const Icon(Icons.more_horiz_rounded, size: 12, color: VaultColors.violet) : null)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, decoration: task.status == 'Done' ? TextDecoration.lineThrough : null, color: task.status == 'Done' ? VaultColors.muted : null)), const SizedBox(height: 2), Text('${project?.name ?? 'No project'} · ${task.status == 'Blocked' ? 'Blocked' : _friendlyDate(task.dueDate)}', style: TextStyle(color: task.status == 'Blocked' ? VaultColors.amber : VaultColors.muted, fontSize: 8.7))])), Container(width: 6, height: 6, decoration: BoxDecoration(color: _priorityColor(task.priority), shape: BoxShape.circle))]));
    }),
    TextButton.icon(onPressed: onView, icon: const Icon(Icons.add_rounded, size: 14), label: const Text('Open task board', style: TextStyle(fontSize: 10)), style: TextButton.styleFrom(visualDensity: VisualDensity.compact)),
  ]));
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activities, required this.onView});
  final List<ActivityItem> activities;
  final VoidCallback onView;
  @override
  Widget build(BuildContext context) => SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(17, 16, 14, 12), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const TinyLabel('LATEST UPDATES'), const SizedBox(height: 6), Text('Recent activity', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('A little context for what changed.', style: Theme.of(context).textTheme.bodySmall)])), IconButton(onPressed: onView, tooltip: 'View activity', icon: const Icon(Icons.arrow_forward_rounded, size: 17, color: VaultColors.muted))])),
    if (activities.isEmpty) const Padding(padding: EdgeInsets.all(24), child: EmptyState(icon: Icons.timeline_rounded, title: 'No activity yet', description: 'Changes in your workspace will show up here.')),
    ...activities.map((item) => Padding(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7), child: Row(children: [Container(width: 25, height: 25, decoration: BoxDecoration(color: _activityColor(item.kind).withOpacity(.12), shape: BoxShape.circle), child: Icon(_activityIcon(item.kind), size: 12, color: _activityColor(item.kind))), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(item.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))])), Text(_timeAgo(item.createdAt), style: const TextStyle(fontSize: 8, color: VaultColors.faint))]))),
    Padding(padding: const EdgeInsets.only(bottom: 10, top: 3), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shield_outlined, size: 12, color: VaultColors.green), const SizedBox(width: 5), Text('Sensitive values are never logged', style: TextStyle(fontSize: 8.5, color: VaultColors.muted)), const SizedBox(width: 10), TextButton(onPressed: onView, style: TextButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('Timeline', style: TextStyle(fontSize: 9)))])),
  ]));
}

int _daysUntil(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return 99999;
  return DateUtils.dateOnly(date).difference(DateUtils.dateOnly(DateTime.now())).inDays;
}
String _friendlyDate(String value) { final days = _daysUntil(value); if (days == 0) return 'Due today'; if (days == 1) return 'Due tomorrow'; if (days < 0) return 'Overdue'; return 'Due ${_shortDate(value)}'; }
String _shortDate(String value) { final date = DateTime.tryParse(value); return date == null ? 'date not set' : '${date.day} ${_month(date.month)}'; }
String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
String _timeAgo(String value) { final date = DateTime.tryParse(value); if (date == null) return ''; final diff = DateTime.now().difference(date); if (diff.inMinutes < 1) return 'now'; if (diff.inHours < 1) return '${diff.inMinutes}m'; if (diff.inDays < 1) return '${diff.inHours}h'; if (diff.inDays < 7) return '${diff.inDays}d'; return _shortDate(value); }
Color _priorityColor(String priority) => switch (priority) { 'Urgent' => VaultColors.red, 'High' => VaultColors.amber, 'Medium' => VaultColors.blue, _ => VaultColors.muted };
Color _activityColor(String kind) => switch (kind) { 'security' => VaultColors.amber, 'task' => VaultColors.cyan, 'asset' => VaultColors.blue, 'project' => VaultColors.violet, _ => VaultColors.green };
IconData _activityIcon(String kind) => switch (kind) { 'security' => Icons.shield_outlined, 'task' => Icons.check_circle_outline_rounded, 'asset' => Icons.link_rounded, 'project' => Icons.folder_copy_outlined, _ => Icons.cloud_done_outlined };

extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty ? null : first; }
