import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';
import 'editors.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key, required this.onNavigate, required this.onFocusNode});
  final ValueChanged<AppSection> onNavigate;
  final ValueChanged<String> onFocusNode;
  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  String _filter = 'All assets';
  String _query = '';
  final _searchController = TextEditingController();
  static const _filters = ['All assets', 'Domain', 'GitHub', 'Cloudflare', 'Server', 'Database', 'API', 'SaaS', 'Email', 'Document'];
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final filtered = app.data.assets.where((asset) {
      final matchesQuery = '${asset.name} ${asset.type} ${asset.summary} ${asset.tags.join(' ')} ${asset.fields.values.join(' ')}'.toLowerCase().contains(_query.toLowerCase());
      final matchesType = _filter == 'All assets' || asset.type == _filter || (_filter == 'Server' && ['VPS', 'Hosting'].contains(asset.type));
      return matchesQuery && matchesType;
    }).toList();
    final attention = app.data.assets.where((asset) => asset.status == 'Attention' || asset.status == 'Offline').length;
    final categoryCount = app.data.assets.map((asset) => asset.type).toSet().length;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      final pad = compact ? 16.0 : 28.0;
      return SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, compact ? 18 : 27, pad, 28), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(eyebrow: 'WORKSPACE / DIGITAL ASSETS', title: 'Digital assets', subtitle: 'Your domains, services, code and infrastructure — in one connected place.', count: app.data.assets.length.toString().padLeft(2, '0'), actions: compact ? null : Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () => widget.onNavigate(AppSection.mindMap), icon: const Icon(Icons.hub_rounded, size: 15), label: const Text('Explore map')), PrimaryAction(label: 'Add asset', onPressed: () => showAssetEditor(context, app))])),
        _AssetSummary(total: app.data.assets.length, categories: categoryCount, attention: attention),
        const SizedBox(height: 18),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _filters.map((item) => Padding(padding: const EdgeInsets.only(right: 6), child: _AssetFilter(label: item, selected: _filter == item, count: item == 'All assets' ? app.data.assets.length : null, onTap: () => setState(() => _filter = item)))).toList())),
        const SizedBox(height: 10),
        _AssetSearch(controller: _searchController, query: _query, compact: compact, onChanged: (value) => setState(() => _query = value)),
        const SizedBox(height: 13),
        if (filtered.isEmpty) EmptyState(icon: Icons.widgets_outlined, title: _query.isEmpty ? 'No assets connected yet' : 'No matching assets', description: _query.isEmpty ? 'Connect a domain, repository, server or service to start mapping your digital ecosystem.' : 'Try another search or choose a different category.', actionLabel: 'Add an asset', onAction: () => showAssetEditor(context, app))
        else compact ? Column(children: filtered.map((asset) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _AssetCard(asset: asset, projectName: app.data.projects.where((p) => p.id == asset.projectId).firstOrNull?.name, onOpen: () => _showAssetDetails(context, asset, app), onEdit: () => showAssetEditor(context, app, asset), onDelete: () => _deleteAsset(context, app, asset), onFocus: () => widget.onFocusNode('node-${asset.id}')))).toList()) : _AssetTable(assets: filtered, projects: app.data.projects, onOpen: (asset) => _showAssetDetails(context, asset, app), onEdit: (asset) => showAssetEditor(context, app, asset), onDelete: (asset) => _deleteAsset(context, app, asset), onFocus: (asset) => widget.onFocusNode('node-${asset.id}'), onProjectTap: () => widget.onNavigate(AppSection.projects)),
        const SizedBox(height: 13),
        Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11), decoration: BoxDecoration(color: VaultColors.cyan.withOpacity(.055), borderRadius: BorderRadius.circular(12), border: Border.all(color: VaultColors.cyan.withOpacity(.13))), child: Row(children: [const Icon(Icons.shield_outlined, size: 15, color: VaultColors.cyan), const SizedBox(width: 8), const Expanded(child: Text('Keep passwords, API keys and private IPs in Vault — asset details are not encrypted.', style: TextStyle(fontSize: 9.5, color: VaultColors.muted))), TextButton(onPressed: () => widget.onNavigate(AppSection.vault), style: TextButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('Open Vault', style: TextStyle(fontSize: 10)))])),
      ]))));
    });
  }

  Future<void> _showAssetDetails(BuildContext context, AssetItem asset, AppController app) => showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).colorScheme.surface, showDragHandle: true, builder: (sheetContext) {
    final current = app.data.assets.where((item) => item.id == asset.id).firstOrNull ?? asset;
    final projectName = app.data.projects.where((project) => project.id == current.projectId).firstOrNull?.name;
    return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(19, 3, 19, 24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [_AssetIcon(type: current.type, size: 44), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(current.type.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.3)), const SizedBox(height: 4), Text(current.name, style: Theme.of(context).textTheme.titleLarge)])), StatusBadge(current.status)]),
      if (current.summary.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 13, bottom: 11), child: Text(current.summary, style: Theme.of(context).textTheme.bodySmall)),
      _DetailLine(label: 'Related project', value: projectName ?? 'Unlinked'),
      ...current.fields.entries.where((entry) => entry.value.isNotEmpty).map((entry) => _DetailLine(label: entry.key, value: entry.value)),
      if (current.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 9, bottom: 14), child: Wrap(spacing: 6, runSpacing: 6, children: current.tags.map((tag) => TagChip(tag)).toList())),
      Container(margin: const EdgeInsets.only(top: 15), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [const Icon(Icons.key_rounded, size: 16, color: VaultColors.cyan), const SizedBox(width: 8), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Credentials stay separate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), SizedBox(height: 3), Text('Secret values are never stored in asset details.', style: TextStyle(fontSize: 9, color: VaultColors.muted))])), TextButton(onPressed: () { Navigator.pop(sheetContext); widget.onNavigate(AppSection.vault); }, child: const Text('Vault', style: TextStyle(fontSize: 10)))])),
      const SizedBox(height: 14), Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); widget.onFocusNode('node-${current.id}'); }, icon: const Icon(Icons.hub_rounded, size: 15), label: const Text('Open in mind map')), FilledButton.icon(onPressed: () { Navigator.pop(sheetContext); showAssetEditor(context, app, current); }, icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Edit asset'))]),
    ])))));
  });

  Future<void> _deleteAsset(BuildContext context, AppController app, AssetItem asset) async {
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Remove asset?'), content: Text('“${asset.name}” will be removed from your workspace and mind map.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove'))]));
    if (ok == true) app.deleteAsset(asset);
  }
}

