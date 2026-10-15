import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';

const _uuid = Uuid();
const _projectStatuses = ['Idea', 'Planning', 'Design', 'Development', 'Testing', 'Staging', 'Production', 'Maintenance', 'Paused', 'Archived'];
const _priorities = ['Low', 'Medium', 'High', 'Urgent'];
const _assetTypes = ['Domain', 'GitHub', 'Cloudflare', 'Server', 'VPS', 'Hosting', 'Database', 'API', 'SaaS', 'Social Account', 'Email', 'Payment Gateway', 'Storage', 'Device', 'Document'];
const _assetStatuses = ['Healthy', 'Attention', 'Offline', 'Archived'];
const _taskStatuses = ['Todo', 'In Progress', 'Blocked', 'Done'];
const _renewalCategories = ['Domain', 'SSL', 'Hosting', 'VPS', 'SaaS', 'API', 'License', 'Cloud service', 'Other'];

Future<void> showProjectEditor(BuildContext context, AppController controller, [ProjectItem? existing]) => showDialog<void>(context: context, builder: (_) => _ProjectEditor(controller: controller, existing: existing));
Future<void> showAssetEditor(BuildContext context, AppController controller, [AssetItem? existing, String? type]) => showDialog<void>(context: context, builder: (_) => _AssetEditor(controller: controller, existing: existing, initialType: type));
Future<void> showTaskEditor(BuildContext context, AppController controller, [TaskItem? existing, String initialStatus = 'Todo']) => showDialog<void>(context: context, builder: (_) => _TaskEditor(controller: controller, existing: existing, initialStatus: initialStatus));
Future<void> showRenewalEditor(BuildContext context, AppController controller, [RenewalItem? existing]) => showDialog<void>(context: context, builder: (_) => _RenewalEditor(controller: controller, existing: existing));

class _ProjectEditor extends StatefulWidget {
  const _ProjectEditor({required this.controller, this.existing});
  final AppController controller;
  final ProjectItem? existing;
  @override
  State<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<_ProjectEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _next;
  late final TextEditingController _blockers;
  late final TextEditingController _tags;
  late final TextEditingController _notes;
  late String _status;
  late String _priority;
  late DateTime _startDate;
  DateTime? _targetDate;
  late double _progress;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _name = TextEditingController(text: item?.name ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _category = TextEditingController(text: item?.category ?? '');
    _next = TextEditingController(text: item?.nextAction ?? '');
    _blockers = TextEditingController(text: item?.blockers ?? '');
    _tags = TextEditingController(text: item?.tags.join(', ') ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
    _status = item?.status ?? 'Idea';
    _priority = item?.priority ?? 'Medium';
    _progress = (item?.progress ?? 0).toDouble();
    _startDate = _parseDate(item?.startDate) ?? DateUtils.dateOnly(DateTime.now());
    _targetDate = _parseDate(item?.targetDate);
  }

  @override
  void dispose() {
    _name.dispose(); _description.dispose(); _category.dispose(); _next.dispose(); _blockers.dispose(); _tags.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseDate(bool target) async {
    final value = await showDatePicker(context: context, initialDate: target ? (_targetDate ?? DateTime.now()) : _startDate, firstDate: DateTime(2018), lastDate: DateTime(2100));
    if (value == null || !mounted) return;
    setState(() { if (target) _targetDate = value; else _startDate = value; });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = ProjectItem(
      id: widget.existing?.id ?? 'project-${_uuid.v4()}', name: _name.text.trim(), description: _description.text.trim(),
      category: _category.text.trim(), status: _status, priority: _priority, progress: _progress.round(), currentPhase: _status,
      currentTask: widget.existing?.currentTask ?? '', nextAction: _next.text.trim(), blockers: _blockers.text.trim(),
      owner: widget.existing?.owner ?? 'You', startDate: dateKey(_startDate), targetDate: _targetDate == null ? '' : dateKey(_targetDate!),
      tags: _parseTags(_tags.text), notes: _notes.text.trim(),
    );
    widget.controller.saveProject(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorDialog(
    eyebrow: 'PROJECT DETAILS', title: widget.existing == null ? 'Create a project' : 'Edit project',
    subtitle: 'Set the context, then connect the tools that bring it to life.',
    content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      _TextField(controller: _name, label: 'Project name', hint: 'e.g. Website refresh', required: true, autofocus: true),
      _TextField(controller: _description, label: 'Description', hint: 'What are you building, and why?', maxLines: 3),
      Row(children: [Expanded(child: _TextField(controller: _category, label: 'Category', hint: 'Product, client work…')), const SizedBox(width: 12), Expanded(child: _DropdownField(label: 'Status', value: _status, options: _projectStatuses, onChanged: (value) => setState(() => _status = value))) ]),
      Row(children: [Expanded(child: _DropdownField(label: 'Priority', value: _priority, options: _priorities, onChanged: (value) => setState(() => _priority = value))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _FieldLabel('Progress'), Row(children: [Expanded(child: Slider(value: _progress, min: 0, max: 100, divisions: 20, onChanged: (value) => setState(() => _progress = value))), Text('${_progress.round()}%', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 11))])]))]),
      Row(children: [Expanded(child: _DateField(label: 'Start date', value: _startDate, onTap: () => _chooseDate(false))), const SizedBox(width: 12), Expanded(child: _DateField(label: 'Target date', value: _targetDate, onTap: () => _chooseDate(true))) ]),
      Row(children: [Expanded(child: _TextField(controller: _next, label: 'Next action', hint: 'The next meaningful step')), const SizedBox(width: 12), Expanded(child: _TextField(controller: _blockers, label: 'Blockers', hint: 'None'))]),
      _TextField(controller: _tags, label: 'Tags', hint: 'business, launch, client'),
      _TextField(controller: _notes, label: 'Notes', hint: 'Internal notes', maxLines: 2),
    ])),
    onSave: _save,
  );
}

