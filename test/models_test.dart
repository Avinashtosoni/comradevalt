import 'package:flutter_test/flutter_test.dart';

import 'package:comrade_vault/models.dart';

void main() {
  group('workspace models', () {
    test('demo workspace survives a JSON round trip', () {
      final original = WorkspaceData.demo();
      final restored = WorkspaceData.fromJson(original.toJson());

      expect(restored.toJson(), equals(original.toJson()));
      expect(restored.notes, hasLength(3));
    });

    test('empty and partial backups receive safe defaults', () {
      final workspace = WorkspaceData.fromJson(const {});
      final project = ProjectItem.fromJson(const {});
      final task = TaskItem.fromJson(const {});
      final renewal = RenewalItem.fromJson(const {});

      expect(workspace.projects, isEmpty);
      expect(workspace.assets, isEmpty);
      expect(workspace.tasks, isEmpty);
      expect(workspace.notes, isEmpty);
      expect(workspace.nodes, isEmpty);
      expect(project.status, 'Idea');
      expect(task.status, 'Todo');
      expect(renewal.reminders, [30, 14, 7, 3, 1]);
    });

    test('notes preserve content, tags, pin state and timestamps in JSON', () {
      final note = NoteItem(
        id: 'note-1',
        title: 'Release notes',
        body: 'Review the launch checklist.',
        tags: const ['launch', 'review'],
        pinned: true,
        createdAt: '2026-10-01T12:00:00.000Z',
        updatedAt: '2026-10-12T08:30:00.000Z',
      );
      final restored = NoteItem.fromJson(note.toJson());

      expect(restored.toJson(), equals(note.toJson()));
      expect(note.copyWith(pinned: false).pinned, isFalse);
      expect(note.copyWith(tags: const ['done']).tags, ['done']);
    });

    test('nullable links can be explicitly cleared with copyWith', () {
      final asset = const AssetItem(id: 'a', name: 'Asset', type: 'Domain', projectId: 'p');
      final task = const TaskItem(id: 't', title: 'Task', projectId: 'p', assetId: 'a');
      final renewal = const RenewalItem(id: 'r', title: 'Renewal', projectId: 'p');
      final node = const MindNode(id: 'n', label: 'Node', type: 'Project', projectId: 'p', assetId: 'a', x: 10, y: 20);

      expect(asset.copyWith(clearProject: true).projectId, isNull);
      expect(task.copyWith(clearProject: true, clearAsset: true).projectId, isNull);
      expect(task.copyWith(clearProject: true, clearAsset: true).assetId, isNull);
      expect(renewal.copyWith(clearProject: true).projectId, isNull);
      expect(node.copyWith(clearProject: true, clearAsset: true).projectId, isNull);
      expect(node.copyWith(clearProject: true, clearAsset: true).assetId, isNull);
    });
  });
}