class _AssetSummary extends StatelessWidget {
  const _AssetSummary({required this.total, required this.categories, required this.attention});
  final int total; final int categories; final int attention;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [
    _AssetMetric(icon: Icons.widgets_rounded, color: VaultColors.violet, value: total, label: 'Tracked assets'), _DividerVertical(), _AssetMetric(icon: Icons.category_outlined, color: VaultColors.cyan, value: categories, label: 'Categories'), const Spacer(),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: (attention > 0 ? VaultColors.amber : VaultColors.green).withOpacity(.09), borderRadius: BorderRadius.circular(10)), child: Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: attention > 0 ? VaultColors.amber : VaultColors.green, shape: BoxShape.circle)), const SizedBox(width: 7), Text(attention > 0 ? '$attention need a look' : 'All systems healthy', style: TextStyle(color: attention > 0 ? VaultColors.amber : VaultColors.green, fontSize: 9.5, fontWeight: FontWeight.w700))])),
  ]));
}
class _AssetMetric extends StatelessWidget { const _AssetMetric({required this.icon, required this.color, required this.value, required this.label}); final IconData icon; final Color color; final int value; final String label; @override Widget build(BuildContext context) => Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 15, color: color)), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))])]); }
class _DividerVertical extends StatelessWidget { @override Widget build(BuildContext context) => Container(height: 27, width: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: Theme.of(context).dividerColor); }

