import 'package:flutter/material.dart';

String dateKey(DateTime value) => DateUtils.dateOnly(value).toIso8601String().split('T').first;
String dateAfter(int days) => dateKey(DateTime.now().add(Duration(days: days)));

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.status = 'Idea',
    this.priority = 'Medium',
    this.progress = 0,
    this.currentPhase = '',
    this.currentTask = '',
    this.nextAction = '',
    this.blockers = '',
    this.owner = 'You',
    this.startDate = '',
    this.targetDate = '',
    this.tags = const [],
    this.notes = '',
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String status;
  final String priority;
  final int progress;
  final String currentPhase;
  final String currentTask;
  final String nextAction;
  final String blockers;
  final String owner;
  final String startDate;
  final String targetDate;
  final List<String> tags;
  final String notes;

  ProjectItem copyWith({String? id, String? name, String? description, String? category, String? status, String? priority, int? progress, String? currentPhase, String? currentTask, String? nextAction, String? blockers, String? owner, String? startDate, String? targetDate, List<String>? tags, String? notes}) => ProjectItem(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    progress: progress ?? this.progress,
    currentPhase: currentPhase ?? this.currentPhase,
    currentTask: currentTask ?? this.currentTask,
    nextAction: nextAction ?? this.nextAction,
    blockers: blockers ?? this.blockers,
    owner: owner ?? this.owner,
    startDate: startDate ?? this.startDate,
    targetDate: targetDate ?? this.targetDate,
    tags: tags ?? this.tags,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description, 'category': category, 'status': status,
    'priority': priority, 'progress': progress, 'currentPhase': currentPhase, 'currentTask': currentTask,
    'nextAction': nextAction, 'blockers': blockers, 'owner': owner, 'startDate': startDate,
    'targetDate': targetDate, 'tags': tags, 'notes': notes,
  };

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
    id: json['id'] as String? ?? '', name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '', category: json['category'] as String? ?? '',
    status: json['status'] as String? ?? 'Idea', priority: json['priority'] as String? ?? 'Medium',
    progress: (json['progress'] as num?)?.round() ?? 0, currentPhase: json['currentPhase'] as String? ?? '',
    currentTask: json['currentTask'] as String? ?? '', nextAction: json['nextAction'] as String? ?? '',
    blockers: json['blockers'] as String? ?? '', owner: json['owner'] as String? ?? 'You',
    startDate: json['startDate'] as String? ?? '', targetDate: json['targetDate'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>? ?? const []).map((value) => value.toString()).toList(),
    notes: json['notes'] as String? ?? '',
  );
}

