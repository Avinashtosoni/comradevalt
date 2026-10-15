import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/common.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _filter = 'All activity';
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final activities = app.data.activities
        .where((item) => '${item.title} ${item.detail}'.toLowerCase().contains(_query.toLowerCase()) && (_filter == 'All activity' || item.kind.toLowerCase() == _filter.toLowerCase()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      final pad = compact ? 16.0 : 28.0;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, compact ? 18 : 27, pad, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(eyebrow: 'WORKSPACE / HISTORY', title: 'Activity', subtitle: 'A clear, privacy-conscious timeline of what changed.', count: activities.length.toString().padLeft(2, '0')),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: VaultColors.green, size: 17),
                      const SizedBox(width: 9),
                      const Expanded(child: Text('Sensitive values are never included in activity history.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                      if (!compact)
                        SizedBox(
                          width: 230,
                          child: TextField(
                            controller: _search,
                            onChanged: (value) => setState(() => _query = value),
                            decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search_rounded, size: 15), hintText: 'Search activity'),
                          ),
                        ),
                    ],
                  ),
                ),
                if (compact)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: _search,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search_rounded, size: 15), hintText: 'Search activity'),
                    ),
                  ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in ['All activity', 'Project', 'Asset', 'Task', 'Note', 'Security', 'Renewal', 'System'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ActivityFilter(label: item, selected: _filter == item, onTap: () => setState(() => _filter = item)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                if (activities.isEmpty)
                  const EmptyState(icon: Icons.timeline_rounded, title: 'No activity to show', description: 'Updates to projects, assets, notes, tasks and renewals will appear here.')
                else
                  _ActivityTimeline(activities: activities),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 13, color: VaultColors.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text('This activity feed is saved with your local workspace. It is not a server-side audit log.', style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ActivityFilter extends StatelessWidget {
  const _ActivityFilter({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          labelStyle: TextStyle(fontSize: 9.5, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.25) : Theme.of(context).dividerColor),
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      );
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.activities});
  final List<ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ActivityItem>>{};
    for (final item in activities) {
      final date = DateTime.tryParse(item.createdAt);
      final key = date == null ? 'Earlier' : _dateLabel(date);
      (grouped[key] ??= []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(left: 3, bottom: 9), child: TinyLabel(entry.key)),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    for (var index = 0; index < entry.value.length; index++)
                      _TimelineRow(item: entry.value[index], isLast: index == entry.value.length - 1),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});
  final ActivityItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tint = _kindColor(item.kind);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: tint.withOpacity(.12), shape: BoxShape.circle),
                child: Icon(_kindIcon(item.kind), size: 13, color: tint),
              ),
              if (!isLast) Container(width: 1, height: 42, color: Theme.of(context).dividerColor),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : BorderSide(color: Theme.of(context).dividerColor.withOpacity(.55)))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                      if (item.detail.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.detail, style: const TextStyle(fontSize: 9, color: VaultColors.muted))),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: tint.withOpacity(.09), borderRadius: BorderRadius.circular(5)),
                            child: Text(item.kind.toUpperCase(), style: TextStyle(color: tint, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: .7)),
                          ),
                          const SizedBox(width: 7),
                          const Text('This device', style: TextStyle(fontSize: 8, color: VaultColors.faint)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(_timeAgo(item.createdAt), style: const TextStyle(fontSize: 8.5, color: VaultColors.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Color _kindColor(String kind) => switch (kind) {
      'security' => VaultColors.amber,
      'task' => VaultColors.cyan,
      'asset' => VaultColors.blue,
      'project' => VaultColors.violet,
      'renewal' => VaultColors.pink,
      _ => VaultColors.green,
    };
IconData _kindIcon(String kind) => switch (kind) {
      'security' => Icons.shield_outlined,
      'task' => Icons.check_circle_outline_rounded,
      'asset' => Icons.link_rounded,
      'project' => Icons.folder_copy_outlined,
      'renewal' => Icons.event_repeat_rounded,
      _ => Icons.cloud_done_outlined,
    };
String _dateLabel(DateTime date) {
  final today = DateUtils.dateOnly(DateTime.now());
  final day = DateUtils.dateOnly(date);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return 'Earlier this week';
  return '${_month(date.month)} ${date.day}, ${date.year}';
}
String _timeAgo(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day} ${_month(date.month)}';
}
String _month(int value) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value - 1];
