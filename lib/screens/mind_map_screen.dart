import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../sections.dart';
import '../widgets/common.dart';

const _nodeWidth = 188.0;
const _nodeHeight = 72.0;
const _canvasWidth = 1600.0;
const _canvasHeight = 1100.0;
const _nodeUuid = Uuid();

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key, required this.focusNodeId, required this.onFocusHandled, required this.onNavigate});
  final String? focusNodeId;
  final VoidCallback onFocusHandled;
  final ValueChanged<AppSection> onNavigate;
  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  final TransformationController _transform = TransformationController();
  String? _selectedNodeId;
  String? _connectFrom;
  bool _connectMode = false;
  bool _fullscreen = false;
  Size _viewport = Size.zero;
  final Map<String, Offset> _dragPositions = {};
  bool _initialFitDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialFitDone) { _fitView(); _initialFitDone = true; }
    });
  }

  @override
  void didUpdateWidget(covariant MindMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNodeId != null && widget.focusNodeId != oldWidget.focusNodeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedNodeId = widget.focusNodeId);
        _focusNode(widget.focusNodeId!);
        widget.onFocusHandled();
      });
    }
  }

  @override
  void dispose() { _transform.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final data = app.data;
    final selected = data.nodes.where((node) => node.id == _selectedNodeId).firstOrNull;
    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 880;
      final detailWidth = !mobile && !_fullscreen && _selectedNodeId != null ? 314.0 : 0.0;
      _viewport = Size(constraints.maxWidth - detailWidth, constraints.maxHeight - (_fullscreen ? 0 : 101));
      final pad = constraints.maxWidth < 600 ? 15.0 : 22.0;
      final hidden = <String>{};
      for (final node in data.nodes.where((item) => item.collapsed)) {
        for (final edge in data.edges.where((item) => item.source == node.id || item.target == node.id)) {
          final neighbor = edge.source == node.id ? edge.target : edge.source;
          if (neighbor != 'node-root' && neighbor != node.id && neighbor != selected?.id) hidden.add(neighbor);
        }
      }
      final visibleNodes = data.nodes.where((node) => !hidden.contains(node.id)).toList();
      final visibleEdges = data.edges.where((edge) => visibleNodes.any((node) => node.id == edge.source) && visibleNodes.any((node) => node.id == edge.target)).toList();
      return Column(children: [
        if (!_fullscreen) Padding(padding: EdgeInsets.fromLTRB(pad, 17, pad, 11), child: _MapHeader(onAdd: () => _showNodeEditor(context, app, parentId: selected?.id ?? 'node-root'), onAutoLayout: app.applyAutoLayout, onFit: _fitView, onFullscreen: () => setState(() => _fullscreen = true), fullscreen: false)),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: ClipRect(child: Stack(children: [
            Container(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF10121B) : const Color(0xFFF5F7FC)),
            InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              minScale: .24,
              maxScale: 2.15,
              boundaryMargin: const EdgeInsets.all(760),
              clipBehavior: Clip.none,
              child: SizedBox(width: _canvasWidth, height: _canvasHeight, child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _MapGridPainter(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF282C3A) : const Color(0xFFD8DCE8)))),
                Positioned.fill(child: CustomPaint(painter: _MapEdgesPainter(nodes: visibleNodes, edges: visibleEdges, selectedNodeId: _selectedNodeId, dark: Theme.of(context).brightness == Brightness.dark))),
                for (final node in visibleNodes) _positionedNode(node, app, selected, mobile),
              ]))),
            Positioned(left: 15, top: 15, child: _MapZoomPanel(onZoomIn: () => _zoom(1.18), onZoomOut: () => _zoom(.84), onFit: _fitView, onAuto: app.applyAutoLayout)),
            Positioned(left: 15, bottom: 16, child: _MapLegend()),
            if (_connectMode) Positioned(left: 0, right: 0, top: 0, child: _ConnectBanner(label: _connectFrom == null ? 'Choose a starting node' : 'Now select another node to connect', onCancel: () => setState(() { _connectMode = false; _connectFrom = null; }))),
            if (_fullscreen) Positioned(right: 16, top: 16, child: FilledButton.tonalIcon(onPressed: () => setState(() => _fullscreen = false), icon: const Icon(Icons.fullscreen_exit_rounded, size: 17), label: const Text('Exit full screen'))),
            if (selected == null && !mobile) Positioned(right: 18, top: 18, child: _MapHint()),
            if (selected != null && mobile) Positioned(left: 9, right: 9, bottom: 9, child: _NodePeek(node: selected, edges: data.edges, nodes: data.nodes, onOpen: () => _showNodeSheet(context, app, selected), onClose: () => setState(() => _selectedNodeId = null))),
          ]))),
          if (!mobile && !_fullscreen && selected != null) SizedBox(width: 314, child: _NodeDetailPanel(node: selected, nodes: data.nodes, edges: data.edges, projects: data.projects, assets: data.assets, tasks: data.tasks, onSelect: (node) { setState(() => _selectedNodeId = node.id); _focusNode(node.id); }, onEdit: () => _showNodeEditor(context, app, existing: selected), onDelete: () => _deleteNode(context, app, selected), onConnect: () => setState(() { _connectMode = true; _connectFrom = selected.id; }), onDisconnect: (other) => app.disconnectNodes(selected.id, other.id), onCollapse: () => app.toggleCollapsed(selected), onNavigate: widget.onNavigate, onClose: () => setState(() => _selectedNodeId = null), onFocus: () => _focusNode(selected.id))),
        ])),
      ]);
    });
  }

  Widget _positionedNode(MindNode node, AppController app, MindNode? selected, bool mobile) {
    final position = _dragPositions[node.id] ?? Offset(node.x, node.y);
    final active = selected?.id == node.id;
    final connected = _selectedNodeId != null && app.data.edges.any((edge) => (edge.source == _selectedNodeId && edge.target == node.id) || (edge.target == _selectedNodeId && edge.source == node.id));
    return Positioned(left: position.dx, top: position.dy, width: node.id == 'node-root' ? 205 : _nodeWidth, height: node.id == 'node-root' ? 79 : _nodeHeight, child: GestureDetector(
      onTap: () => _handleNodeTap(node, app),
      onDoubleTap: () => _showNodeSheet(context, app, node),
      onLongPress: () => _showNodeMenu(context, app, node),
      onSecondaryTapDown: (details) => _showNodeMenu(context, app, node, globalPosition: details.globalPosition),
      onPanStart: (_) => setState(() => _dragPositions[node.id] = position),
      onPanUpdate: (details) {
        final scale = _transform.value.getMaxScaleOnAxis().clamp(.25, 2.2);
        setState(() => _dragPositions[node.id] = (_dragPositions[node.id] ?? position) + details.delta / scale);
      },
      onPanEnd: (_) {
        final moved = _dragPositions.remove(node.id);
        if (moved != null) app.moveNode(node.id, moved.dx, moved.dy);
      },
      child: _MapNodeCard(node: node, selected: active, connected: connected, dimmed: _selectedNodeId != null && !connected && !active, connectMode: _connectMode),
    ));
  }

  void _handleNodeTap(MindNode node, AppController app) {
    if (_connectMode) {
      if (_connectFrom == null) {
        setState(() { _connectFrom = node.id; _selectedNodeId = node.id; });
      } else if (_connectFrom == node.id) {
        setState(() => _connectFrom = null);
      } else {
        app.connectNodes(_connectFrom!, node.id);
        setState(() { _selectedNodeId = node.id; _connectMode = false; _connectFrom = null; });
        _showMessage('Nodes connected');
      }
      return;
    }
    setState(() => _selectedNodeId = node.id);
  }

  void _focusNode(String nodeId) {
    final node = context.read<AppController>().data.nodes.where((item) => item.id == nodeId).firstOrNull;
    if (node == null || _viewport == Size.zero) return;
    final scale = 1.18;
    final centerX = node.x + (node.id == 'node-root' ? 100 : _nodeWidth / 2);
    final centerY = node.y + (node.id == 'node-root' ? 39 : _nodeHeight / 2);
    _transform.value = Matrix4.identity()..translate(_viewport.width / 2 - centerX * scale, _viewport.height / 2 - centerY * scale)..scale(scale);
  }

  void _fitView() {
    final nodes = context.read<AppController>().data.nodes;
    if (nodes.isEmpty || _viewport == Size.zero) return;
    var minX = double.infinity; var minY = double.infinity; var maxX = 0.0; var maxY = 0.0;
    for (final node in nodes) { minX = math.min(minX, node.x); minY = math.min(minY, node.y); maxX = math.max(maxX, node.x + _nodeWidth); maxY = math.max(maxY, node.y + _nodeHeight); }
    final boundsWidth = math.max(1.0, maxX - minX); final boundsHeight = math.max(1.0, maxY - minY);
    final scale = math.min((_viewport.width - 70) / boundsWidth, (_viewport.height - 90) / boundsHeight).clamp(.24, 1.25);
    final dx = _viewport.width / 2 - ((minX + maxX) / 2) * scale;
    final dy = _viewport.height / 2 - ((minY + maxY) / 2) * scale;
    _transform.value = Matrix4.identity()..translate(dx, dy)..scale(scale);
  }

  void _zoom(double factor) {
    final matrix = _transform.value.clone();
    matrix.translate(_viewport.width / 2, _viewport.height / 2);
    matrix.scale(factor);
    matrix.translate(-_viewport.width / 2, -_viewport.height / 2);
    _transform.value = matrix;
  }

  Future<void> _showNodeEditor(BuildContext context, AppController app, {MindNode? existing, String parentId = 'node-root'}) async {
    final result = await showDialog<_NodeDraft>(context: context, builder: (_) => _NodeEditor(existing: existing, parentId: parentId, data: app.data));
    if (result == null) return;
    if (existing == null) {
      final node = app.addNode(label: result.label, type: result.type, status: result.status, description: result.description, parentId: result.parentId);
      setState(() => _selectedNodeId = node.id);
    } else {
      app.updateNode(existing.copyWith(label: result.label, type: result.type, status: result.status, description: result.description));
    }
  }

  Future<void> _deleteNode(BuildContext context, AppController app, MindNode node) async {
    if (node.id == 'node-root') return;
    final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Remove node from map?'), content: Text('“${node.label}” will be removed from the mind map. Its project or asset record will stay in your workspace.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove'))]));
    if (confirm == true) { app.deleteNode(node); setState(() => _selectedNodeId = null); }
  }

  Future<void> _showNodeMenu(BuildContext context, AppController app, MindNode node, {Offset? globalPosition}) async {
    final position = globalPosition ?? (Overlay.of(context).context.findRenderObject() as RenderBox).localToGlobal(const Offset(170, 170));
    final selection = await showMenu<String>(context: context, position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1), items: [
      const PopupMenuItem(value: 'focus', child: _MenuLine(icon: Icons.center_focus_strong_rounded, label: 'Focus node')),
      const PopupMenuItem(value: 'edit', child: _MenuLine(icon: Icons.edit_outlined, label: 'Edit node')),
      PopupMenuItem(value: 'collapse', child: _MenuLine(icon: node.collapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded, label: node.collapsed ? 'Expand connections' : 'Collapse connections')),
      const PopupMenuItem(value: 'connect', child: _MenuLine(icon: Icons.link_rounded, label: 'Connect from here')),
      if (node.id != 'node-root') const PopupMenuItem(value: 'delete', child: _MenuLine(icon: Icons.delete_outline_rounded, label: 'Remove from map')),
    ]);
    if (!mounted || selection == null) return;
    setState(() => _selectedNodeId = node.id);
    switch (selection) {
      case 'focus': _focusNode(node.id); break;
      case 'edit': _showNodeEditor(context, app, existing: node); break;
      case 'collapse': app.toggleCollapsed(node); break;
      case 'connect': setState(() { _connectMode = true; _connectFrom = node.id; }); break;
      case 'delete': _deleteNode(context, app, node); break;
    }
  }

  Future<void> _showNodeSheet(BuildContext context, AppController app, MindNode node) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: _NodeDetailPanel(
            node: node,
            nodes: app.data.nodes,
            edges: app.data.edges,
            projects: app.data.projects,
            assets: app.data.assets,
            tasks: app.data.tasks,
            onSelect: (item) { Navigator.pop(sheetContext); setState(() => _selectedNodeId = item.id); _focusNode(item.id); },
            onEdit: () { Navigator.pop(sheetContext); _showNodeEditor(context, app, existing: node); },
            onDelete: () { Navigator.pop(sheetContext); _deleteNode(context, app, node); },
            onConnect: () { Navigator.pop(sheetContext); setState(() { _connectMode = true; _connectFrom = node.id; _selectedNodeId = node.id; }); },
            onDisconnect: (other) => app.disconnectNodes(node.id, other.id),
            onCollapse: () => app.toggleCollapsed(node),
            onNavigate: widget.onNavigate,
            onClose: () => Navigator.pop(sheetContext),
            onFocus: () { Navigator.pop(sheetContext); _focusNode(node.id); },
          ),
        ),
      ),
    ),
  );

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.onAdd, required this.onAutoLayout, required this.onFit, required this.onFullscreen, required this.fullscreen});
  final VoidCallback onAdd; final VoidCallback onAutoLayout; final VoidCallback onFit; final VoidCallback onFullscreen; final bool fullscreen;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('YOUR ECOSYSTEM', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)), const SizedBox(width: 7), Container(width: 5, height: 5, decoration: const BoxDecoration(color: VaultColors.green, shape: BoxShape.circle))]), const SizedBox(height: 4), Text('Mind Map', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 21)), const SizedBox(height: 2), Text('Explore how your digital world connects.', style: Theme.of(context).textTheme.bodySmall)])),
    _MapToolButton(icon: Icons.auto_awesome_motion_rounded, label: 'Auto layout', onTap: onAutoLayout, hideLabel: MediaQuery.sizeOf(context).width < 920), const SizedBox(width: 6),
    _MapToolButton(icon: Icons.fit_screen_rounded, label: 'Fit view', onTap: onFit, hideLabel: MediaQuery.sizeOf(context).width < 780), const SizedBox(width: 7),
    if (MediaQuery.sizeOf(context).width > 850) IconButton(tooltip: fullscreen ? 'Exit full screen' : 'Full screen', onPressed: onFullscreen, icon: const Icon(Icons.fullscreen_rounded, size: 19)),
    const SizedBox(width: 7), FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 16), label: Text(MediaQuery.sizeOf(context).width < 600 ? 'Node' : 'Add node'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11), textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
  ]);
}

