// lib/api_cache.dart
import 'package:redis/redis.dart' show Command;

const ttlSeconds = 30;
const versionKey = 'availability:version';

// Контракт для работы с Redis (чтобы в тестах можно было подставить словарь)
abstract interface class KeyValueStore {
  Future<String?> get(String key);
  Future<void> set(String key, String value, int ttlSeconds);
  Future<void> increment(String key);
}

// Реальная работа с Redis
class RedisKeyValueStore implements KeyValueStore {
  RedisKeyValueStore(this._redis);
  final Command _redis;

  @override
  Future<String?> get(String key) async => await _redis.send_object(['GET', key]) as String?;

  @override
  Future<void> set(String key, String value, int ttlSeconds) =>
      _redis.send_object(['SET', key, value, 'EX', '$ttlSeconds']);

  @override
  Future<void> increment(String key) => _redis.send_object(['INCR', key]);
}

// Сам кэш (Cache-aside)
class AvailabilityCache {
  AvailabilityCache(this._store);
  final KeyValueStore _store;

  Future<String> key(String checkIn, String checkOut) async {
    final version = await _store.get(versionKey) ?? '0';
    return 'availability:v$version:$checkIn:$checkOut';
  }

  Future<String?> get(String key) => _store.get(key);

  Future<void> set(String key, String roomNumbers) => _store.set(key, roomNumbers, ttlSeconds);

  Future<void> invalidate() => _store.increment(versionKey);
}