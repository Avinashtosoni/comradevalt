import 'package:flutter/material.dart';

enum AppSection { mindMap, dashboard, projects, assets, vault, tasks, renewals, activity, notifications, settings }

extension AppSectionInfo on AppSection {
  String get id => switch (this) {
    AppSection.mindMap => 'mindmap', AppSection.dashboard => 'dashboard', AppSection.projects => 'projects',
    AppSection.assets => 'assets', AppSection.vault => 'vault', AppSection.tasks => 'tasks', AppSection.renewals => 'renewals',
    AppSection.activity => 'activity', AppSection.notifications => 'notifications', AppSection.settings => 'settings',
  };
  String get label => switch (this) {
    AppSection.mindMap => 'Mind Map', AppSection.dashboard => 'Dashboard', AppSection.projects => 'Projects', AppSection.assets => 'Digital Assets',
    AppSection.vault => 'Vault', AppSection.tasks => 'Tasks', AppSection.renewals => 'Renewals', AppSection.activity => 'Activity',
    AppSection.notifications => 'Notifications', AppSection.settings => 'Settings',
  };
  String get eyebrow => switch (this) {
    AppSection.mindMap => 'YOUR ECOSYSTEM', AppSection.dashboard => 'COMMAND CENTER', AppSection.projects => 'WORKSPACE', AppSection.assets => 'WORKSPACE',
    AppSection.vault => 'PRIVATE STORAGE', AppSection.tasks => 'OPERATIONS', AppSection.renewals => 'OPERATIONS', AppSection.activity => 'WORKSPACE HISTORY',
    AppSection.notifications => 'UPDATES', AppSection.settings => 'PREFERENCES',
  };
  IconData get icon => switch (this) {
    AppSection.mindMap => Icons.hub_rounded, AppSection.dashboard => Icons.grid_view_rounded, AppSection.projects => Icons.folder_copy_rounded,
    AppSection.assets => Icons.widgets_rounded, AppSection.vault => Icons.key_rounded, AppSection.tasks => Icons.checklist_rounded,
    AppSection.renewals => Icons.event_repeat_rounded, AppSection.activity => Icons.timeline_rounded, AppSection.notifications => Icons.notifications_none_rounded,
    AppSection.settings => Icons.tune_rounded,
  };
  static AppSection fromId(String value) => AppSection.values.firstWhere((item) => item.id == value, orElse: () => AppSection.mindMap);
}
