import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class AppController extends ChangeNotifier {
  static const _workspaceKey = 'comrade_vault.workspace.v1';
  static const _uuid = Uuid();

  WorkspaceData data = WorkspaceData.demo();
  bool ready = false;
  bool isOnline = true;
  String? persistenceMessage;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  SharedPreferences? _preferences;

  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final saved = _preferences!.getString(_workspaceKey);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is Map<String, dynamic>) data = WorkspaceData.fromJson(decoded);
      }
    } catch (_) {
      persistenceMessage = 'Local storage could not be opened. Changes may not persist.';
    }
    try {
      final current = await Connectivity().checkConnectivity();
      isOnline = current.any((item) => item != ConnectivityResult.none);
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        final online = results.any((item) => item != ConnectivityResult.none);
        if (online != isOnline) {
          isOnline = online;
          notifyListeners();
        }
      });
    } catch (_) {
      // Connectivity checks are an enhancement; the workspace remains available offline.
    }
    ready = true;
    notifyListeners();
  }

  void _save() {
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final saved = await _preferences!.setString(_workspaceKey, jsonEncode(data.toJson()));
      if (!saved) throw StateError('Workspace preferences were not saved.');
      persistenceMessage = null;
    } catch (_) {
      persistenceMessage = 'Could not save this change on the device. Check available storage.';
      notifyListeners();
    }
  }

  ActivityItem _activity(String title, String detail, String kind, {String? entityId, String? entityType}) => ActivityItem(
    id: _uuid.v4(), title: title, detail: detail, kind: kind, entityId: entityId, entityType: entityType, createdAt: DateTime.now().toIso8601String(),
  );

  void _prependActivity(ActivityItem activity) {
    data = data.copyWith(activities: [activity, ...data.activities].take(100).toList());
  }

  void saveProject(ProjectItem project) {
    final isNew = !data.projects.any((item) => item.id == project.id);
    final nodeId = 'node-${project.id}';
    final node = MindNode(id: nodeId, label: project.name, type: 'Project', status: project.status, description: project.description, projectId: project.id, x: 440 + (data.nodes.length % 4) * 110, y: 180 + (data.nodes.length % 3) * 115);
    final projects = isNew ? [project, ...data.projects] : data.projects.map((item) => item.id == project.id ? project : item).toList();
    final nodes = data.nodes.any((item) => item.id == nodeId) ? data.nodes.map((item) => item.id == nodeId ? item.copyWith(label: project.name, status: project.status, description: project.description) : item).toList() : [...data.nodes, node];
    final edges = data.edges.any((edge) => edge.source == 'node-root' && edge.target == nodeId) ? data.edges : [...data.edges, MindEdge(id: _uuid.v4(), source: 'node-root', target: nodeId, label: 'owns')];
    data = data.copyWith(projects: projects, nodes: nodes, edges: edges);
    _prependActivity(_activity(isNew ? 'Project created' : 'Project updated', '${project.name} · ${project.status}', 'project', entityId: project.id, entityType: 'project'));
    _save();
  }

  void deleteProject(ProjectItem project) {
    final nodeId = 'node-${project.id}';
    final assets = data.assets.map((asset) => asset.projectId == project.id ? asset.copyWith(clearProject: true) : asset).toList();
    final tasks = data.tasks.map((task) => task.projectId == project.id ? task.copyWith(clearProject: true) : task).toList();
    final renewals = data.renewals.map((renewal) => renewal.projectId == project.id ? renewal.copyWith(clearProject: true) : renewal).toList();
    data = data.copyWith(
      projects: data.projects.where((item) => item.id != project.id).toList(),
      assets: assets, tasks: tasks, renewals: renewals,
      nodes: data.nodes.where((node) => node.id != nodeId).toList(),
      edges: data.edges.where((edge) => edge.source != nodeId && edge.target != nodeId).toList(),
    );
    _prependActivity(_activity('Project removed', project.name, 'project'));
    _save();
  }

  void saveAsset(AssetItem asset) {
    final isNew = !data.assets.any((item) => item.id == asset.id);
    final nodeId = 'node-${asset.id}';
    final node = MindNode(id: nodeId, label: asset.name, type: asset.type, status: asset.status, description: asset.summary, projectId: asset.projectId, assetId: asset.id, x: 440 + (data.nodes.length % 5) * 100, y: 120 + (data.nodes.length % 4) * 115);
    final assets = isNew ? [asset, ...data.assets] : data.assets.map((item) => item.id == asset.id ? asset : item).toList();
    final nodes = data.nodes.any((item) => item.id == nodeId) ? data.nodes.map((item) => item.id == nodeId ? item.copyWith(label: asset.name, type: asset.type, status: asset.status, description: asset.summary, projectId: asset.projectId, clearProject: asset.projectId == null, assetId: asset.id) : item).toList() : [...data.nodes, node];
    final parent = asset.projectId == null ? 'node-root' : 'node-${asset.projectId}';
    var edges = data.edges.where((edge) => !(edge.target == nodeId && (edge.label == 'uses' || edge.label == 'tracks'))).toList();
    if (!edges.any((edge) => edge.source == parent && edge.target == nodeId)) edges = [...edges, MindEdge(id: _uuid.v4(), source: parent, target: nodeId, label: asset.projectId == null ? 'tracks' : 'uses')];
    data = data.copyWith(assets: assets, nodes: nodes, edges: edges);
    final project = data.projects.where((item) => item.id == asset.projectId).firstOrNull;
    _prependActivity(_activity(isNew ? '${asset.type} added' : '${asset.type} updated', '${asset.name}${project == null ? '' : ' · ${project.name}'}', 'asset', entityId: asset.id, entityType: 'asset'));
    _save();
  }

  void deleteAsset(AssetItem asset) {
    final nodeId = 'node-${asset.id}';
    data = data.copyWith(
      assets: data.assets.where((item) => item.id != asset.id).toList(),
      nodes: data.nodes.where((item) => item.id != nodeId).toList(),
      edges: data.edges.where((edge) => edge.source != nodeId && edge.target != nodeId).toList(),
      tasks: data.tasks.map((task) => task.assetId == asset.id ? task.copyWith(clearAsset: true) : task).toList(),
    );
    _prependActivity(_activity('${asset.type} removed', asset.name, 'asset'));
    _save();
  }

  void saveTask(TaskItem task) {
    final isNew = !data.tasks.any((item) => item.id == task.id);
    final tasks = isNew ? [task, ...data.tasks] : data.tasks.map((item) => item.id == task.id ? task : item).toList();
    final project = data.projects.where((item) => item.id == task.projectId).firstOrNull;
    data = data.copyWith(tasks: tasks);
    _prependActivity(_activity(isNew ? 'Task created' : 'Task updated', '${task.title}${project == null ? '' : ' · ${project.name}'}', 'task', entityId: task.id, entityType: 'task'));
    _save();
  }

  void updateTaskStatus(TaskItem task, String status) {
    if (task.status == status) return;
    data = data.copyWith(tasks: data.tasks.map((item) => item.id == task.id ? item.copyWith(status: status) : item).toList());
    _prependActivity(_activity(status == 'Done' ? 'Task completed' : 'Task moved to $status', task.title, 'task', entityId: task.id, entityType: 'task'));
    _save();
  }

  void deleteTask(TaskItem task) {
    data = data.copyWith(tasks: data.tasks.where((item) => item.id != task.id).toList());
    _prependActivity(_activity('Task removed', task.title, 'task'));
    _save();
  }

  void saveRenewal(RenewalItem renewal) {
    final isNew = !data.renewals.any((item) => item.id == renewal.id);
    final renewals = isNew ? [renewal, ...data.renewals] : data.renewals.map((item) => item.id == renewal.id ? renewal : item).toList();
    data = data.copyWith(renewals: renewals);
    _prependActivity(_activity(isNew ? 'Renewal added' : 'Renewal updated', '${renewal.title} · ${renewal.category}', 'renewal', entityId: renewal.id, entityType: 'renewal'));
    _save();
  }

  void deleteRenewal(RenewalItem renewal) {
    data = data.copyWith(renewals: data.renewals.where((item) => item.id != renewal.id).toList());
    _prependActivity(_activity('Renewal removed', renewal.title, 'renewal'));
    _save();
  }

  void moveNode(String nodeId, double x, double y) {
    data = data.copyWith(nodes: data.nodes.map((node) => node.id == nodeId ? node.copyWith(x: x, y: y) : node).toList());
    _save();
  }

  void updateNode(MindNode node) {
    data = data.copyWith(nodes: data.nodes.map((item) => item.id == node.id ? node : item).toList());
    _save();
  }

  MindNode addNode({required String label, required String type, required String status, required String description, required String parentId}) {
    final node = MindNode(id: _uuid.v4(), label: label, type: type, status: status, description: description, x: 500 + (data.nodes.length % 4) * 105, y: 200 + (data.nodes.length % 3) * 125);
    final parent = data.nodes.where((item) => item.id == parentId).firstOrNull;
    final edge = MindEdge(id: _uuid.v4(), source: parent == null ? 'node-root' : parentId, target: node.id, label: parent?.type == 'Project' ? 'uses' : 'tracks');
    data = data.copyWith(nodes: [...data.nodes, node], edges: [...data.edges, edge]);
    _save();
    return node;
  }

  void deleteNode(MindNode node) {
    if (node.id == 'node-root') return;
    data = data.copyWith(nodes: data.nodes.where((item) => item.id != node.id).toList(), edges: data.edges.where((edge) => edge.source != node.id && edge.target != node.id).toList());
    _save();
  }

  void connectNodes(String source, String target, {String label = 'connected to'}) {
    if (source == target || data.edges.any((edge) => (edge.source == source && edge.target == target) || (edge.source == target && edge.target == source))) return;
    data = data.copyWith(edges: [...data.edges, MindEdge(id: _uuid.v4(), source: source, target: target, label: label)]);
    _save();
  }

  void disconnectNodes(String source, String target) {
    data = data.copyWith(edges: data.edges.where((edge) => !((edge.source == source && edge.target == target) || (edge.source == target && edge.target == source))).toList());
    _save();
  }

  void toggleCollapsed(MindNode node) {
    data = data.copyWith(nodes: data.nodes.map((item) => item.id == node.id ? item.copyWith(collapsed: !item.collapsed) : item).toList());
    _save();
  }

  void applyAutoLayout() {
    const centerX = 657.5;
    const centerY = 354.0;
    final others = data.nodes.where((node) => node.id != 'node-root').toList();
    final projects = others.where((node) => node.type == 'Project').toList();
    final remaining = others.where((node) => node.type != 'Project').toList();
    final positions = <String, Offset>{'node-root': const Offset(555, 315)};
    void arrange(List<MindNode> items, double radius, double initialAngle) {
      if (items.isEmpty) return;
      for (var i = 0; i < items.length; i++) {
        final angle = initialAngle + (i * 2 * math.pi / items.length);
        positions[items[i].id] = Offset(centerX + radius * math.cos(angle) - 94, centerY + radius * math.sin(angle) - 36);
      }
    }
    arrange(projects, 300, -math.pi / 2);
    arrange(remaining, 495, 0);
    data = data.copyWith(nodes: data.nodes.map((node) {
      final point = positions[node.id];
      return point == null ? node : node.copyWith(x: point.dx, y: point.dy);
    }).toList());
    _save();
  }

  void setTheme(String theme) { data = data.copyWith(theme: theme); _save(); }
  void setAccent(String accent) { data = data.copyWith(accent: accent); _save(); }
  void setAutoLockMinutes(int minutes) { data = data.copyWith(autoLockMinutes: minutes); _save(); }
  void markNotificationsRead(Iterable<String> ids) { data = data.copyWith(notificationsRead: {...data.notificationsRead, ...ids}.toList()); _save(); }

  Future<void> replaceWorkspace(WorkspaceData replacement) async {
    data = replacement;
    notifyListeners();
    await _persist();
  }

  Future<void> resetWorkspace() async {
    data = WorkspaceData.demo();
    notifyListeners();
    await _persist();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
