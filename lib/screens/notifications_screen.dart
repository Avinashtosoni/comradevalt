import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.onNavigate});
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final data = app.data;
    final notifications = <_LocalNotification>[];

    for (final task in data.tasks.where((item) => item.status != 'Done' && _daysUntil(item.dueDate) <= 2)) {
      final days = _daysUntil(task.dueDate);
      notifications.add(_LocalNotification(
        id: 'task:${task.id}',
        title: days < 0 ? 'Task overdue' : days == 0 ? 'Task due today' : 'Task due soon',
        body: '${task.title}${_projectSuffix(task.projectId, data.projects)}',
        kind: 'task',
        time: task.dueDate,
        section: AppSection.tasks,
      ));
    }
    for (final renewal in data.renewals.where((item) => _daysUntil(item.dueDate) < 0 || item.reminders.any((reminder) => _daysUntil(item.dueDate) <= reminder))) {
      final days = _daysUntil(renewal.dueDate);
      notifications.add(_LocalNotification(
        id: 'renewal:${renewal.id}',
        title: days < 0 ? 'Renewal overdue' : 'Renewal coming up',
        body: '${renewal.title} · ${days < 0 ? '${-days} days overdue' : 'in $days days'}',
        kind: 'renewal',
        time: renewal.dueDate,
        section: AppSection.renewals,
      ));
    }
    for (final asset in data.assets.where((item) => item.status == 'Attention' || item.status == 'Offline')) {
      notifications.add(_LocalNotification(
        id: 'asset:${asset.id}',
        title: asset.status == 'Offline' ? 'Asset offline' : 'Asset needs attention',
        body: '${asset.name} · ${asset.summary}',
        kind: 'security',
        time: asset.updatedAt,
        section: AppSection.assets,
      ));
    }
    notifications.sort((a, b) => _sortTime(a.time).compareTo(_sortTime(b.time)));
    final unread = notifications.where((item) => !data.notificationsRead.contains(item.id)).length;

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      final pad = compact ? 16.0 : 28.0;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, compact ? 18 : 27, pad, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  eyebrow: 'UPDATES',
                  title: 'Notifications',
                  subtitle: 'Renewals, tasks and assets that could use your attention.',
                  count: unread.toString().padLeft(2, '0'),
                  actions: unread == 0
                      ? null
                      : TextButton.icon(
                          onPressed: () => app.markNotificationsRead(notifications.map((item) => item.id)),
                          icon: const Icon(Icons.done_all_rounded, size: 15),
                          label: const Text('Mark all read'),
                        ),
                ),
                if (notifications.isEmpty)
                  const EmptyState(icon: Icons.notifications_none_rounded, title: 'You’re all caught up', description: 'When a task, renewal or asset needs attention, you’ll see it here.')
                else
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Column(
                      children: [
                        for (final item in notifications) _NotificationRow(
                          item: item,
                          read: data.notificationsRead.contains(item.id),
                          onTap: () {
                            app.markNotificationsRead([item.id]);
                            onNavigate(item.section);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(13)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 15, color: VaultColors.muted),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('These are local in-app reminders. Push, email and device alerts are not enabled without a notification backend.', style: TextStyle(fontSize: 9.3, color: VaultColors.muted, height: 1.4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.read, required this.onTap});
  final _LocalNotification item;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = item.kind == 'security' ? VaultColors.amber : item.kind == 'renewal' ? VaultColors.pink : VaultColors.cyan;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: read ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(.035),
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.55))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(color: tint.withOpacity(.11), borderRadius: BorderRadius.circular(11)),
              child: Icon(_notificationIcon(item.kind), size: 17, color: tint),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: TextStyle(fontSize: 10.5, fontWeight: read ? FontWeight.w600 : FontWeight.w800))),
                      if (!read) Container(width: 6, height: 6, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: VaultColors.muted)),
                  const SizedBox(height: 5),
                  Text(_when(item.time), style: const TextStyle(fontSize: 8, color: VaultColors.faint)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: VaultColors.faint),
          ],
        ),
      ),
    );
  }
}

class _LocalNotification {
  const _LocalNotification({required this.id, required this.title, required this.body, required this.kind, required this.time, required this.section});
  final String id;
  final String title;
  final String body;
  final String kind;
  final String time;
  final AppSection section;
}

IconData _notificationIcon(String kind) => switch (kind) {
      'security' => Icons.shield_outlined,
      'renewal' => Icons.event_repeat_rounded,
      _ => Icons.checklist_rounded,
    };
String _projectSuffix(String? projectId, List<ProjectItem> projects) {
  final project = projects.where((item) => item.id == projectId).firstOrNull;
  return project == null ? '' : ' · ${project.name}';
}
int _daysUntil(String value) {
  final date = DateTime.tryParse(value);
  return date == null ? 99999 : DateUtils.dateOnly(date).difference(DateUtils.dateOnly(DateTime.now())).inDays;
}
DateTime _sortTime(String value) => DateTime.tryParse(value) ?? DateTime(9999);
String _when(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return '';
  final days = DateUtils.dateOnly(date).difference(DateUtils.dateOnly(DateTime.now())).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days < 0) return '${-days} days overdue';
  return 'In $days days';
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
