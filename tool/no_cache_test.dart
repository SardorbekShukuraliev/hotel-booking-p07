import 'dart:convert';
import 'dart:io';

const int requestsCount = 1000;
const String host = 'localhost';
final HttpClient client = HttpClient()..maxConnectionsPerHost = 1;

Future<String> get(String path) async {
  final request = await client.getUrl(Uri.parse('http://$host:5080$path'));
  final response = await request.close();
  return await response.transform(utf8.decoder).join();
}

Future<Map<String, dynamic>> getStats() async {
  final body = await get('/stats');
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<void> main() async {
  print('=============================================');
  print('   ТЕСТ СКОРОСТИ: ТОЛЬКО POSTGRESQL (БЕЗ КЭША)');
  print('=============================================');
  
  // Очищаем кэш, чтобы он не мешал
  print('Очистка Redis...');
  await Process.run('docker', ['compose', 'exec', 'cache', 'redis-cli', 'FLUSHALL']);

  final before = await getStats();
  final times = <double>[];
  
  print('Отправка $requestsCount УНИКАЛЬНЫХ запросов (все идут в базу)...');

  for (var i = 0; i < requestsCount; i++) {
    // Генерируем 1000 уникальных дат, чтобы кэш ни разу не сработал
    final date = DateTime.utc(2026, 1, 1).add(Duration(days: i));
    final checkIn = date.toIso8601String().split('T')[0];
    final checkOut = date.add(const Duration(days: 2)).toIso8601String().split('T')[0];
    
    final watch = Stopwatch()..start();
    await get('/rooms/availability?checkIn=$checkIn&checkOut=$checkOut');
    times.add(watch.elapsedMicroseconds / 1000.0);
  }

  final after = await getStats();
  client.close();

  times.sort();
  final avg = times.reduce((a, b) => a + b) / requestsCount;
  final p95 = times[(0.95 * requestsCount).ceil() - 1];
  final dbQueries = (after['databaseQueries'] as int) - (before['databaseQueries'] as int);
  final cacheHits = (after['cacheHits'] as int) - (before['cacheHits'] as int);

  print('\n=============================================');
  print('РЕЗУЛЬТАТ (БЕЗ КЭША):');
  print('Запросов к PostgreSQL: $dbQueries (ожидаем 2000)');
  print('Попаданий в кэш:       $cacheHits (ожидаем 0)');
  print('Среднее время:         ${avg.toStringAsFixed(2)} мс');
  print('p95 (95% быстрее):     ${p95.toStringAsFixed(2)} мс');
  print('=============================================');
}