class _AssetEditor extends StatefulWidget {
  const _AssetEditor({required this.controller, this.existing, this.initialType});
  final AppController controller;
  final AssetItem? existing;
  final String? initialType;
  @override
  State<_AssetEditor> createState() => _AssetEditorState();
}

class _AssetEditorState extends State<_AssetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _summary;
  late final TextEditingController _tags;
  late String _type;
  late String _status;
  String _projectId = '';
  late Map<String, String> _fields;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _type = item?.type ?? widget.initialType ?? 'Domain';
    _status = item?.status ?? 'Healthy';
    _name = TextEditingController(text: item?.name ?? '');
    _summary = TextEditingController(text: item?.summary ?? '');
    _tags = TextEditingController(text: item?.tags.join(', ') ?? '');
    _projectId = item?.projectId ?? '';
    _fields = Map<String, String>.from(item?.fields ?? const {});
  }

  @override
  void dispose() { _name.dispose(); _summary.dispose(); _tags.dispose(); super.dispose(); }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    widget.controller.saveAsset(AssetItem(
      id: widget.existing?.id ?? 'asset-${_uuid.v4()}', name: _name.text.trim(), type: _type, status: _status,
      summary: _summary.text.trim(), projectId: _projectId.isEmpty ? null : _projectId,
      tags: _parseTags(_tags.text), fields: Map<String, String>.from(_fields), updatedAt: DateTime.now().toIso8601String(),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fieldNames = _fieldsFor(_type);
    return _EditorDialog(
      eyebrow: 'DIGITAL ASSET', title: widget.existing == null ? 'Connect an asset' : 'Edit asset',
      subtitle: 'Add the details you need to understand and manage this service.',
      content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: VaultColors.cyan.withOpacity(.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: VaultColors.cyan.withOpacity(.17))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.shield_outlined, size: 17, color: VaultColors.cyan), const SizedBox(width: 9), Expanded(child: Text('Keep passwords, API keys and private IPs in Vault. Asset notes are not encrypted.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VaultColors.cyan, height: 1.45)))])),
        Row(children: [Expanded(child: _TextField(controller: _name, label: 'Asset name', hint: _type == 'Domain' ? 'example.com' : 'Name this asset', required: true, autofocus: true)), const SizedBox(width: 12), Expanded(child: _DropdownField(label: 'Type', value: _type, options: _assetTypes, onChanged: (value) => setState(() { _type = value; _fields = {}; }))) ]),
        _TextField(controller: _summary, label: 'Description', hint: 'What does this asset do?', maxLines: 2),
        Row(children: [Expanded(child: _DropdownField(label: 'Status', value: _status, options: _assetStatuses, onChanged: (value) => setState(() => _status = value))), const SizedBox(width: 12), Expanded(child: _DropdownField(label: 'Related project', value: _projectId, options: ['', ...widget.controller.data.projects.map((item) => item.id)], labels: {'': 'No project', for (final project in widget.controller.data.projects) project.id: project.name}, onChanged: (value) => setState(() => _projectId = value))) ]),
        Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(top: 3, bottom: 6), child: Row(children: [const _FieldLabel('Asset details'), const SizedBox(width: 7), _TinyPill(_type)]))),
        ...fieldNames.map((field) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(initialValue: _fields[field] ?? '', onSaved: (value) => _fields[field] = value?.trim() ?? '', decoration: InputDecoration(labelText: field, hintText: field.toLowerCase().contains('reference') || field.toLowerCase().contains('credential') ? 'Reference in Vault' : field)))),
        _TextField(controller: _tags, label: 'Tags', hint: 'production, business'),
      ])),
      onSave: _save,
    );
  }
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.controller, this.existing, this.initialStatus = 'Todo'});
  final AppController controller;
  final TaskItem? existing;
  final String initialStatus;
  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  late String _status;
  late String _priority;
  late String _projectId;
  late String _assetId;
  DateTime _dueDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    final task = widget.existing;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _tags = TextEditingController(text: task?.tags.join(', ') ?? '');
    _status = task?.status ?? widget.initialStatus; _priority = task?.priority ?? 'Medium';
    _projectId = task?.projectId ?? ''; _assetId = task?.assetId ?? '';
    _dueDate = _parseDate(task?.dueDate) ?? DateUtils.dateOnly(DateTime.now());
  }
  @override
  void dispose() { _title.dispose(); _description.dispose(); _tags.dispose(); super.dispose(); }
  Future<void> _pickDate() async { final date = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2018), lastDate: DateTime(2100)); if (date != null && mounted) setState(() => _dueDate = date); }
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.saveTask(TaskItem(id: widget.existing?.id ?? 'task-${_uuid.v4()}', title: _title.text.trim(), description: _description.text.trim(), status: _status, priority: _priority, dueDate: dateKey(_dueDate), projectId: _projectId.isEmpty ? null : _projectId, assetId: _assetId.isEmpty ? null : _assetId, tags: _parseTags(_tags.text), createdAt: widget.existing?.createdAt ?? DateTime.now().toIso8601String()));
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) => _EditorDialog(
    eyebrow: 'TASK DETAILS', title: widget.existing == null ? 'Create a task' : 'Edit task', subtitle: 'A clear next step makes the bigger picture easier.',
    content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      _TextField(controller: _title, label: 'Task title', hint: 'What needs to happen?', required: true, autofocus: true),
      _TextField(controller: _description, label: 'Notes', hint: 'Add a little context', maxLines: 3),
      Row(children: [Expanded(child: _DropdownField(label: 'Status', value: _status, options: _taskStatuses, onChanged: (value) => setState(() => _status = value))), const SizedBox(width: 12), Expanded(child: _DropdownField(label: 'Priority', value: _priority, options: _priorities, onChanged: (value) => setState(() => _priority = value))) ]),
      Row(children: [Expanded(child: _DateField(label: 'Due date', value: _dueDate, onTap: _pickDate)), const SizedBox(width: 12), Expanded(child: _DropdownField(label: 'Project', value: _projectId, options: ['', ...widget.controller.data.projects.map((item) => item.id)], labels: {'': 'No project', for (final item in widget.controller.data.projects) item.id: item.name}, onChanged: (value) => setState(() => _projectId = value))) ]),
      _DropdownField(label: 'Related asset', value: _assetId, options: ['', ...widget.controller.data.assets.map((item) => item.id)], labels: {'': 'No asset', for (final item in widget.controller.data.assets) item.id: item.name}, onChanged: (value) => setState(() => _assetId = value)),
      _TextField(controller: _tags, label: 'Tags', hint: 'urgent, client'),
    ])),
    onSave: _save,
  );
}

