import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comrade_vault/models.dart';
import 'package:comrade_vault/services/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists only ciphertext and unlocks it with the correct passphrase', () async {
    final vault = VaultService();
    addTearDown(vault.dispose);
    await vault.initialize(5);

    const passphrase = 'correct horse battery staple';
    const uniqueTitle = 'private-service-account-92731';
    const uniqueSecret = 'do-not-store-this-plaintext-92731';
    await vault.createVault(passphrase);
    await vault.saveSecret(const VaultSecret(
      id: '',
      title: uniqueTitle,
      category: 'API Key',
      username: 'private-user-92731',
      secret: uniqueSecret,
      website: 'https://example.invalid',
      notes: 'private note 92731',
      tags: ['test'],
    ));

    final preferences = await SharedPreferences.getInstance();
    final serialized = preferences.getString('comrade_vault.encrypted_vault.v1');
    expect(serialized, isNotNull);
    expect(serialized, isNot(contains(uniqueTitle)));
    expect(serialized, isNot(contains(uniqueSecret)));
    expect(serialized, isNot(contains('private-user-92731')));
    expect(serialized, isNot(contains(passphrase)));

    final archive = vault.encryptedExport()!;
    await expectLater(vault.restoreEncrypted({'version': 1}), throwsA(isA<FormatException>()));
    expect(vault.isUnlocked, isTrue, reason: 'An invalid archive must not replace the active Vault.');
    await vault.restoreEncrypted(archive);
    expect(vault.isUnlocked, isFalse, reason: 'Restoring an archive must leave the Vault locked.');
    expect(vault.items, isEmpty);

    await expectLater(vault.unlock('incorrect passphrase'), throwsA(isA<StateError>()));
    expect(vault.isUnlocked, isFalse);

    await vault.unlock(passphrase);
    expect(vault.isUnlocked, isTrue);
    expect(vault.items, hasLength(1));
    expect(vault.items.single.title, uniqueTitle);
    expect(vault.items.single.secret, uniqueSecret);
    expect(vault.items.single.username, 'private-user-92731');
  });
}
