import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class VaultSecret {
  const VaultSecret({required this.id, required this.title, required this.category, this.username = '', this.secret = '', this.website = '', this.notes = '', this.tags = const [], this.updatedAt = ''});
  final String id;
  final String title;
  final String category;
  final String username;
  final String secret;
  final String website;
  final String notes;
  final List<String> tags;
  final String updatedAt;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'category': category, 'username': username, 'secret': secret, 'website': website, 'notes': notes, 'tags': tags, 'updatedAt': updatedAt};
  factory VaultSecret.fromJson(Map<String, dynamic> json) => VaultSecret(
    id: json['id'] as String? ?? '', title: json['title'] as String? ?? '', category: json['category'] as String? ?? 'Password',
    username: json['username'] as String? ?? '', secret: json['secret'] as String? ?? '', website: json['website'] as String? ?? '',
    notes: json['notes'] as String? ?? '', tags: (json['tags'] as List<dynamic>? ?? const []).map((value) => value.toString()).toList(),
    updatedAt: json['updatedAt'] as String? ?? '',
  );
}

class VaultService extends ChangeNotifier {
  static const _storageKey = 'comrade_vault.encrypted_vault.v1';
  static const _verifyText = 'COMRADE_VAULT_UNLOCK_CHECK_V1';
  static const _iterations = 310000;
  static const _uuid = Uuid();