class _MapToolButton extends StatelessWidget {
  const _MapToolButton({required this.icon, required this.label, required this.onTap, this.hideLabel = false}); final IconData icon; final String label; final VoidCallback onTap; final bool hideLabel;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 14), label: hideLabel ? const SizedBox.shrink() : Text(label), style: OutlinedButton.styleFrom(foregroundColor: VaultColors.muted, side: BorderSide(color: Theme.of(context).dividerColor), padding: EdgeInsets.symmetric(horizontal: hideLabel ? 8 : 10, vertical: 10), textStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), minimumSize: const Size(35, 36)));
}

class _MapZoomPanel extends StatelessWidget {
  const _MapZoomPanel({required this.onZoomIn, required this.onZoomOut, required this.onFit, required this.onAuto}); final VoidCallback onZoomIn; final VoidCallback onZoomOut; final VoidCallback onFit; final VoidCallback onAuto;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(.95), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 18, offset: const Offset(0, 6))]), child: Column(children: [
    _MapIconButton(icon: Icons.add_rounded, tooltip: 'Zoom in', onTap: onZoomIn), _MapIconButton(icon: Icons.remove_rounded, tooltip: 'Zoom out', onTap: onZoomOut), Container(height: 1, width: 25, margin: const EdgeInsets.symmetric(vertical: 3), color: Theme.of(context).dividerColor), _MapIconButton(icon: Icons.fit_screen_rounded, tooltip: 'Fit to screen', onTap: onFit), _MapIconButton(icon: Icons.auto_awesome_motion_rounded, tooltip: 'Auto layout', onTap: onAuto),
  ]));
}
class _MapIconButton extends StatelessWidget { const _MapIconButton({required this.icon, required this.tooltip, required this.onTap}); final IconData icon; final String tooltip; final VoidCallback onTap; @override Widget build(BuildContext context) => IconButton(tooltip: tooltip, visualDensity: VisualDensity.compact, onPressed: onTap, icon: Icon(icon, size: 17, color: VaultColors.muted)); }

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(.94), borderRadius: BorderRadius.circular(11), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [const _LegendItem(color: VaultColors.violet, label: 'Project'), const SizedBox(width: 12), const _LegendItem(color: VaultColors.cyan, label: 'Asset'), const SizedBox(width: 12), const _LegendItem(color: VaultColors.amber, label: 'Attention'), const SizedBox(width: 12), Text('Drag to move · Scroll to zoom', style: TextStyle(fontSize: 8, color: Theme.of(context).brightness == Brightness.dark ? VaultColors.faint : const Color(0xFF8B90A0)))]));
}
class _LegendItem extends StatelessWidget { const _LegendItem({required this.color, required this.label}); final Color color; final String label; @override Widget build(BuildContext context) => Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 8, color: VaultColors.muted))]); }