class AssetItem {
  const AssetItem({
    required this.id,
    required this.name,
    required this.type,
    this.status = 'Healthy',
    this.summary = '',
    this.projectId,
    this.tags = const [],
    this.fields = const {},
    this.updatedAt = '',
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final String summary;
  final String? projectId;
  final List<String> tags;
  final Map<String, String> fields;
  final String updatedAt;

  AssetItem copyWith({String? id, String? name, String? type, String? status, String? summary, String? projectId, bool clearProject = false, List<String>? tags, Map<String, String>? fields, String? updatedAt}) => AssetItem(
    id: id ?? this.id, name: name ?? this.name, type: type ?? this.type, status: status ?? this.status,
    summary: summary ?? this.summary, projectId: clearProject ? null : (projectId ?? this.projectId),
    tags: tags ?? this.tags, fields: fields ?? this.fields, updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type, 'status': status, 'summary': summary, 'projectId': projectId, 'tags': tags, 'fields': fields, 'updatedAt': updatedAt};
  factory AssetItem.fromJson(Map<String, dynamic> json) => AssetItem(
    id: json['id'] as String? ?? '', name: json['name'] as String? ?? '', type: json['type'] as String? ?? 'SaaS',
    status: json['status'] as String? ?? 'Healthy', summary: json['summary'] as String? ?? '', projectId: json['projectId'] as String?,
    tags: (json['tags'] as List<dynamic>? ?? const []).map((value) => value.toString()).toList(),
    fields: (json['fields'] as Map<String, dynamic>? ?? const {}).map((key, value) => MapEntry(key, value.toString())),
    updatedAt: json['updatedAt'] as String? ?? '',
  );
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'Todo',
    this.priority = 'Medium',
    this.dueDate = '',
    this.projectId,
    this.assetId,
    this.tags = const [],
    this.createdAt = '',
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String dueDate;
  final String? projectId;
  final String? assetId;
  final List<String> tags;
  final String createdAt;

  TaskItem copyWith({String? id, String? title, String? description, String? status, String? priority, String? dueDate, String? projectId, bool clearProject = false, String? assetId, bool clearAsset = false, List<String>? tags, String? createdAt}) => TaskItem(
    id: id ?? this.id, title: title ?? this.title, description: description ?? this.description,
    status: status ?? this.status, priority: priority ?? this.priority, dueDate: dueDate ?? this.dueDate,
    projectId: clearProject ? null : (projectId ?? this.projectId), assetId: clearAsset ? null : (assetId ?? this.assetId),
    tags: tags ?? this.tags, createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'status': status, 'priority': priority, 'dueDate': dueDate, 'projectId': projectId, 'assetId': assetId, 'tags': tags, 'createdAt': createdAt};
  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id'] as String? ?? '', title: json['title'] as String? ?? '', description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'Todo', priority: json['priority'] as String? ?? 'Medium', dueDate: json['dueDate'] as String? ?? '',
    projectId: json['projectId'] as String?, assetId: json['assetId'] as String?,
    tags: (json['tags'] as List<dynamic>? ?? const []).map((value) => value.toString()).toList(), createdAt: json['createdAt'] as String? ?? '',
  );
}

class RenewalItem {
  const RenewalItem({required this.id, required this.title, this.category = 'SaaS', this.dueDate = '', this.provider = '', this.amount = '', this.autoRenew = false, this.projectId, this.reminders = const [30, 14, 7, 3, 1]});
  final String id;
  final String title;
  final String category;
  final String dueDate;
  final String provider;
  final String amount;
  final bool autoRenew;
  final String? projectId;
  final List<int> reminders;

  RenewalItem copyWith({String? id, String? title, String? category, String? dueDate, String? provider, String? amount, bool? autoRenew, String? projectId, bool clearProject = false, List<int>? reminders}) => RenewalItem(
    id: id ?? this.id, title: title ?? this.title, category: category ?? this.category, dueDate: dueDate ?? this.dueDate,
    provider: provider ?? this.provider, amount: amount ?? this.amount, autoRenew: autoRenew ?? this.autoRenew,
    projectId: clearProject ? null : (projectId ?? this.projectId), reminders: reminders ?? this.reminders,
  );
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'category': category, 'dueDate': dueDate, 'provider': provider, 'amount': amount, 'autoRenew': autoRenew, 'projectId': projectId, 'reminders': reminders};
  factory RenewalItem.fromJson(Map<String, dynamic> json) => RenewalItem(
    id: json['id'] as String? ?? '', title: json['title'] as String? ?? '', category: json['category'] as String? ?? 'SaaS',
    dueDate: json['dueDate'] as String? ?? '', provider: json['provider'] as String? ?? '', amount: json['amount'] as String? ?? '',
    autoRenew: json['autoRenew'] as bool? ?? false, projectId: json['projectId'] as String?,
    reminders: (json['reminders'] as List<dynamic>? ?? const [30, 14, 7, 3, 1]).map((value) => (value as num).toInt()).toList(),
  );
}

class ActivityItem {
  const ActivityItem({required this.id, required this.title, this.detail = '', this.kind = 'system', this.entityId, this.entityType, required this.createdAt});
  final String id;
  final String title;
  final String detail;
  final String kind;
  final String? entityId;
  final String? entityType;
  final String createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'detail': detail, 'kind': kind, 'entityId': entityId, 'entityType': entityType, 'createdAt': createdAt};
  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(id: json['id'] as String? ?? '', title: json['title'] as String? ?? '', detail: json['detail'] as String? ?? '', kind: json['kind'] as String? ?? 'system', entityId: json['entityId'] as String?, entityType: json['entityType'] as String?, createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String());
}

