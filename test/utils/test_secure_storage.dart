import 'package:bitsxlamarato_frontend_2025/services/session_manager.dart';

class InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> _store = {};

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }
}
