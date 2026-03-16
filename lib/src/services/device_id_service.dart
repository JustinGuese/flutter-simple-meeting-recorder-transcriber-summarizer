import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _storageKey = 'device_uuid';
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  );

  final FlutterSecureStorage _storage;

  DeviceIdService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String? _cached;

  /// Returns the persistent device UUID, creating one on first call.
  Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;

    final existing = await _storage.read(
      key: _storageKey,
      iOptions: _iosOptions,
    );

    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final newId = const Uuid().v4();
    await _storage.write(
      key: _storageKey,
      value: newId,
      iOptions: _iosOptions,
    );
    _cached = newId;
    return newId;
  }
}