class _RenewalEditor extends StatefulWidget {
  const _RenewalEditor({required this.controller, this.existing});
  final AppController controller;
  final RenewalItem? existing;
  @override
  State<_RenewalEditor> createState() => _RenewalEditorState();
}

class _RenewalEditorState extends State<_RenewalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _provider;
  late final TextEditingController _amount;
  late String _category;
  late String _projectId;
  late bool _autoRenew;
  late List<int> _reminders;
  DateTime _dueDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? ''); _provider = TextEditingController(text: item?.provider ?? ''); _amount = TextEditingController(text: item?.amount ?? '');
    _category = item?.category ?? 'Domain'; _projectId = item?.projectId ?? ''; _autoRenew = item?.autoRenew ?? false; _reminders = List<int>.from(item?.reminders ?? [30, 14, 7, 3, 1]);
    _dueDate = _parseDate(item?.dueDate) ?? DateUtils.dateOnly(DateTime.now());
  }
  @override
  void dispose() { _title.dispose(); _provider.dispose(); _amount.dispose(); super.dispose(); }
  Future<void> _pickDate() async { final date = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2018), lastDate: DateTime(2100)); if (date != null && mounted) setState(() => _dueDate = date); }
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.saveRenewal(RenewalItem(id: widget.existing?.id ?? 'renewal-${_uuid.v4()}', title: _title.text.trim(), category: _category, dueDate: dateKey(_dueDate), provider: _provider.text.trim(), amount: _amount.text.trim(), autoRenew: _autoRenew, projectId: _projectId.isEmpty ? null : _projectId, reminders: _reminders));
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) => _EditorDialog(
    eyebrow: 'RENEWAL TRACKER', title: widget.existing == null ? 'Track a renewal' : 'Edit renewal', subtitle: 'Set a date and reminder rhythm that works for you.',
    content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      _TextField(controller: _title, label: 'Renewal name', hint: 'e.g. domain or subscription', required: true, autofocus: true),
      Row(children: [Expanded(child: _DropdownField(label: 'Category', value: _category, options: _renewalCategories, onChanged: (value) => setState(() => _category = value))), const SizedBox(width: 12), Expanded(child: _DateField(label: 'Renewal date', value: _dueDate, onTap: _pickDate)) ]),
      Row(children: [Expanded(child: _TextField(controller: _provider, label: 'Provider', hint: 'Service or registrar')), const SizedBox(width: 12), Expanded(child: _TextField(controller: _amount, label: 'Cost', hint: 'Optional'))]),
      _DropdownField(label: 'Related project', value: _projectId, options: ['', ...widget.controller.data.projects.map((item) => item.id)], labels: {'': 'No project', for (final project in widget.controller.data.projects) project.id: project.name}, onChanged: (value) => setState(() => _projectId = value)),
      SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Auto-renews', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), subtitle: const Text('This subscription is set to renew automatically', style: TextStyle(fontSize: 10)), value: _autoRenew, onChanged: (value) => setState(() => _autoRenew = value)),
      Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 2), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _FieldLabel('Remind me'), const SizedBox(height: 8), Wrap(spacing: 7, children: [30, 14, 7, 3, 1].map((days) => FilterChip(label: Text('$days days'), selected: _reminders.contains(days), onSelected: (selected) => setState(() { if (selected) { _reminders.add(days); } else { _reminders.remove(days); } _reminders.sort((a, b) => b.compareTo(a)); }), visualDensity: VisualDensity.compact)).toList())]))),
    ])),
    onSave: _save,
  );
}