class _MapHint extends StatelessWidget { @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(.94), borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor)), child: const Row(children: [Icon(Icons.touch_app_rounded, size: 14, color: VaultColors.cyan), SizedBox(width: 6), Text('Select a node to see its connections', style: TextStyle(fontSize: 9, color: VaultColors.muted))])); }

class _ConnectBanner extends StatelessWidget { const _ConnectBanner({required this.label, required this.onCancel}); final String label; final VoidCallback onCancel; @override Widget build(BuildContext context) => Center(child: Container(margin: const EdgeInsets.only(top: 13), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.95), borderRadius: BorderRadius.circular(11), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 15)]), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.link_rounded, size: 15, color: Colors.white), const SizedBox(width: 7), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(width: 10), InkWell(onTap: onCancel, child: const Icon(Icons.close_rounded, size: 15, color: Colors.white))]))); }

class _MapNodeCard extends StatelessWidget {
  const _MapNodeCard({required this.node, required this.selected, required this.connected, required this.dimmed, required this.connectMode}); final MindNode node; final bool selected; final bool connected; final bool dimmed; final bool connectMode;
  @override
  Widget build(BuildContext context) {
    final root = node.id == 'node-root';
    final tint = root ? VaultColors.violet : _nodeColor(node.type);
    return AnimatedOpacity(duration: const Duration(milliseconds: 150), opacity: dimmed ? .48 : 1, child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: EdgeInsets.all(root ? 12 : 10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(root ? 17 : 14), border: Border.all(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.9) : connected ? tint.withOpacity(.48) : Theme.of(context).dividerColor, width: selected ? 1.5 : 1), boxShadow: [if (selected) BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(.19), blurRadius: 22, spreadRadius: 1), BoxShadow(color: Colors.black.withOpacity(.16), blurRadius: 12, offset: const Offset(0, 5))]), child: Row(children: [
      if (root) const BrandMark(size: 37) else Container(width: 34, height: 34, decoration: BoxDecoration(color: tint.withOpacity(.13), borderRadius: BorderRadius.circular(10)), child: Icon(_nodeIcon(node.type), size: 17, color: tint)),
      const SizedBox(width: 9), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(node.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: root ? 11.5 : 10, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Row(children: [Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor(node.status), shape: BoxShape.circle)), const SizedBox(width: 5), Expanded(child: Text(root ? 'PRIVATE WORKSPACE' : node.status.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 7, letterSpacing: .65, fontWeight: FontWeight.w700, color: root ? VaultColors.muted : statusColor(node.status))))])])),
      if (node.collapsed) Padding(padding: const EdgeInsets.only(left: 3), child: Icon(Icons.unfold_more_rounded, size: 14, color: VaultColors.muted)),
      if (connectMode && !root) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.add_link_rounded, size: 13, color: VaultColors.cyan)),
    ])));
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(.62)..strokeWidth = 1;
    const gap = 28.0;
    for (var x = 0.0; x < size.width; x += gap) { for (var y = 0.0; y < size.height; y += gap) { canvas.drawCircle(Offset(x + 14, y + 14), .85, paint); } }
  }
  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => oldDelegate.color != color;
}