class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    this.body = '',
    this.tags = const [],
    this.pinned = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final bool pinned;
  final String createdAt;
  final String updatedAt;

  NoteItem copyWith({String? id, String? title, String? body, List<String>? tags, bool? pinned, String? createdAt, String? updatedAt}) => NoteItem(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'tags': tags,
        'pinned': pinned,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>? ?? const []).map((value) => value.toString()).toList(),
        pinned: json['pinned'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}

class MindNode {
  const MindNode({required this.id, required this.label, required this.type, this.status = 'Healthy', this.description = '', this.projectId, this.assetId, required this.x, required this.y, this.collapsed = false});
  final String id;
  final String label;
  final String type;
  final String status;
  final String description;
  final String? projectId;
  final String? assetId;
  final double x;
  final double y;
  final bool collapsed;
  MindNode copyWith({String? id, String? label, String? type, String? status, String? description, String? projectId, bool clearProject = false, String? assetId, bool clearAsset = false, double? x, double? y, bool? collapsed}) => MindNode(
    id: id ?? this.id, label: label ?? this.label, type: type ?? this.type, status: status ?? this.status,
    description: description ?? this.description, projectId: clearProject ? null : (projectId ?? this.projectId),
    assetId: clearAsset ? null : (assetId ?? this.assetId), x: x ?? this.x, y: y ?? this.y, collapsed: collapsed ?? this.collapsed,
  );
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'type': type, 'status': status, 'description': description, 'projectId': projectId, 'assetId': assetId, 'x': x, 'y': y, 'collapsed': collapsed};
  factory MindNode.fromJson(Map<String, dynamic> json) => MindNode(
    id: json['id'] as String? ?? '', label: json['label'] as String? ?? '', type: json['type'] as String? ?? 'Project',
    status: json['status'] as String? ?? 'Healthy', description: json['description'] as String? ?? '',
    projectId: json['projectId'] as String?, assetId: json['assetId'] as String?,
    x: (json['x'] as num?)?.toDouble() ?? 0, y: (json['y'] as num?)?.toDouble() ?? 0, collapsed: json['collapsed'] as bool? ?? false,
  );
}

class MindEdge {
  const MindEdge({required this.id, required this.source, required this.target, this.label = ''});
  final String id;
  final String source;
  final String target;
  final String label;
  Map<String, dynamic> toJson() => {'id': id, 'source': source, 'target': target, 'label': label};
  factory MindEdge.fromJson(Map<String, dynamic> json) => MindEdge(id: json['id'] as String? ?? '', source: json['source'] as String? ?? '', target: json['target'] as String? ?? '', label: json['label'] as String? ?? '');
}

class WorkspaceData {
  const WorkspaceData({required this.projects, required this.assets, required this.tasks, required this.renewals, required this.activities, required this.nodes, required this.edges, this.notes = const [], this.notificationsRead = const [], this.theme = 'dark', this.accent = 'violet', this.autoLockMinutes = 5});
  final List<ProjectItem> projects;
  final List<AssetItem> assets;
  final List<TaskItem> tasks;
  final List<RenewalItem> renewals;
  final List<ActivityItem> activities;
  final List<NoteItem> notes;
  final List<MindNode> nodes;
  final List<MindEdge> edges;
  final List<String> notificationsRead;
  final String theme;
  final String accent;
  final int autoLockMinutes;

  WorkspaceData copyWith({List<ProjectItem>? projects, List<AssetItem>? assets, List<TaskItem>? tasks, List<RenewalItem>? renewals, List<ActivityItem>? activities, List<NoteItem>? notes, List<MindNode>? nodes, List<MindEdge>? edges, List<String>? notificationsRead, String? theme, String? accent, int? autoLockMinutes}) => WorkspaceData(
    projects: projects ?? this.projects, assets: assets ?? this.assets, tasks: tasks ?? this.tasks,
    renewals: renewals ?? this.renewals, activities: activities ?? this.activities, notes: notes ?? this.notes, nodes: nodes ?? this.nodes,
    edges: edges ?? this.edges, notificationsRead: notificationsRead ?? this.notificationsRead,
    theme: theme ?? this.theme, accent: accent ?? this.accent, autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
  );

