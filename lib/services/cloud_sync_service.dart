import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_controller.dart';
import '../models.dart';
import 'supabase_config.dart';

/// Optional, explicit cloud backup/restore for the local workspace.
/// Vault records are deliberately not included in the workspace snapshot.
class CloudSyncService extends ChangeNotifier {
  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;

  bool isCheckingRemote = false;
  bool isBusy = false;
  bool hasCloudWorkspace = false;
  bool hasCloudSnapshot = false;
  int remoteRevision = 0;
  String? remoteUpdatedAt;
  String? workspaceName;
  String? initializationError;
  String? errorMessage;
  String? infoMessage;
  String? _workspaceId;

  bool get isConfigured => SupabaseConfig.isConfigured;
  bool get isReady => _client != null;
  User? get currentUser => _client?.auth.currentUser;
  String? get signedInEmail => currentUser?.email;

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final supabase = await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _client = supabase.client;
      _authSubscription = _client!.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
        onError: (Object error) {
          errorMessage = _friendlyError(error);
          notifyListeners();
        },
      );
      if (_client!.auth.currentSession != null) {
        unawaited(refreshRemoteState());
      }
    } catch (error) {
      initializationError = _friendlyError(error);
    }
    notifyListeners();
  }

  void _handleAuthStateChange(AuthState state) {
    errorMessage = null;
    _clearRemoteState();
    if (state.session == null) {
      infoMessage = null;
    } else {
      infoMessage = 'Signed in. Choose whether to upload this device or restore the cloud copy.';
      unawaited(refreshRemoteState());
    }
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) => _run(() async {
        if (email.trim().isEmpty || password.isEmpty) throw const FormatException('Enter your email and password.');
        await _requireClient().auth.signInWithPassword(email: email.trim(), password: password);
        infoMessage = 'Signed in. Choose whether to upload this device or restore the cloud copy.';
      });

  Future<void> signUp({required String email, required String password}) => _run(() async {
        if (email.trim().isEmpty || password.isEmpty) throw const FormatException('Enter an email and password.');
        final response = await _requireClient().auth.signUp(email: email.trim(), password: password);
        infoMessage = response.session == null
            ? 'Check your email to confirm the new account, then sign in here.'
            : 'Account created. Choose whether to upload this device or restore the cloud copy.';
      });

  Future<void> signOut() => _run(() async {
        await _requireClient().auth.signOut();
        _clearRemoteState();
        infoMessage = 'Signed out. Your local workspace is unchanged.';
      });

  Future<void> refreshRemoteState() async {
    if (isCheckingRemote) return;
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      _clearRemoteState();
      notifyListeners();
      return;
    }

    isCheckingRemote = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();
    try {
      await _loadRemoteState(client, user);
    } catch (error) {
      errorMessage = _friendlyError(error);
    } finally {
      isCheckingRemote = false;
      notifyListeners();
    }
  }

  Future<void> uploadLocalWorkspace(AppController app) => _run(() async {
        final client = _requireClient();
        final user = client.auth.currentUser;
        if (user == null) throw const FormatException('Sign in before uploading a workspace.');

        final workspace = await _ensureWorkspace(client, user);
        final workspaceId = workspace['id']! as String;
        final snapshot = await client
            .from('workspace_data')
            .select('revision')
            .eq('workspace_id', workspaceId)
            .maybeSingle();
        final expectedRevision = snapshot == null ? 0 : (snapshot['revision'] as num).toInt();

        final result = await client.rpc('save_workspace_snapshot', params: {
          'p_workspace_id': workspaceId,
          'p_payload': app.data.toJson(),
          'p_expected_revision': expectedRevision,
        });
        final savedRow = _rpcRow(result);
        _workspaceId = workspaceId;
        workspaceName = workspace['name'] as String? ?? 'Personal workspace';
        hasCloudWorkspace = true;
        hasCloudSnapshot = true;
        remoteRevision = (savedRow?['revision'] as num?)?.toInt() ?? expectedRevision + 1;
        remoteUpdatedAt = savedRow?['updated_at'] as String? ?? DateTime.now().toUtc().toIso8601String();
        infoMessage = 'Workspace uploaded. Upload again after local edits to update the cloud copy.';
      });

  Future<void> restoreCloudWorkspace(AppController app) => _run(() async {
        final client = _requireClient();
        final user = client.auth.currentUser;
        if (user == null) throw const FormatException('Sign in before restoring a workspace.');
        final workspace = await _findWorkspace(client, user);
        if (workspace == null) throw const FormatException('There is no cloud workspace to restore yet.');
        final workspaceId = workspace['id']! as String;
        final snapshot = await client
            .from('workspace_data')
            .select('payload,revision,updated_at')
            .eq('workspace_id', workspaceId)
            .maybeSingle();
        if (snapshot == null) throw const FormatException('There is no cloud snapshot to restore yet.');
        final payload = snapshot['payload'];
        if (payload is! Map) throw const FormatException('The cloud workspace snapshot is invalid.');

        final restored = WorkspaceData.fromJson(Map<String, dynamic>.from(payload));
        await app.replaceWorkspace(restored);
        _workspaceId = workspaceId;
        workspaceName = workspace['name'] as String? ?? 'Personal workspace';
        hasCloudWorkspace = true;
        hasCloudSnapshot = true;
        remoteRevision = (snapshot['revision'] as num).toInt();
        remoteUpdatedAt = snapshot['updated_at'] as String?;
        infoMessage = app.persistenceMessage == null
            ? 'Cloud workspace restored to this device. The Vault remains separate.'
            : 'Cloud data loaded, but this device could not save it locally.';
      });

  Future<void> _loadRemoteState(SupabaseClient client, User user) async {
    final workspace = await _findWorkspace(client, user);
    if (client.auth.currentUser?.id != user.id) {
      _clearRemoteState();
      return;
    }
    if (workspace == null) {
      _clearRemoteState();
      infoMessage = 'No cloud workspace yet. Upload this device to create one.';
      return;
    }

    _workspaceId = workspace['id']! as String;
    workspaceName = workspace['name'] as String? ?? 'Personal workspace';
    hasCloudWorkspace = true;
    final snapshot = await client
        .from('workspace_data')
        .select('revision,updated_at')
        .eq('workspace_id', _workspaceId!)
        .maybeSingle();
    if (client.auth.currentUser?.id != user.id) {
      _clearRemoteState();
      return;
    }
    if (snapshot == null) {
      hasCloudSnapshot = false;
      remoteRevision = 0;
      remoteUpdatedAt = null;
      infoMessage = 'Cloud workspace is ready, but it has no saved snapshot yet.';
      return;
    }

    hasCloudSnapshot = true;
    remoteRevision = (snapshot['revision'] as num).toInt();
    remoteUpdatedAt = snapshot['updated_at'] as String?;
    infoMessage = 'Cloud snapshot available · revision $remoteRevision.';
  }

  Map<String, dynamic>? _rpcRow(dynamic result) {
    if (result is Map) return Map<String, dynamic>.from(result);
    if (result is List && result.isNotEmpty && result.first is Map) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _findWorkspace(SupabaseClient client, User user) async {
    final result = await client
        .from('workspaces')
        .select('id,name')
        .eq('owner_id', user.id)
        .maybeSingle();
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> _ensureWorkspace(SupabaseClient client, User user) async {
    final existing = await _findWorkspace(client, user);
    if (existing != null) return existing;

    try {
      final created = await client
          .from('workspaces')
          .insert({'owner_id': user.id})
          .select('id,name')
          .single();
      return Map<String, dynamic>.from(created);
    } catch (_) {
      // Another signed-in device may have created the one-per-user row at the
      // same time. Re-read before treating that as a real failure.
      final createdElsewhere = await _findWorkspace(client, user);
      if (createdElsewhere != null) return createdElsewhere;
      rethrow;
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_client == null) return;
    isBusy = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();
    try {
      await operation();
    } catch (error) {
      errorMessage = _friendlyError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  SupabaseClient _requireClient() => _client ?? (throw StateError('Supabase is not initialized.'));

  void _clearRemoteState() {
    _workspaceId = null;
    workspaceName = null;
    hasCloudWorkspace = false;
    hasCloudSnapshot = false;
    remoteRevision = 0;
    remoteUpdatedAt = null;
  }

  String _friendlyError(Object error) {
    if (error is AuthException) return error.message;
    if (error is FormatException) return error.message;
    if (error is PostgrestException) {
      if (error.code == '40001' || error.message.contains('sync_conflict')) {
        return 'The cloud copy changed in another session. Refresh its status, review it, then try again.';
      }
      if (error.code == '42501') {
        return 'Supabase denied this request. Check that the SQL migration and row-level security policies are installed.';
      }
      return error.message;
    }
    return 'Cloud request failed. Check your network and Supabase project configuration.';
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