class _MapEdgesPainter extends CustomPainter {
  _MapEdgesPainter({required this.nodes, required this.edges, required this.selectedNodeId, required this.dark});
  final List<MindNode> nodes; final List<MindEdge> edges; final String? selectedNodeId; final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final node in nodes) node.id: node};
    for (final edge in edges) {
      final source = byId[edge.source]; final target = byId[edge.target];
      if (source == null || target == null) continue;
      final start = Offset(source.x + (source.id == 'node-root' ? 102 : _nodeWidth / 2), source.y + (source.id == 'node-root' ? 39 : _nodeHeight / 2));
      final end = Offset(target.x + (target.id == 'node-root' ? 102 : _nodeWidth / 2), target.y + (target.id == 'node-root' ? 39 : _nodeHeight / 2));
      final highlighted = selectedNodeId != null && (edge.source == selectedNodeId || edge.target == selectedNodeId);
      final color = highlighted ? VaultColors.violet.withOpacity(.78) : (dark ? const Color(0xFF505469) : const Color(0xFF9EA6B8)).withOpacity(.38);
      final delta = (end - start);
      final bend = math.max(55.0, delta.distance * .26);
      final direction = delta.dx >= 0 ? 1.0 : -1.0;
      final path = Path()..moveTo(start.dx, start.dy)..cubicTo(start.dx + bend * direction, start.dy, end.dx - bend * direction, end.dy, end.dx, end.dy);
      final linePaint = Paint()..color = color..strokeWidth = 1.25..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      if (highlighted) linePaint.strokeWidth = 2.0;
      canvas.drawPath(path, linePaint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final arrowPath = Path()..moveTo(end.dx - 7 * math.cos(angle - .45), end.dy - 7 * math.sin(angle - .45))..lineTo(end.dx, end.dy)..lineTo(end.dx - 7 * math.cos(angle + .45), end.dy - 7 * math.sin(angle + .45));
      canvas.drawPath(arrowPath, Paint()..color = color..strokeWidth = 1.35..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      if (highlighted && edge.label.isNotEmpty) {
        final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 7);
        final text = TextPainter(text: TextSpan(text: edge.label, style: TextStyle(color: dark ? const Color(0xFFE0DEF2) : const Color(0xFF4E5362), fontSize: 8, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout(maxWidth: 100);
        final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: midpoint, width: text.width + 12, height: 18), const Radius.circular(6));
        canvas.drawRRect(rect, Paint()..color = dark ? const Color(0xFF202330) : Colors.white);
        text.paint(canvas, Offset(midpoint.dx - text.width / 2, midpoint.dy - text.height / 2));
      }
    }
  }
  @override
  bool shouldRepaint(covariant _MapEdgesPainter oldDelegate) => oldDelegate.nodes != nodes || oldDelegate.edges != edges || oldDelegate.selectedNodeId != selectedNodeId || oldDelegate.dark != dark;
}