class _AssetFilter extends StatelessWidget {
  const _AssetFilter({required this.label, required this.selected, required this.onTap, this.count}); final String label; final bool selected; final VoidCallback onTap; final int? count;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label), if (count != null) ...[const SizedBox(width: 5), Text('$count', style: const TextStyle(fontSize: 9, color: VaultColors.muted, fontWeight: FontWeight.w800))]]), selected: selected, onSelected: (_) => onTap(), labelStyle: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : VaultColors.muted, fontSize: 9.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500), visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 3), side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.3) : Theme.of(context).dividerColor), backgroundColor: Theme.of(context).colorScheme.surface, selectedColor: Theme.of(context).colorScheme.primary.withOpacity(.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))));
}
class _AssetSearch extends StatelessWidget { const _AssetSearch({required this.controller, required this.query, required this.compact, required this.onChanged}); final TextEditingController controller; final String query; final bool compact; final ValueChanged<String> onChanged; @override Widget build(BuildContext context) => Align(alignment: Alignment.centerRight, child: SizedBox(width: compact ? double.infinity : 240, child: TextField(controller: controller, onChanged: onChanged, decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search_rounded, size: 16), hintText: 'Find an asset', suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { controller.clear(); onChanged(''); }, icon: const Icon(Icons.close_rounded, size: 14)))))); }

class _AssetTable extends StatelessWidget {
  const _AssetTable({required this.assets, required this.projects, required this.onOpen, required this.onEdit, required this.onDelete, required this.onFocus, required this.onProjectTap});
  final List<AssetItem> assets; final List<ProjectItem> projects; final ValueChanged<AssetItem> onOpen; final ValueChanged<AssetItem> onEdit; final ValueChanged<AssetItem> onDelete; final ValueChanged<AssetItem> onFocus; final VoidCallback onProjectTap;
  @override
  Widget build(BuildContext context) => Container(clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(children: [
    Container(height: 39, padding: const EdgeInsets.symmetric(horizontal: 16), color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B1E29) : const Color(0xFFF7F8FB), child: const Row(children: [Expanded(flex: 4, child: _TableLabel('ASSET')), Expanded(flex: 2, child: _TableLabel('TYPE')), Expanded(flex: 2, child: _TableLabel('STATUS')), Expanded(flex: 3, child: _TableLabel('PROJECT')), SizedBox(width: 105, child: _TableLabel('UPDATED')), SizedBox(width: 76)])),
    ...assets.map((asset) { final project = projects.where((item) => item.id == asset.projectId).firstOrNull; return _AssetTableRow(asset: asset, projectName: project?.name, onOpen: () => onOpen(asset), onEdit: () => onEdit(asset), onDelete: () => onDelete(asset), onFocus: () => onFocus(asset), onProjectTap: onProjectTap); }),
  ]));
}
class _TableLabel extends StatelessWidget { const _TableLabel(this.value); final String value; @override Widget build(BuildContext context) => Text(value, style: const TextStyle(fontSize: 8, color: VaultColors.faint, fontWeight: FontWeight.w800, letterSpacing: 1.0)); }
class _AssetTableRow extends StatelessWidget {
  const _AssetTableRow({required this.asset, required this.projectName, required this.onOpen, required this.onEdit, required this.onDelete, required this.onFocus, required this.onProjectTap}); final AssetItem asset; final String? projectName; final VoidCallback onOpen; final VoidCallback onEdit; final VoidCallback onDelete; final VoidCallback onFocus; final VoidCallback onProjectTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onOpen, child: Container(height: 63, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.65)))), child: Row(children: [
    Expanded(flex: 4, child: Row(children: [_AssetIcon(type: asset.type, size: 33), const SizedBox(width: 9), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(asset.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))]))])),
    Expanded(flex: 2, child: Text(asset.type, style: const TextStyle(fontSize: 9.5, color: VaultColors.muted))), Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: StatusBadge(asset.status, compact: true))),
    Expanded(flex: 3, child: projectName == null ? const Text('Unlinked', style: TextStyle(fontSize: 9, color: VaultColors.faint)) : InkWell(onTap: onProjectTap, child: Row(children: [CircleAvatar(radius: 10, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.14), child: Text(projectName![0].toUpperCase(), style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800))), const SizedBox(width: 6), Flexible(child: Text(projectName!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)))]))),
    SizedBox(width: 105, child: Text(_shortDate(asset.updatedAt), style: const TextStyle(fontSize: 9, color: VaultColors.muted))),
    SizedBox(width: 76, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(tooltip: 'Open in mind map', onPressed: onFocus, visualDensity: VisualDensity.compact, icon: const Icon(Icons.hub_outlined, size: 15, color: VaultColors.cyan)), PopupMenuButton<String>(tooltip: 'Asset options', padding: EdgeInsets.zero, iconSize: 17, icon: const Icon(Icons.more_horiz_rounded, color: VaultColors.muted), onSelected: (value) => value == 'edit' ? onEdit() : value == 'remove' ? onDelete() : onOpen(), itemBuilder: (_) => const [PopupMenuItem(value: 'view', child: Text('View details')), PopupMenuItem(value: 'edit', child: Text('Edit asset')), PopupMenuItem(value: 'remove', child: Text('Remove asset'))])])),
  ])));
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset, required this.projectName, required this.onOpen, required this.onEdit, required this.onDelete, required this.onFocus}); final AssetItem asset; final String? projectName; final VoidCallback onOpen; final VoidCallback onEdit; final VoidCallback onDelete; final VoidCallback onFocus;
  @override
  Widget build(BuildContext context) => Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(15), child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [_AssetIcon(type: asset.type, size: 39), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), StatusBadge(asset.status, compact: true)]), const SizedBox(height: 4), Text('${asset.type}${projectName == null ? '' : ' · $projectName'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: VaultColors.muted)), const SizedBox(height: 4), Text(asset.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: VaultColors.faint))])), PopupMenuButton<String>(icon: const Icon(Icons.more_vert_rounded, size: 17, color: VaultColors.muted), onSelected: (value) => value == 'edit' ? onEdit() : value == 'remove' ? onDelete() : onFocus(), itemBuilder: (_) => const [PopupMenuItem(value: 'focus', child: Text('Open in map')), PopupMenuItem(value: 'edit', child: Text('Edit asset')), PopupMenuItem(value: 'remove', child: Text('Remove asset'))])]))));
}

