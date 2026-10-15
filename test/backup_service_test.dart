import 'package:flutter_test/flutter_test.dart';

import 'package:comrade_vault/models.dart';
import 'package:comrade_vault/services/backup_service.dart';

void main() {
  group('CSV metadata export', () {
    test('escapes CSV structure and neutralizes spreadsheet formulas', () {
      final workspace = WorkspaceData(
        projects: const [
          ProjectItem(
            id: 'p-1',
            name: '=HYPERLINK("https://example.invalid","open")',
            description: 'First line\nSecond line',
          ),
        ],
        assets: const [],
        tasks: const [],
        renewals: const [],
        activities: const [],
        nodes: const [],
        edges: const [],
      );

      final csv = BackupService.buildCsv(workspace);

      expect(csv, contains("\"'=HYPERLINK("));
      expect(csv, isNot(contains('"=HYPERLINK(')));
      expect(csv, contains('First line Second line'));
      expect(csv, contains('"type","name","status","category","project","tags","description","date"'));
    });

    test('exports project, asset, task and renewal metadata without adding Vault rows', () {
      final project = const ProjectItem(id: 'project', name: 'Workspace project');
      final workspace = WorkspaceData(
        projects: [project],
        assets: const [AssetItem(id: 'asset', name: 'example.com', type: 'Domain', projectId: 'project')],
        tasks: const [TaskItem(id: 'task', title: 'Review DNS', projectId: 'project')],
        renewals: const [RenewalItem(id: 'renewal', title: 'Domain renewal', projectId: 'project')],
        activities: const [],
        notes: const [NoteItem(id: 'note', title: 'Private note title', body: 'A private note body.')],
        nodes: const [],
        edges: const [],
      );

      final csv = BackupService.buildCsv(workspace);

      expect(csv, contains('"Project","Workspace project"'));
      expect(csv, contains('"Asset","example.com"'));
      expect(csv, contains('"Task","Review DNS"'));
      expect(csv, contains('"Renewal","Domain renewal"'));
      expect(csv.toLowerCase(), isNot(contains('vault')));
      expect(csv, isNot(contains('Private note title')));
      expect(csv, isNot(contains('A private note body.')));
    });
  });
}