class _EditorDialog extends StatelessWidget {
  const _EditorDialog({required this.eyebrow, required this.title, required this.subtitle, required this.content, required this.onSave});
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Theme.of(context).colorScheme.surface,
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: Theme.of(context).dividerColor)),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.fromLTRB(22, 20, 16, 16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 1.3)), const SizedBox(height: 5), Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])), IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, size: 19))])),
      Divider(height: 1, color: Theme.of(context).dividerColor),
      Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 4), child: content)),
      Divider(height: 1, color: Theme.of(context).dividerColor),
      Padding(padding: const EdgeInsets.fromLTRB(18, 13, 18, 14), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')), const SizedBox(width: 9), FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.check_rounded, size: 16), label: Text(title.startsWith('Create') || title.startsWith('Connect') || title.startsWith('Track') ? 'Save' : 'Save changes'))])),
    ])),
  );
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller, required this.label, this.hint, this.maxLines = 1, this.required = false, this.autofocus = false});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool required;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: TextFormField(controller: controller, autofocus: autofocus, maxLines: maxLines, validator: required ? (value) => value == null || value.trim().isEmpty ? '$label is required' : null : null, decoration: InputDecoration(labelText: required ? '$label *' : label, hintText: hint)));
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label, required this.value, required this.options, required this.onChanged, this.labels = const {}});
  final String label;
  final String value;
  final List<String> options;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: DropdownButtonFormField<String>(value: options.contains(value) ? value : options.first, isExpanded: true, decoration: InputDecoration(labelText: label), items: options.map((item) => DropdownMenuItem(value: item, child: Text(labels[item] ?? item, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (selected) { if (selected != null) onChanged(selected); }));
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month_rounded, size: 17)), child: Text(value == null ? 'Select date' : MaterialLocalizations.of(context).formatMediumDate(value!), style: TextStyle(fontSize: 12, color: value == null ? VaultColors.muted : Theme.of(context).colorScheme.onSurface)))));
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(value, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? VaultColors.muted : const Color(0xFF6D7182), fontSize: 10.5, fontWeight: FontWeight.w700));
}