class _NodeDetailPanel extends StatelessWidget {
  const _NodeDetailPanel({
    required this.node,
    required this.nodes,
    required this.edges,
    required this.projects,
    required this.assets,
    required this.tasks,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onConnect,
    required this.onDisconnect,
    required this.onCollapse,
    required this.onNavigate,
    required this.onClose,
    required this.onFocus,
  });
  final MindNode node;
  final List<MindNode> nodes;
  final List<MindEdge> edges;
  final List<ProjectItem> projects;
  final List<AssetItem> assets;
  final List<TaskItem> tasks;
  final ValueChanged<MindNode> onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConnect;
  final ValueChanged<MindNode> onDisconnect;
  final VoidCallback onCollapse;
  final ValueChanged<AppSection> onNavigate;
  final VoidCallback onClose;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final connectedEdges = edges.where((edge) => edge.source == node.id || edge.target == node.id).toList();
    final relatedNodes = connectedEdges
        .map((edge) => nodes.where((item) => item.id == (edge.source == node.id ? edge.target : edge.source)).firstOrNull)
        .whereType<MindNode>()
        .toList();
    final project = projects.where((item) => item.id == node.projectId || item.id == node.id.replaceFirst('node-', '')).firstOrNull;
    final asset = assets.where((item) => item.id == node.assetId || item.id == node.id.replaceFirst('node-', '')).firstOrNull;
    final relatedTasks = tasks
        .where((task) => (project != null && task.projectId == project.id) || (asset != null && task.assetId == asset.id))
        .where((task) => task.status != 'Done')
        .take(4)
        .toList();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 11, 13),
            child: Row(
              children: [
                const Expanded(child: Text('NODE DETAILS', style: TextStyle(color: VaultColors.muted, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.25))),
                IconButton(tooltip: 'Close details', onPressed: onClose, visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, size: 16)),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MapNodeIcon(type: node.type, size: 43),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(node.type.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                            const SizedBox(height: 4),
                            Text(node.label, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            StatusBadge(node.status, compact: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (node.description.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 14), child: Text(node.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55))),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _PanelAction(icon: Icons.center_focus_strong_rounded, label: 'Focus', onTap: onFocus),
                      _PanelAction(icon: Icons.link_rounded, label: 'Connect', onTap: onConnect),
                      _PanelAction(icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit),
                      if (node.id != 'node-root') _PanelAction(icon: Icons.delete_outline_rounded, label: 'Remove', onTap: onDelete, danger: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _PanelSection(
                    title: 'Connected to',
                    count: relatedNodes.length,
                    trailing: TextButton.icon(onPressed: onConnect, icon: const Icon(Icons.add_rounded, size: 13), label: const Text('Connect', style: TextStyle(fontSize: 9))),
                  ),
                  if (relatedNodes.isEmpty)
                    const _PanelEmpty('No connections yet. Link this node to another part of your workspace.')
                  else
                    ...relatedNodes.map((other) {
                      final connectingEdge = connectedEdges.where((edge) =>
                          (edge.source == other.id && edge.target == node.id) ||
                          (edge.target == other.id && edge.source == node.id)).firstOrNull;
                      return _ConnectedNodeRow(
                        node: other,
                        edge: connectingEdge,
                        onTap: () => onSelect(other),
                        onDisconnect: () => onDisconnect(other),
                      );
                    }),
                  if (project != null) ...[
                    const SizedBox(height: 17),
                    const _PanelSection(title: 'Related project'),
                    InkWell(
                      onTap: () => onNavigate(AppSection.projects),
                      child: Container(
                        margin: const EdgeInsets.only(top: 9),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: VaultColors.violet.withOpacity(.14),
                              child: Text(project.name[0].toUpperCase(), style: const TextStyle(color: VaultColors.violet, fontSize: 9, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(project.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text('${project.status} · ${project.progress}% complete', style: const TextStyle(fontSize: 8.5, color: VaultColors.muted)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 13, color: VaultColors.muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (relatedTasks.isNotEmpty) ...[
                    const SizedBox(height: 17),
                    _PanelSection(title: 'Open tasks', count: relatedTasks.length),
                    for (final task in relatedTasks)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 14, color: statusColor(task.status)),
                            const SizedBox(width: 7),
                            Expanded(child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600))),
                            Text(task.status, style: const TextStyle(fontSize: 8, color: VaultColors.muted)),
                          ],
                        ),
                      ),
                  ],
                  if (asset != null) ...[
                    const SizedBox(height: 17),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: VaultColors.cyan.withOpacity(.07), borderRadius: BorderRadius.circular(11), border: Border.all(color: VaultColors.cyan.withOpacity(.14))),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.key_rounded, size: 14, color: VaultColors.cyan),
                          SizedBox(width: 7),
                          Expanded(child: Text('Credentials and private values belong in Vault. Asset records are local metadata.', style: TextStyle(fontSize: 8.8, color: VaultColors.muted, height: 1.45))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 17),
                  OutlinedButton.icon(
                    onPressed: onCollapse,
                    icon: Icon(node.collapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded, size: 15),
                    label: Text(node.collapsed ? 'Expand connections' : 'Collapse connections', style: const TextStyle(fontSize: 9.5)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(37), alignment: Alignment.centerLeft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelSection extends StatelessWidget { const _PanelSection({required this.title, this.count, this.trailing}); final String title; final int? count; final Widget? trailing; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Row(children: [Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)), if (count != null) ...[const SizedBox(width: 6), CountTag(count!, color: VaultColors.cyan)]])), if (trailing != null) trailing!]); }