class _AssetIcon extends StatelessWidget { const _AssetIcon({required this.type, this.size = 34}); final String type; final double size; @override Widget build(BuildContext context) { final color = _assetColor(type); return Container(width: size, height: size, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(size * .28)), child: Icon(_assetIcon(type), size: size * .47, color: color)); } }
IconData _assetIcon(String type) => switch (type) { 'Domain' => Icons.language_rounded, 'GitHub' => Icons.code_rounded, 'Cloudflare' => Icons.cloud_rounded, 'Server' || 'VPS' || 'Hosting' => Icons.dns_rounded, 'Database' => Icons.storage_rounded, 'API' => Icons.api_rounded, 'SaaS' => Icons.apps_rounded, 'Email' => Icons.alternate_email_rounded, 'Social Account' => Icons.people_alt_rounded, 'Payment Gateway' => Icons.payments_outlined, 'Storage' => Icons.folder_open_rounded, 'Device' => Icons.devices_rounded, 'Document' => Icons.description_outlined, _ => Icons.widgets_rounded};
Color _assetColor(String type) => switch (type) { 'Domain' => VaultColors.cyan, 'GitHub' => VaultColors.text, 'Cloudflare' => VaultColors.amber, 'Server' || 'VPS' || 'Hosting' => VaultColors.blue, 'Database' => VaultColors.violet, 'API' => VaultColors.pink, 'Email' => VaultColors.cyan, 'Document' => VaultColors.blue, _ => VaultColors.violet};
class _DetailLine extends StatelessWidget { const _DetailLine({required this.label, required this.value}); final String label; final String value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 115, child: Text(label, style: const TextStyle(fontSize: 10, color: VaultColors.muted))), Expanded(child: Text(value, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)))])); }
String _shortDate(String value) { final date = DateTime.tryParse(value); if (date == null) return '—'; return '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]}'; }
extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty ? null : first; }