  final AesGcm _cipher = AesGcm.with256bits();
  final Pbkdf2 _kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _iterations, bits: 256);
  SharedPreferences? _preferences;
  Map<String, dynamic>? _snapshot;
  SecretKey? _key;
  List<VaultSecret> items = [];
  DateTime _lastActivity = DateTime.now();
  Timer? _autoLockTimer;
  int autoLockMinutes = 5;
  int _lockGeneration = 0;
  String? errorMessage;

  bool get hasVault => _snapshot != null && _snapshot!['salt'] is String;
  bool get isUnlocked => _key != null;
  int get count => items.length;

  Future<void> initialize(int autoLock) async {
    autoLockMinutes = autoLock;
    try {
      _preferences = await SharedPreferences.getInstance();
      final stored = _preferences!.getString(_storageKey);
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic> && _isSupportedSnapshot(decoded)) {
          _snapshot = decoded;
        } else {
          errorMessage = 'The saved Vault archive has an unsupported or invalid format.';
        }
      }
    } catch (_) {
      errorMessage = 'Vault storage could not be opened. The workspace can still be used, but Vault changes may not persist.';
    }
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_key == null || autoLockMinutes <= 0) return;
      if (DateTime.now().difference(_lastActivity) >= Duration(minutes: autoLockMinutes)) lock();
    });
    notifyListeners();
  }

  void setAutoLock(int minutes) {
    autoLockMinutes = minutes;
    touch();
    notifyListeners();
  }

  void touch() {
    _lastActivity = DateTime.now();
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) => _kdf.deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);

  Future<Map<String, String>> _encryptText(SecretKey key, String value) async {
    final nonce = _cipher.newNonce();
    final box = await _cipher.encrypt(utf8.encode(value), secretKey: key, nonce: nonce);
    return {'nonce': base64Encode(box.nonce), 'cipherText': base64Encode(box.cipherText), 'mac': base64Encode(box.mac.bytes)};
  }

  Future<String> _decryptText(SecretKey key, Map<String, dynamic> box) async {
    final secretBox = SecretBox(
      base64Decode(box['cipherText'] as String),
      nonce: base64Decode(box['nonce'] as String),
      mac: Mac(base64Decode(box['mac'] as String)),
    );
    final bytes = await _cipher.decrypt(secretBox, secretKey: key);
    return utf8.decode(bytes);
  }

  Future<void> createVault(String passphrase) async {
    if (hasVault) throw StateError('A vault already exists on this device.');
    final generation = _lockGeneration;
    final random = Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
    final key = await _deriveKey(passphrase, salt);
    final proof = await _encryptText(key, _verifyText);
    final snapshot = {
      'version': 1,
      'kdf': 'PBKDF2-SHA-256',
      'iterations': _iterations,
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'verifier': proof,
      'items': <Map<String, dynamic>>[],
    };
    await _persistSnapshot(snapshot);
    _snapshot = snapshot;
    if (generation == _lockGeneration) {
      _key = key;
      touch();
    }
    items = [];
    notifyListeners();
  }

  Future<void> unlock(String passphrase) async {
    if (!hasVault) throw StateError('No vault exists on this device.');
    final generation = _lockGeneration;
    try {
      final salt = base64Decode(_snapshot!['salt'] as String);
      final key = await _deriveKey(passphrase, salt);
      final proof = await _decryptText(key, Map<String, dynamic>.from(_snapshot!['verifier'] as Map));
      if (proof != _verifyText) throw StateError('Vault could not be unlocked. Check your passphrase.');
      final decrypted = <VaultSecret>[];
      for (final entry in (_snapshot!['items'] as List<dynamic>)) {
        final row = Map<String, dynamic>.from(entry as Map);
        final clear = await _decryptText(key, Map<String, dynamic>.from(row['payload'] as Map));
        final item = VaultSecret.fromJson(jsonDecode(clear) as Map<String, dynamic>);
        decrypted.add(item.copyWithUpdatedAt(row['updatedAt'] as String? ?? item.updatedAt));
      }
      if (generation != _lockGeneration) return;
      _key = key;
      items = decrypted..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      errorMessage = null;
      touch();
      notifyListeners();
    } catch (_) {
      throw StateError('Vault could not be unlocked. Check your passphrase.');
    }
  }

  Future<void> saveSecret(VaultSecret item) async {
    final key = _key;
    if (key == null) throw StateError('Unlock the vault to continue.');
    final generation = _lockGeneration;
    final updated = VaultSecret(id: item.id.isEmpty ? _uuid.v4() : item.id, title: item.title, category: item.category, username: item.username, secret: item.secret, website: item.website, notes: item.notes, tags: item.tags, updatedAt: DateTime.now().toIso8601String());
    final encrypted = await _encryptText(key, jsonEncode(updated.toJson()));
    final rows = List<Map<String, dynamic>>.from((_snapshot!['items'] as List<dynamic>).map((row) => Map<String, dynamic>.from(row as Map)));
    final replacement = {'id': updated.id, 'updatedAt': updated.updatedAt, 'payload': encrypted};
    final existingIndex = rows.indexWhere((row) => row['id'] == updated.id);
    if (existingIndex < 0) rows.insert(0, replacement); else rows[existingIndex] = replacement;
    final snapshot = Map<String, dynamic>.from(_snapshot!);
    snapshot['items'] = rows;
    await _persistSnapshot(snapshot);
    _snapshot = snapshot;
    if (generation == _lockGeneration && identical(_key, key)) {
      items = [updated, ...items.where((existing) => existing.id != updated.id)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      touch();
    }
    notifyListeners();
  }

  Future<void> deleteSecret(String itemId) async {
    final key = _key;
    if (key == null) throw StateError('Unlock the vault to continue.');
    final generation = _lockGeneration;
    final snapshot = Map<String, dynamic>.from(_snapshot!);
    snapshot['items'] = (_snapshot!['items'] as List<dynamic>).where((row) => (row as Map)['id'] != itemId).toList();
    await _persistSnapshot(snapshot);
    _snapshot = snapshot;
    if (generation == _lockGeneration && identical(_key, key)) {
      items = items.where((item) => item.id != itemId).toList();
      touch();
    }
    notifyListeners();
  }

  Future<void> _persistSnapshot(Map<String, dynamic> snapshot) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    _preferences = prefs;
    final saved = await prefs.setString(_storageKey, jsonEncode(snapshot));
    if (!saved) throw StateError('The encrypted vault could not be saved on this device.');
  }

  bool _isSupportedSnapshot(Map<String, dynamic> snapshot) =>
      snapshot['version'] == 1 &&
      snapshot['kdf'] == 'PBKDF2-SHA-256' &&
      snapshot['iterations'] == _iterations &&
      snapshot['cipher'] == 'AES-256-GCM' &&
      snapshot['salt'] is String &&
      snapshot['verifier'] is Map &&
      snapshot['items'] is List;

  Map<String, dynamic>? encryptedExport() => _snapshot == null ? null : Map<String, dynamic>.from(_snapshot!);

  Future<void> restoreEncrypted(Map<String, dynamic>? archive) async {
    if (archive == null) {
      final prefs = _preferences ?? await SharedPreferences.getInstance();
      _preferences = prefs;
      await prefs.remove(_storageKey);
      _snapshot = null;
    } else {
      if (!_isSupportedSnapshot(archive)) {
        throw const FormatException('This encrypted vault backup is not valid.');
      }
      final snapshot = Map<String, dynamic>.from(archive);
      await _persistSnapshot(snapshot);
      _snapshot = snapshot;
    }
    lock();
  }

  Future<void> removeVault() async {
    _lockGeneration++;
    _clearUnlockedState();
    notifyListeners();
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    _preferences = prefs;
    await prefs.remove(_storageKey);
    _snapshot = null;
    notifyListeners();
  }

  void lock() {
    _lockGeneration++;
    _clearUnlockedState();
    notifyListeners();
  }

  void _clearUnlockedState() {
    _key = null;
    items = [];
    touch();
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    _lockGeneration++;
    _key = null;
    items = [];
    super.dispose();
  }
}

extension on VaultSecret {
  VaultSecret copyWithUpdatedAt(String value) => VaultSecret(id: id, title: title, category: category, username: username, secret: secret, website: website, notes: notes, tags: tags, updatedAt: value);
}
