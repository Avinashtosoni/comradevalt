import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../widgets/common.dart';

class NavDestination {
  const NavDestination(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const workspaceDestinations = [
  NavDestination('mindmap', 'Mind Map', Icons.hub_rounded),
  NavDestination('dashboard', 'Dashboard', Icons.grid_view_rounded),
  NavDestination('projects', 'Projects', Icons.folder_copy_rounded),
  NavDestination('assets', 'Digital Assets', Icons.widgets_rounded),
  NavDestination('notes', 'Notes', Icons.sticky_note_2_rounded),
  NavDestination('vault', 'Vault', Icons.key_rounded),
];
const operationsDestinations = [
  NavDestination('tasks', 'Tasks', Icons.checklist_rounded),
  NavDestination('renewals', 'Renewals', Icons.event_repeat_rounded),
  NavDestination('activity', 'Activity', Icons.timeline_rounded),
  NavDestination('notifications', 'Notifications', Icons.notifications_none_rounded),
];
const settingsDestination = NavDestination('settings', 'Settings', Icons.tune_rounded);

class FullNavigation extends StatelessWidget {
  const FullNavigation({
    super.key,
    required this.section,
    required this.onSelect,
    required this.onSearch,
    required this.onQuickAdd,
    required this.unreadCount,
  });
  final String section;
  final ValueChanged<String> onSelect;
  final VoidCallback onSearch;
  final VoidCallback onQuickAdd;
  final int unreadCount;

  @override
  Widget build(BuildContext context) => Container(
        width: 246,
        color: Theme.of(context).brightness == Brightness.dark ? VaultColors.sidebar : const Color(0xFFF9FAFD),
        padding: const EdgeInsets.fromLTRB(14, 17, 13, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 20),
              child: Row(
                children: [
                  const BrandMark(size: 37),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -.4),
                            children: const [TextSpan(text: 'comrade'), TextSpan(text: 'vault', style: TextStyle(color: VaultColors.violet))],
                          ),
                        ),
                        Text(
                          'DIGITAL COMMAND CENTER',
                          style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 1.15, color: Theme.of(context).brightness == Brightness.dark ? VaultColors.muted : const Color(0xFF767A8C)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF191C27) : const Color(0xFFF0F1F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.65)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF53BFC2), Color(0xFF795AE9)]), borderRadius: BorderRadius.circular(9)),
                    alignment: Alignment.center,
                    child: const Text('C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personal workspace', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        const Text('Local · this device', style: TextStyle(fontSize: 9, color: VaultColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: VaultColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF191C27) : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.55)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 15, color: VaultColors.muted),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Search anything', style: TextStyle(color: VaultColors.muted, fontSize: 10.5))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(5), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: const Text('⌘ K', style: TextStyle(fontSize: 8.5, color: VaultColors.muted, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GroupLabel('WORKSPACE', trailing: IconButton(onPressed: onQuickAdd, visualDensity: VisualDensity.compact, tooltip: 'Quick create', icon: const Icon(Icons.add_rounded, size: 16))),
                    ...workspaceDestinations.map((item) => _NavItem(destination: item, selected: section == item.id, onTap: () => onSelect(item.id))),
                    const SizedBox(height: 14),
                    const _GroupLabel('OPERATIONS'),
                    ...operationsDestinations.map((item) => _NavItem(destination: item, selected: section == item.id, badge: item.id == 'notifications' ? unreadCount : 0, onTap: () => onSelect(item.id))),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(color: VaultColors.green.withOpacity(.06), border: Border.all(color: VaultColors.green.withOpacity(.14)), borderRadius: BorderRadius.circular(11)),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: VaultColors.green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: VaultColors.green, blurRadius: 7)])),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vault encrypted locally', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Workspace notes are not encrypted', style: TextStyle(fontSize: 8.5, color: VaultColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.shield_outlined, size: 15, color: VaultColors.green),
                ],
              ),
            ),
            _NavItem(destination: settingsDestination, selected: section == 'settings', onTap: () => onSelect('settings')),
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                children: [
                  const CircleAvatar(radius: 14, backgroundColor: Color(0xFF293544), child: Text('YU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF9BE1DB)))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your workspace', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        const Text('Personal · local', style: TextStyle(fontSize: 8, color: VaultColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz_rounded, size: 18, color: VaultColors.muted),
                ],
              ),
            ),
          ],
        ),
      );
}

class CompactNavigation extends StatelessWidget {
  const CompactNavigation({super.key, required this.section, required this.onSelect, required this.onSearch, required this.onQuickAdd, required this.unreadCount});
  final String section;
  final ValueChanged<String> onSelect;
  final VoidCallback onSearch;
  final VoidCallback onQuickAdd;
  final int unreadCount;
  @override
  Widget build(BuildContext context) => Container(width: 76, color: Theme.of(context).brightness == Brightness.dark ? VaultColors.sidebar : const Color(0xFFF9FAFD), child: Column(children: [
    const Padding(padding: EdgeInsets.fromLTRB(0, 18, 0, 18), child: BrandMark(size: 35)),
    IconButton(onPressed: onSearch, tooltip: 'Search', icon: const Icon(Icons.search_rounded, size: 20)),
    IconButton(onPressed: onQuickAdd, tooltip: 'Quick create', icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: Theme.of(context).colorScheme.primary)),
    const SizedBox(height: 12),
    Expanded(child: SingleChildScrollView(child: Column(children: [
      ...workspaceDestinations.map((item) => _CompactNavItem(destination: item, selected: section == item.id, onTap: () => onSelect(item.id))),
      const Divider(height: 20, indent: 17, endIndent: 17),
      ...operationsDestinations.map((item) => _CompactNavItem(destination: item, selected: section == item.id, badge: item.id == 'notifications' ? unreadCount : 0, onTap: () => onSelect(item.id))),
    ]))),
    _CompactNavItem(destination: settingsDestination, selected: section == 'settings', onTap: () => onSelect('settings')),
    const SizedBox(height: 12),
  ]));
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label, {this.trailing});
  final String label;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(9, 2, 1, 5), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: VaultColors.faint, letterSpacing: 1.25))), if (trailing != null) SizedBox(width: 25, height: 25, child: trailing)]));
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap, this.badge = 0});
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? accent.withOpacity(.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            height: 37,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: selected ? 19 : 0,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 9),
                Icon(destination.icon, size: 16, color: selected ? accent : VaultColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(fontSize: 10.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Theme.of(context).colorScheme.onSurface : VaultColors.muted),
                  ),
                ),
                if (badge > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: VaultColors.red.withOpacity(.14), borderRadius: BorderRadius.circular(7)),
                    child: Text('$badge', style: const TextStyle(color: VaultColors.red, fontSize: 8, fontWeight: FontWeight.w800)),
                  ),
                if (selected && badge == 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: Container(width: 5, height: 5, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavItem extends StatelessWidget {
  const _CompactNavItem({required this.destination, required this.selected, required this.onTap, this.badge = 0});
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => Tooltip(message: destination.label, child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: SizedBox(width: 60, height: 52, child: Stack(alignment: Alignment.center, children: [
    AnimatedContainer(duration: const Duration(milliseconds: 180), width: 42, height: 39, decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.14) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(destination.icon, size: 19, color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted)),
    if (badge > 0) Positioned(top: 5, right: 7, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: VaultColors.red, shape: BoxShape.circle))),
  ])))));
}