class _PanelEmpty extends StatelessWidget { const _PanelEmpty(this.value); final String value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(value, style: const TextStyle(fontSize: 9, color: VaultColors.muted, height: 1.5))); }
class _ConnectedNodeRow extends StatelessWidget { const _ConnectedNodeRow({required this.node, required this.edge, required this.onTap, required this.onDisconnect}); final MindNode node; final MindEdge? edge; final VoidCallback onTap; final VoidCallback onDisconnect; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 7), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.75))), child: Row(children: [_MapNodeIcon(type: node.type, size: 27), const SizedBox(width: 7), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(node.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)), Text(edge?.label.isNotEmpty == true ? edge!.label : node.type, style: const TextStyle(fontSize: 8, color: VaultColors.muted))])), IconButton(tooltip: 'Disconnect', visualDensity: VisualDensity.compact, onPressed: onDisconnect, icon: const Icon(Icons.link_off_rounded, size: 13, color: VaultColors.faint))])))); }
class _PanelAction extends StatelessWidget { const _PanelAction({required this.icon, required this.label, required this.onTap, this.danger = false}); final IconData icon; final String label; final VoidCallback onTap; final bool danger; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: danger ? VaultColors.red.withOpacity(.08) : Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: danger ? VaultColors.red.withOpacity(.17) : Theme.of(context).dividerColor)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: danger ? VaultColors.red : VaultColors.muted), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: danger ? VaultColors.red : VaultColors.muted))]))); }

