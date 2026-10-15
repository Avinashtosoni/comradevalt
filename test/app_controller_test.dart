import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comrade_vault/app_controller.dart';
import 'package:comrade_vault/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saving a project creates its mind-map node and activity, then persists', () async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.initialize();

    const project = ProjectItem(
      id: 'project-test',
      name: 'Test workspace project',
      status: 'Planning',
      description: 'A project created by a persistence test.',
    );
    controller.saveProject(project);
    // Await a deterministic persistence pass after the synchronous controller action.
    await controller.replaceWorkspace(controller.data);

    final node = controller.data.nodes.singleWhere((item) => item.id == 'node-project-test');
    expect(node.label, project.name);
    expect(node.projectId, project.id);
    expect(controller.data.edges.any((edge) => edge.source == 'node-root' && edge.target == node.id), isTrue);
    expect(controller.data.activities.first.title, 'Project created');

    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(preferences.getString('comrade_vault.workspace.v1')!) as Map<String, dynamic>;
    final restored = WorkspaceData.fromJson(saved);
    expect(restored.projects.any((item) => item.id == project.id), isTrue);
    expect(restored.nodes.any((item) => item.id == node.id), isTrue);
  });

  test('deleting a project clears dependent links and removes its map edges', () async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.initialize();
    final project = controller.data.projects.first;
    final nodeId = 'node-${project.id}';

    controller.deleteProject(project);
    await controller.replaceWorkspace(controller.data);

    expect(controller.data.projects.any((item) => item.id == project.id), isFalse);
    expect(controller.data.assets.where((item) => item.projectId == project.id), isEmpty);
    expect(controller.data.tasks.where((item) => item.projectId == project.id), isEmpty);
    expect(controller.data.renewals.where((item) => item.projectId == project.id), isEmpty);
    expect(controller.data.nodes.any((item) => item.id == nodeId), isFalse);
    expect(controller.data.edges.where((edge) => edge.source == nodeId || edge.target == nodeId), isEmpty);
  });

  test('notes can be created, updated and deleted without leaking their contents to activity', () async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.initialize();

    const note = NoteItem(
      id: 'note-controller-test',
      title: 'Sensitive planning context',
      body: 'Keep this private note body out of activity history.',
      tags: ['planning', 'private'],
      pinned: true,
    );
    controller.saveNote(note);
    await controller.replaceWorkspace(controller.data);

    var savedNote = controller.data.notes.singleWhere((item) => item.id == note.id);
    expect(savedNote.title, note.title);
    expect(savedNote.body, note.body);
    expect(savedNote.tags, note.tags);
    expect(savedNote.pinned, isTrue);
    expect(savedNote.createdAt, isNotEmpty);
    expect(controller.data.activities.first.title, 'Workspace note created');
    expect(controller.data.activities.first.detail, isEmpty);
    final activityText = controller.data.activities.map((item) => '${item.title} ${item.detail}').join(' ');
    expect(activityText, isNot(contains(note.title)));
    expect(activityText, isNot(contains(note.body)));

    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(preferences.getString('comrade_vault.workspace.v1')!) as Map<String, dynamic>;
    expect(WorkspaceData.fromJson(saved).notes.singleWhere((item) => item.id == note.id).body, note.body);

    controller.saveNote(savedNote.copyWith(title: 'Updated planning context'));
    await controller.replaceWorkspace(controller.data);
    expect(controller.data.notes.where((item) => item.id == note.id), hasLength(1));
    expect(controller.data.notes.singleWhere((item) => item.id == note.id).createdAt, savedNote.createdAt);
    expect(controller.data.notes.singleWhere((item) => item.id == note.id).title, 'Updated planning context');

    savedNote = controller.data.notes.singleWhere((item) => item.id == note.id);
    controller.deleteNote(savedNote);
    await controller.replaceWorkspace(controller.data);
    expect(controller.data.notes.any((item) => item.id == note.id), isFalse);
    expect(controller.data.activities.first.title, 'Workspace note removed');
    expect(controller.data.activities.first.detail, isEmpty);
  });
}