  Map<String, dynamic> toJson() => {
    'projects': projects.map((item) => item.toJson()).toList(), 'assets': assets.map((item) => item.toJson()).toList(),
    'tasks': tasks.map((item) => item.toJson()).toList(), 'renewals': renewals.map((item) => item.toJson()).toList(),
    'activities': activities.map((item) => item.toJson()).toList(), 'notes': notes.map((item) => item.toJson()).toList(),
    'nodes': nodes.map((item) => item.toJson()).toList(),
    'edges': edges.map((item) => item.toJson()).toList(), 'notificationsRead': notificationsRead,
    'theme': theme, 'accent': accent, 'autoLockMinutes': autoLockMinutes,
  };

  factory WorkspaceData.fromJson(Map<String, dynamic> json) => WorkspaceData(
    projects: (json['projects'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(ProjectItem.fromJson).toList(),
    assets: (json['assets'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(AssetItem.fromJson).toList(),
    tasks: (json['tasks'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(TaskItem.fromJson).toList(),
    renewals: (json['renewals'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(RenewalItem.fromJson).toList(),
    activities: (json['activities'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(ActivityItem.fromJson).toList(),
    notes: (json['notes'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(NoteItem.fromJson).toList(),
    nodes: (json['nodes'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(MindNode.fromJson).toList(),
    edges: (json['edges'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().map(MindEdge.fromJson).toList(),
    notificationsRead: (json['notificationsRead'] as List<dynamic>? ?? []).map((value) => value.toString()).toList(),
    theme: json['theme'] as String? ?? 'dark', accent: json['accent'] as String? ?? 'violet',
    autoLockMinutes: (json['autoLockMinutes'] as num?)?.toInt() ?? 5,
  );

  factory WorkspaceData.demo() {
    final projects = <ProjectItem>[
      ProjectItem(id: 'project-digital-comrade', name: 'Digital Comrade', description: 'A calm, reliable home for the tools and systems behind the business.', category: 'Business platform', status: 'Development', priority: 'High', progress: 72, currentPhase: 'Development', currentTask: 'Polish the account workspace', nextAction: 'Review onboarding flow', owner: 'You', startDate: dateAfter(-62), targetDate: dateAfter(18), tags: const ['business', 'production', 'development'], notes: 'Keep the first launch focused on the essentials.'),
      ProjectItem(id: 'project-hospital-saas', name: 'Hospital SaaS', description: 'A lightweight operations platform for independent clinics.', category: 'Healthcare', status: 'Planning', priority: 'Medium', progress: 34, currentPhase: 'Planning', currentTask: 'Confirm the first clinic workflow', nextAction: 'Map the appointment journey', blockers: 'Waiting on two stakeholder interviews', owner: 'You', startDate: dateAfter(-17), targetDate: dateAfter(74), tags: const ['client', 'planning', 'healthcare']),
      ProjectItem(id: 'project-wa-crm', name: 'WhatsApp CRM', description: 'A compact lead inbox with thoughtful follow-up automation.', category: 'SaaS', status: 'Production', priority: 'Medium', progress: 91, currentPhase: 'Maintenance', currentTask: 'Monitor delivery health', nextAction: 'Review message delivery report', owner: 'You', startDate: dateAfter(-140), targetDate: dateAfter(30), tags: const ['business', 'production', 'customer-success']),
    ];
    final assets = <AssetItem>[
      AssetItem(id: 'asset-domain', name: 'digitalcomrade.in', type: 'Domain', status: 'Healthy', summary: 'Primary business domain and public website.', projectId: projects[0].id, tags: const ['production', 'business'], fields: {'Registrar': 'Cloudflare Registrar', 'DNS provider': 'Cloudflare', 'Expiry': dateAfter(128), 'Auto-renew': 'On', 'Nameservers': 'Cloudflare nameservers'}, updatedAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()),
      AssetItem(id: 'asset-github', name: 'digital-comrade / website', type: 'GitHub', status: 'Healthy', summary: 'Source repository for the public website.', projectId: projects[0].id, tags: const ['development', 'production'], fields: {'Organization': 'digital-comrade', 'Repository': 'website', 'Repository URL': 'https://github.com/digital-comrade/website', 'Branch': 'main', 'Deployment': 'Production'}, updatedAt: DateTime.now().subtract(const Duration(hours: 12)).toIso8601String()),
      AssetItem(id: 'asset-cloudflare', name: 'Cloudflare · digitalcomrade.in', type: 'Cloudflare', status: 'Healthy', summary: 'DNS, edge security and page delivery.', projectId: projects[0].id, tags: const ['production', 'infrastructure'], fields: {'Account': 'Personal workspace', 'Zone': 'digitalcomrade.in', 'DNS': 'Active', 'Workers': '1 worker', 'Pages': '1 deployment', 'R2': 'Not configured'}, updatedAt: DateTime.now().subtract(const Duration(hours: 22)).toIso8601String()),
      AssetItem(id: 'asset-server', name: 'cv-prod-01', type: 'VPS', status: 'Healthy', summary: 'Production application host. Sensitive connection details belong in Vault.', projectId: projects[0].id, tags: const ['server', 'production'], fields: {'Provider': 'Hetzner Cloud', 'OS': 'Ubuntu 24.04', 'Location': 'Helsinki', 'Plan': 'CX22', 'Purpose': 'Application services', 'IP reference': 'Stored in Vault'}, updatedAt: DateTime.now().subtract(const Duration(hours: 31)).toIso8601String()),
      AssetItem(id: 'asset-database', name: 'Primary database', type: 'Database', status: 'Healthy', summary: 'Managed PostgreSQL for application data.', projectId: projects[0].id, tags: const ['database', 'production'], fields: {'Provider': 'Supabase', 'Engine': 'PostgreSQL', 'Region': 'Asia Pacific', 'Purpose': 'Application data', 'Credentials': 'Stored in Vault'}, updatedAt: DateTime.now().subtract(const Duration(hours: 44)).toIso8601String()),
      AssetItem(id: 'asset-mail', name: 'Stalwart Mail', type: 'Email', status: 'Attention', summary: 'Transactional and team mail service; SPF review is due.', projectId: projects[0].id, tags: const ['email', 'review'], fields: {'Provider': 'Stalwart', 'Domain': 'digitalcomrade.in', 'Purpose': 'Transactional email', 'Next review': dateAfter(3)}, updatedAt: DateTime.now().subtract(const Duration(hours: 50)).toIso8601String()),
      AssetItem(id: 'asset-whatsapp-api', name: 'WhatsApp Business API', type: 'API', status: 'Healthy', summary: 'Messaging integration for the CRM workflow.', projectId: projects[2].id, tags: const ['api', 'production'], fields: {'Provider': 'Meta', 'Environment': 'Production', 'Secret reference': 'Stored in Vault'}, updatedAt: DateTime.now().subtract(const Duration(hours: 78)).toIso8601String()),
    ];
    final tasks = <TaskItem>[
      TaskItem(id: 'task-onboarding', title: 'Review onboarding flow', description: 'Check the first-run experience on desktop and mobile.', status: 'In Progress', priority: 'High', dueDate: dateAfter(1), projectId: projects[0].id, tags: const ['product', 'urgent'], createdAt: DateTime.now().subtract(const Duration(hours: 30)).toIso8601String()),
      TaskItem(id: 'task-spf', title: 'Verify SPF and DMARC records', description: 'Review mail authentication after the latest DNS update.', status: 'Todo', priority: 'High', dueDate: dateAfter(3), projectId: projects[0].id, assetId: 'asset-mail', tags: const ['email', 'infrastructure'], createdAt: DateTime.now().subtract(const Duration(hours: 20)).toIso8601String()),
      TaskItem(id: 'task-clinic', title: 'Map the appointment journey', description: 'Capture the front-desk workflow before the first prototype.', status: 'Todo', priority: 'Medium', dueDate: dateAfter(5), projectId: projects[1].id, tags: const ['research'], createdAt: DateTime.now().subtract(const Duration(hours: 10)).toIso8601String()),
      TaskItem(id: 'task-backup', title: 'Verify encrypted backup', description: 'Run a restore drill and check the exported archive.', status: 'Blocked', priority: 'Urgent', dueDate: dateAfter(-1), projectId: projects[0].id, tags: const ['security', 'backup'], createdAt: DateTime.now().subtract(const Duration(hours: 52)).toIso8601String()),
      TaskItem(id: 'task-report', title: 'Review delivery health report', description: 'Check the last seven days of message delivery.', status: 'Done', priority: 'Low', dueDate: dateAfter(-2), projectId: projects[2].id, tags: const ['operations'], createdAt: DateTime.now().subtract(const Duration(hours: 100)).toIso8601String()),
    ];
    final renewals = <RenewalItem>[
      RenewalItem(id: 'renewal-domain', title: 'digitalcomrade.in', category: 'Domain', dueDate: dateAfter(128), provider: 'Cloudflare Registrar', amount: '₹ 899 / year', autoRenew: true, projectId: projects[0].id),
      RenewalItem(id: 'renewal-vps', title: 'Production VPS', category: 'Hosting', dueDate: dateAfter(14), provider: 'Hetzner Cloud', amount: '€ 5.49 / month', autoRenew: true, projectId: projects[0].id, reminders: const [14, 7, 3, 1]),
      RenewalItem(id: 'renewal-figma', title: 'Figma Professional', category: 'SaaS', dueDate: dateAfter(7), provider: 'Figma', amount: '₹ 1,200 / month', autoRenew: false, projectId: projects[1].id, reminders: const [14, 7, 3, 1]),
    ];
    final nodes = <MindNode>[
      const MindNode(id: 'node-root', label: 'Comrade Vault', type: 'Workspace', status: 'Private workspace', description: 'Your digital ecosystem, connected in one calm command center.', x: 555, y: 315),
      MindNode(id: 'node-project-digital-comrade', label: projects[0].name, type: 'Project', status: projects[0].status, description: projects[0].description, projectId: projects[0].id, x: 285, y: 150),
      MindNode(id: 'node-asset-domain', label: 'digitalcomrade.in', type: 'Domain', status: 'Healthy', description: assets[0].summary, assetId: assets[0].id, projectId: projects[0].id, x: 860, y: 95),
      MindNode(id: 'node-asset-github', label: 'GitHub', type: 'GitHub', status: 'Healthy', description: assets[1].summary, assetId: assets[1].id, projectId: projects[0].id, x: 885, y: 310),
      MindNode(id: 'node-asset-cloudflare', label: 'Cloudflare', type: 'Cloudflare', status: 'Healthy', description: assets[2].summary, assetId: assets[2].id, projectId: projects[0].id, x: 550, y: 45),
      MindNode(id: 'node-asset-server', label: 'Production VPS', type: 'VPS', status: 'Healthy', description: assets[3].summary, assetId: assets[3].id, projectId: projects[0].id, x: 300, y: 470),
      MindNode(id: 'node-asset-database', label: 'Supabase', type: 'Database', status: 'Healthy', description: assets[4].summary, assetId: assets[4].id, projectId: projects[0].id, x: 585, y: 565),
      MindNode(id: 'node-asset-mail', label: 'Stalwart Mail', type: 'Email', status: 'Attention', description: assets[5].summary, assetId: assets[5].id, projectId: projects[0].id, x: 905, y: 535),
      MindNode(id: 'node-project-hospital-saas', label: projects[1].name, type: 'Project', status: projects[1].status, description: projects[1].description, projectId: projects[1].id, x: 1115, y: 220),
      MindNode(id: 'node-project-wa-crm', label: projects[2].name, type: 'Project', status: projects[2].status, description: projects[2].description, projectId: projects[2].id, x: 65, y: 125),
      MindNode(id: 'node-asset-whatsapp-api', label: 'WhatsApp API', type: 'API', status: 'Healthy', description: assets[6].summary, assetId: assets[6].id, projectId: projects[2].id, x: 75, y: 335),
    ];
    final edges = <MindEdge>[
      const MindEdge(id: 'edge-root-project', source: 'node-root', target: 'node-project-digital-comrade', label: 'owns'),
      const MindEdge(id: 'edge-root-domain', source: 'node-root', target: 'node-asset-domain', label: 'tracks'),
      const MindEdge(id: 'edge-root-github', source: 'node-root', target: 'node-asset-github', label: 'tracks'),
      const MindEdge(id: 'edge-root-cloudflare', source: 'node-root', target: 'node-asset-cloudflare', label: 'tracks'),
      const MindEdge(id: 'edge-root-server', source: 'node-root', target: 'node-asset-server', label: 'tracks'),
      const MindEdge(id: 'edge-root-db', source: 'node-root', target: 'node-asset-database', label: 'tracks'),
      const MindEdge(id: 'edge-root-mail', source: 'node-root', target: 'node-asset-mail', label: 'tracks'),
      const MindEdge(id: 'edge-root-hospital', source: 'node-root', target: 'node-project-hospital-saas', label: 'owns'),
      const MindEdge(id: 'edge-root-crm', source: 'node-root', target: 'node-project-wa-crm', label: 'owns'),
      const MindEdge(id: 'edge-root-api', source: 'node-root', target: 'node-asset-whatsapp-api', label: 'tracks'),
      const MindEdge(id: 'edge-project-api', source: 'node-project-wa-crm', target: 'node-asset-whatsapp-api', label: 'integrates'),
      const MindEdge(id: 'edge-project-domain', source: 'node-project-digital-comrade', target: 'node-asset-domain', label: 'uses'),
      const MindEdge(id: 'edge-project-github', source: 'node-project-digital-comrade', target: 'node-asset-github', label: 'ships from'),
      const MindEdge(id: 'edge-project-cf', source: 'node-project-digital-comrade', target: 'node-asset-cloudflare', label: 'delivered by'),
      const MindEdge(id: 'edge-project-server', source: 'node-project-digital-comrade', target: 'node-asset-server', label: 'runs on'),
      const MindEdge(id: 'edge-server-db', source: 'node-asset-server', target: 'node-asset-database', label: 'connects to'),
      const MindEdge(id: 'edge-project-mail', source: 'node-project-digital-comrade', target: 'node-asset-mail', label: 'uses'),
    ];
    final now = DateTime.now();
    final activities = <ActivityItem>[
      ActivityItem(id: 'activity-1', title: 'SPF review flagged', detail: 'Stalwart Mail · Digital Comrade', kind: 'security', entityId: assets[5].id, entityType: 'asset', createdAt: now.subtract(const Duration(hours: 2)).toIso8601String()),
      ActivityItem(id: 'activity-2', title: 'Task moved to In Progress', detail: 'Review onboarding flow · Digital Comrade', kind: 'task', entityId: tasks[0].id, entityType: 'task', createdAt: now.subtract(const Duration(hours: 6)).toIso8601String()),
      ActivityItem(id: 'activity-3', title: 'Repository linked', detail: 'digital-comrade / website · Digital Comrade', kind: 'asset', entityId: assets[1].id, entityType: 'asset', createdAt: now.subtract(const Duration(hours: 19)).toIso8601String()),
      ActivityItem(id: 'activity-4', title: 'Project phase updated', detail: 'Digital Comrade · Development', kind: 'project', entityId: projects[0].id, entityType: 'project', createdAt: now.subtract(const Duration(hours: 42)).toIso8601String()),
      ActivityItem(id: 'activity-5', title: 'Backup review reminder created', detail: 'Sample workspace activity · This device', kind: 'system', createdAt: now.subtract(const Duration(hours: 72)).toIso8601String()),
    ];
    final notes = <NoteItem>[
      NoteItem(id: 'note-weekly-reset', title: 'Weekly reset', body: 'Review active projects, choose one next action for each, and clear tasks that no longer matter.', tags: const ['planning', 'weekly'], pinned: true, createdAt: now.subtract(const Duration(days: 2)).toIso8601String(), updatedAt: now.subtract(const Duration(hours: 5)).toIso8601String()),
      NoteItem(id: 'note-infrastructure', title: 'Infrastructure follow-ups', body: 'Check mail authentication after the SPF update. Confirm backup restoration before the next release.', tags: const ['operations', 'infrastructure'], createdAt: now.subtract(const Duration(days: 5)).toIso8601String(), updatedAt: now.subtract(const Duration(days: 1)).toIso8601String()),
      NoteItem(id: 'note-product-principles', title: 'Product principles', body: 'Keep the first-run experience calm. Prefer clear defaults, reversible actions, and local-first privacy.', tags: const ['product', 'ideas'], createdAt: now.subtract(const Duration(days: 9)).toIso8601String(), updatedAt: now.subtract(const Duration(days: 4)).toIso8601String()),
    ];
    return WorkspaceData(projects: projects, assets: assets, tasks: tasks, renewals: renewals, activities: activities, notes: notes, nodes: nodes, edges: edges);
  }
}