class _NodePeek extends StatelessWidget { const _NodePeek({required this.node, required this.edges, required this.nodes, required this.onOpen, required this.onClose}); final MindNode node; final List<MindEdge> edges; final List<MindNode> nodes; final VoidCallback onOpen; final VoidCallback onClose; @override Widget build(BuildContext context) { final count = edges.where((edge) => edge.source == node.id || edge.target == node.id).length; return Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(15), elevation: 8, child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.fromLTRB(12, 10, 7, 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [_MapNodeIcon(type: node.type, size: 36), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(node.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Row(children: [StatusBadge(node.status, compact: true), const SizedBox(width: 6), Text('$count connections', style: const TextStyle(fontSize: 8.5, color: VaultColors.muted))])])), IconButton(onPressed: onOpen, icon: const Icon(Icons.arrow_upward_rounded, size: 16)), IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 15, color: VaultColors.muted))])))); } }

class _MapNodeIcon extends StatelessWidget { const _MapNodeIcon({required this.type, this.size = 34}); final String type; final double size; @override Widget build(BuildContext context) { final tint = _nodeColor(type); return Container(width: size, height: size, decoration: BoxDecoration(color: tint.withOpacity(.13), borderRadius: BorderRadius.circular(size * .28)), child: Icon(_nodeIcon(type), color: tint, size: size * .48)); } }
class _MenuLine extends StatelessWidget { const _MenuLine({required this.icon, required this.label}); final IconData icon; final String label; @override Widget build(BuildContext context) => Row(children: [Icon(icon, size: 15), const SizedBox(width: 9), Text(label, style: const TextStyle(fontSize: 11))]); }

