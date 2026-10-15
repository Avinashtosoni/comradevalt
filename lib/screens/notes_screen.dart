import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';
import 'editors.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.onNavigate});
  final ValueChanged<AppSection> onNavigate;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _tagFilter;
  bool _pinnedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final notes = [...app.data.notes];
    notes.sort((a, b) {
      final pinOrder = (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0);
      return pinOrder == 0 ? b.updatedAt.compareTo(a.updatedAt) : pinOrder;
    });
    final tags = notes.expand((note) => note.tags).toSet().toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final filtered = notes.where((note) {
      final matchesQuery = '${note.title} ${note.body} ${note.tags.join(' ')}'.toLowerCase().contains(_query.trim().toLowerCase());
      final matchesTag = _tagFilter == null || note.tags.any((tag) => tag.toLowerCase() == _tagFilter!.toLowerCase());
      return matchesQuery && matchesTag && (!_pinnedOnly || note.pinned);
    }).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      final horizontalPadding = compact ? 16.0 : 28.0;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontalPadding, compact ? 18 : 27, horizontalPadding, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  eyebrow: 'WORKSPACE / KNOWLEDGE',
                  title: 'Notes',
                  subtitle: 'Keep decisions, ideas and useful context close to your work.',
                  count: notes.length.toString().padLeft(2, '0'),
                  actions: compact ? null : PrimaryAction(label: 'New note', icon: Icons.add_rounded, onPressed: () => showNoteEditor(context, app)),
                ),
                if (compact) ...[
                  Align(alignment: Alignment.centerRight, child: PrimaryAction(label: 'New note', icon: Icons.add_rounded, compact: true, onPressed: () => showNoteEditor(context, app))),
                  const SizedBox(height: 14),
                ],
                _PrivacyNotice(onOpenVault: () => widget.onNavigate(AppSection.vault)),
                const SizedBox(height: 17),
                _NoteSummary(total: notes.length, pinned: notes.where((note) => note.pinned).length, tagCount: tags.length),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                    hintText: 'Search note titles, text and tags…',
                    suffixIcon: _query.isEmpty ? null : IconButton(tooltip: 'Clear search', onPressed: () { _searchController.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded, size: 17)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 11),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All notes', selected: !_pinnedOnly && _tagFilter == null, onTap: () => setState(() { _pinnedOnly = false; _tagFilter = null; })),
                      const SizedBox(width: 7),
                      _FilterChip(label: 'Pinned', icon: Icons.push_pin_rounded, selected: _pinnedOnly, onTap: () => setState(() { _pinnedOnly = !_pinnedOnly; _tagFilter = null; })),
                      ...tags.map((tag) => Padding(
                            padding: const EdgeInsets.only(left: 7),
                            child: _FilterChip(label: '#$tag', selected: _tagFilter?.toLowerCase() == tag.toLowerCase(), onTap: () => setState(() { _tagFilter = _tagFilter?.toLowerCase() == tag.toLowerCase() ? null : tag; _pinnedOnly = false; })),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                if (filtered.isEmpty)
                  EmptyState(
                    icon: notes.isEmpty ? Icons.sticky_note_2_outlined : Icons.manage_search_rounded,
                    title: notes.isEmpty ? 'Your notes start here' : 'No matching notes',
                    description: notes.isEmpty ? 'Capture a decision, idea or bit of context. You can search and tag notes as they grow.' : 'Try a different search or clear the selected filters.',
                    actionLabel: notes.isEmpty ? 'Create a note' : null,
                    onAction: notes.isEmpty ? () => showNoteEditor(context, app) : null,
                  )
                else
                  LayoutBuilder(builder: (context, gridConstraints) {
                    final width = gridConstraints.maxWidth;
                    final columns = width >= 1050 ? 3 : width >= 620 ? 2 : 1;
                    final gap = 12.0;
                    final cardWidth = (width - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: filtered.map((note) => SizedBox(
                        width: cardWidth,
                        child: _NoteCard(
                          note: note,
                          onOpen: () => showNoteEditor(context, app, note),
                          onTogglePin: () => app.saveNote(note.copyWith(pinned: !note.pinned)),
                          onEdit: () => showNoteEditor(context, app, note),
                          onDelete: () => _confirmDelete(context, app, note),
                        ),
                      )).toList(),
                    );
                  }),
                const SizedBox(height: 17),
                Text('${filtered.length} ${filtered.length == 1 ? 'note' : 'notes'} shown', style: TextStyle(color: VaultColors.muted.withOpacity(.9), fontSize: 10)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _confirmDelete(BuildContext context, AppController app, NoteItem note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this note?'),
        content: Text('“${note.title}” will be removed from this workspace. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) app.deleteNote(note);
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.onOpenVault});
  final VoidCallback onOpenVault;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(color: VaultColors.amber.withOpacity(.055), borderRadius: BorderRadius.circular(12), border: Border.all(color: VaultColors.amber.withOpacity(.15))),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 15, color: VaultColors.amber),
            const SizedBox(width: 8),
            const Expanded(child: Text('Notes are regular workspace data and are not encrypted. Store secrets in Vault instead.', style: TextStyle(fontSize: 9.5, color: VaultColors.muted))),
            TextButton(onPressed: onOpenVault, style: TextButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('Vault', style: TextStyle(fontSize: 10))),
          ],
        ),
      );
}

