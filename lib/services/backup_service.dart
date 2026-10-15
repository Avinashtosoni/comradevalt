import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../app_controller.dart';
import '../models.dart';
import 'vault_service.dart';

class BackupContents {
  const BackupContents({required this.workspace, required this.encryptedVault});
  final WorkspaceData workspace;
  final Map<String, dynamic>? encryptedVault;
}

class BackupService {
  static Future<void> exportFullBackup(AppController app, VaultService vault) async {
    final payload = <String, dynamic>{
      'format': 'comrade-vault-backup',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'workspace': app.data.toJson(),
      'encryptedVault': vault.encryptedExport(),
      'securityNote': 'Workspace metadata, including Notes, is stored in readable form. Only the Vault snapshot is AES-256-GCM encrypted; the master passphrase is not included.',
    };
    await _shareJson(payload, 'comrade-vault-backup.json', 'Comrade Vault backup · workspace readable, Vault encrypted');
  }

  static Future<void> exportCsv(AppController app) async {
    final csv = buildCsv(app.data);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv', name: 'comrade-vault-export.csv')],
      text: 'Comrade Vault CSV · notes and Vault contents excluded',
      fileNameOverrides: const ['comrade-vault-export.csv'],
    );
  }

  static String buildCsv(WorkspaceData workspace) {
    final rows = <List<String>>[
      ['type', 'name', 'status', 'category', 'project', 'tags', 'description', 'date'],
      ...workspace.projects.map((item) => ['Project', item.name, item.status, item.category, '', item.tags.join('|'), item.description, item.targetDate]),
      ...workspace.assets.map((item) => ['Asset', item.name, item.status, item.type, workspace.projects.where((project) => project.id == item.projectId).firstOrNull?.name ?? '', item.tags.join('|'), item.summary, item.updatedAt]),
      ...workspace.tasks.map((item) => ['Task', item.title, item.status, item.priority, workspace.projects.where((project) => project.id == item.projectId).firstOrNull?.name ?? '', item.tags.join('|'), item.description, item.dueDate]),
      ...workspace.renewals.map((item) => ['Renewal', item.title, item.category, item.autoRenew ? 'Auto-renew' : 'Manual', workspace.projects.where((project) => project.id == item.projectId).firstOrNull?.name ?? '', '', item.provider, item.dueDate]),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  static String _csvCell(String value) {
    final cleaned = value.replaceAll('"', '""').replaceAll('\r', ' ').replaceAll('\n', ' ');
    // Quoting protects CSV structure; the apostrophe also prevents spreadsheet formula execution.
    final safe = RegExp(r'^[\t ]*[=+\-@]').hasMatch(cleaned) ? "'$cleaned" : cleaned;
    return '"$safe"';
  }

  static Future<void> exportEncryptedVault(VaultService vault) async {
    final payload = <String, dynamic>{
      'format': 'comrade-vault-encrypted-archive',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'encryptedVault': vault.encryptedExport(),
      'securityNote': 'This archive contains encrypted Vault values only. Use your master passphrase on a trusted device to unlock it.',
    };
    await _shareJson(payload, 'comrade-vault-encrypted.json', 'Encrypted Vault archive');
  }

  static Future<void> _shareJson(Map<String, dynamic> payload, String name, String text) async {
    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)));
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/json', name: name)],
      text: text,
      fileNameOverrides: [name],
    );
  }

  static Future<BackupContents?> pickWorkspaceBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['json'], withData: true, allowMultiple: false);
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) throw const FormatException('This file could not be read in the current browser.');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || decoded['format'] != 'comrade-vault-backup' || decoded['version'] != 1 || decoded['workspace'] is! Map) {
      throw const FormatException('This is not a supported Comrade Vault backup.');
    }
    final encrypted = decoded['encryptedVault'];
    return BackupContents(
      workspace: WorkspaceData.fromJson(Map<String, dynamic>.from(decoded['workspace'] as Map)),
      encryptedVault: encrypted is Map ? Map<String, dynamic>.from(encrypted) : null,
    );
  }

  static Future<Map<String, dynamic>?> pickEncryptedVaultArchive() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['json'], withData: true, allowMultiple: false);
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) throw const FormatException('This file could not be read in the current browser.');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) throw const FormatException('This is not a supported backup.');
    if (decoded['format'] == 'comrade-vault-backup' && decoded['workspace'] is Map) {
      final archive = decoded['encryptedVault'];
      return archive is Map ? Map<String, dynamic>.from(archive) : null;
    }
    if (decoded['format'] == 'comrade-vault-encrypted-archive') {
      final archive = decoded['encryptedVault'];
      if (archive == null) throw const FormatException('This archive does not contain a vault.');
      if (archive is! Map) throw const FormatException('The encrypted vault archive is invalid.');
      return Map<String, dynamic>.from(archive);
    }
    throw const FormatException('This is not a supported encrypted Vault backup.');
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
