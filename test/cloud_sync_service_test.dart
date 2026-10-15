import 'package:flutter_test/flutter_test.dart';

import 'package:comrade_vault/services/cloud_sync_service.dart';

void main() {
  test('cloud service remains disabled when Supabase build settings are absent', () async {
    final service = CloudSyncService();
    addTearDown(service.dispose);

    if (service.isConfigured) return;
    await service.initialize();

    expect(service.isReady, isFalse);
    expect(service.currentUser, isNull);
    expect(service.hasCloudSnapshot, isFalse);
  });
}