class _NodeDraft { const _NodeDraft(this.label, this.type, this.status, this.description, this.parentId); final String label; final String type; final String status; final String description; final String parentId; }
class _NodeEditor extends StatefulWidget { const _NodeEditor({this.existing, required this.parentId, required this.data}); final MindNode? existing; final String parentId; final WorkspaceData data; @override State<_NodeEditor> createState() => _NodeEditorState(); }
class _NodeEditorState extends State<_NodeEditor> {
  final _formKey = GlobalKey<FormState>(); late final TextEditingController _label; late final TextEditingController _description; late String _type; late String _status; late String _parent;
  static const _types = ['Project', 'Website', 'Domain', 'GitHub', 'Cloudflare', 'Server', 'VPS', 'Hosting', 'Database', 'API', 'SaaS', 'Social Account', 'Email', 'Payment Gateway', 'Storage', 'Device', 'Document', 'Task'];
  @override void initState() { super.initState(); _label = TextEditingController(text: widget.existing?.label ?? ''); _description = TextEditingController(text: widget.existing?.description ?? ''); _type = widget.existing?.type ?? 'Domain'; _status = widget.existing?.status ?? 'Healthy'; _parent = widget.parentId; }
  @override void dispose() { _label.dispose(); _description.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text(widget.existing == null ? 'Add a node' : 'Edit node'), content: SizedBox(width: 420, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _label, autofocus: true, validator: (value) => value == null || value.trim().isEmpty ? 'A name is required' : null, decoration: const InputDecoration(labelText: 'Node name', hintText: 'e.g. Customer portal')), const SizedBox(height: 11), DropdownButtonFormField<String>(value: _types.contains(_type) ? _type : 'Project', decoration: const InputDecoration(labelText: 'Node type'), items: _types.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _type = value ?? _type)), const SizedBox(height: 11), DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: ['Healthy', 'Attention', 'Offline', 'Idea', 'Planning', 'Development', 'Production', 'Paused'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _status = value ?? _status)), if (widget.existing == null) ...[const SizedBox(height: 11), DropdownButtonFormField<String>(value: widget.data.nodes.any((node) => node.id == _parent) ? _parent : 'node-root', decoration: const InputDecoration(labelText: 'Connect to'), items: widget.data.nodes.map((node) => DropdownMenuItem(value: node.id, child: Text(node.label, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setState(() => _parent = value ?? 'node-root'))], const SizedBox(height: 11), TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', hintText: 'What does this node represent?'))])))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton.icon(onPressed: () { if (!_formKey.currentState!.validate()) return; Navigator.pop(context, _NodeDraft(_label.text.trim(), _type, _status, _description.text.trim(), _parent)); }, icon: const Icon(Icons.check_rounded, size: 15), label: const Text('Save node'))]);
}

Color _nodeColor(String type) => switch (type) { 'Workspace' => VaultColors.violet, 'Project' => VaultColors.violet, 'Domain' || 'Email' => VaultColors.cyan, 'GitHub' => VaultColors.text, 'Cloudflare' => VaultColors.amber, 'Server' || 'VPS' || 'Hosting' || 'Device' => VaultColors.blue, 'Database' || 'Storage' => VaultColors.cyan, 'API' || 'Social Account' => VaultColors.pink, 'Document' => VaultColors.blue, 'Task' => VaultColors.amber, _ => VaultColors.violet };
IconData _nodeIcon(String type) => switch (type) { 'Workspace' => Icons.hub_rounded, 'Project' => Icons.folder_copy_rounded, 'Website' => Icons.web_rounded, 'Domain' => Icons.language_rounded, 'GitHub' => Icons.code_rounded, 'Cloudflare' => Icons.cloud_rounded, 'Server' || 'VPS' || 'Hosting' => Icons.dns_rounded, 'Database' => Icons.storage_rounded, 'API' => Icons.api_rounded, 'SaaS' => Icons.apps_rounded, 'Social Account' => Icons.people_alt_rounded, 'Email' => Icons.alternate_email_rounded, 'Payment Gateway' => Icons.payments_outlined, 'Storage' => Icons.folder_open_rounded, 'Device' => Icons.devices_rounded, 'Document' => Icons.description_outlined, 'Task' => Icons.checklist_rounded, _ => Icons.widgets_rounded };
extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty ? null : first; }