class _TinyPill extends StatelessWidget {
  const _TinyPill(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), borderRadius: BorderRadius.circular(6)), child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w700)));
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try { return DateTime.parse(value); } catch (_) { return null; }
}

List<String> _parseTags(String value) => value.split(',').map((tag) => tag.trim().replaceFirst(RegExp(r'^#'), '')).where((tag) => tag.isNotEmpty).toSet().toList();

List<String> _fieldsFor(String type) => switch (type) {
  'Domain' => ['Registrar', 'DNS provider', 'Expiry', 'Auto-renew', 'Nameservers'],
  'GitHub' => ['Organization', 'Repository', 'Repository URL', 'Branch', 'Deployment'],
  'Cloudflare' => ['Account', 'Zone', 'DNS', 'Workers', 'Pages', 'R2'],
  'Server' || 'VPS' || 'Hosting' => ['Provider', 'Server name', 'IP reference', 'OS', 'Location', 'Plan', 'Purpose'],
  'Database' => ['Provider', 'Engine', 'Region', 'Purpose', 'Credentials'],
  'API' => ['Provider', 'Environment', 'Base URL', 'Secret reference'],
  'SaaS' => ['Provider', 'Plan', 'Account', 'Renewal date'],
  'Social Account' => ['Platform', 'Handle', 'Profile URL', 'Owner'],
  'Email' => ['Provider', 'Domain', 'Purpose', 'Next review'],
  'Payment Gateway' => ['Provider', 'Environment', 'Merchant reference', 'Secret reference'],
  'Storage' => ['Provider', 'Bucket', 'Region', 'Purpose'],
  'Device' => ['Manufacturer', 'Model', 'Serial reference', 'Owner'],
  'Document' => ['File type', 'Location', 'Version'],
  _ => ['Provider', 'Reference'],
};