class _NoteSummary extends StatelessWidget {
  const _NoteSummary({required this.total, required this.pinned, required this.tagCount});
  final int total;
  final int pinned;
  final int tagCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Wrap(
          spacing: 25,
          runSpacing: 10,
          children: [
            _SummaryMetric(icon: Icons.sticky_note_2_outlined, color: VaultColors.violet, value: total, label: 'Notes'),
            _SummaryMetric(icon: Icons.push_pin_outlined, color: VaultColors.amber, value: pinned, label: 'Pinned'),
            _SummaryMetric(icon: Icons.sell_outlined, color: VaultColors.cyan, value: tagCount, label: 'Tags'),
          ],
        ),
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text('$value', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 9.5, color: VaultColors.muted)),
        ],
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 13),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onOpen, required this.onTogglePin, required this.onEdit, required this.onDelete});
  final NoteItem note;
  final VoidCallback onOpen;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = note.body.trim().replaceAll(RegExp(r'\s+'), ' ');
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, height: 1.35))),
                  IconButton(tooltip: note.pinned ? 'Unpin note' : 'Pin note', visualDensity: VisualDensity.compact, onPressed: onTogglePin, icon: Icon(note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, size: 16, color: note.pinned ? VaultColors.amber : VaultColors.muted)),
                  PopupMenuButton<String>(
                    tooltip: 'Note actions',
                    padding: EdgeInsets.zero,
                    iconSize: 17,
                    onSelected: (value) { if (value == 'edit') onEdit(); if (value == 'delete') onDelete(); },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit note')),
                      PopupMenuItem(value: 'delete', child: Text('Delete note')),
                    ],
                  ),
                ],
              ),
              Text(text.isEmpty ? 'No text yet' : text, maxLines: 5, overflow: TextOverflow.ellipsis, style: TextStyle(color: text.isEmpty ? VaultColors.muted : Theme.of(context).textTheme.bodySmall?.color, fontSize: 10.5, height: 1.6)),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 5, runSpacing: 5, children: note.tags.take(5).map((tag) => TagChip(tag)).toList()),
              ],
              const SizedBox(height: 11),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: VaultColors.muted.withOpacity(.9)),
                  const SizedBox(width: 5),
                  Expanded(child: Text('Updated ${_formatUpdated(note.updatedAt)}', style: const TextStyle(fontSize: 9, color: VaultColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (note.tags.length > 5) Text('+${note.tags.length - 5}', style: const TextStyle(fontSize: 9, color: VaultColors.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatUpdated(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'recently';
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) return 'today';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
