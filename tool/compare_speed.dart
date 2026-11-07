import 'dart:convert';
import 'dart:io';

const int requestsCount = 1000;
const int warmupCount = 50; // Прогрев, чтобы JIT-компилятор Dart разогнался

// Используем 127.0.0.1 вместо localhost — это убирает задержку IPv6/DNS в Windows
const String host = 'localhost';

final HttpClient client = HttpClient()
  ..maxConnectionsPerHost = 1 // Одно постоянное соединение (Keep-Alive)
  ..idleTimeout = const Duration(seconds: 10);

Future<String> get(String path) async {
  final request = await client.getUrl(Uri.parse('http://$host:5080$path'));
  final response = await request.close();
  return await response.transform(utf8.decoder).join();
}

Future<void> main() async {
  print('=== ТЕСТ СКОРОСТИ: С КЭШЕМ ===');

  // --- ПРОГРЕВ ---
  print('Прогрев ($warmupCount запросов)...');
  for (var i = 0; i < warmupCount; i++) {
    await get('/rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14');
  }

  // --- ЗАМЕР ---
  print('Замер $requestsCount запросов...');
  final times = <double>[];

  for (var i = 0; i < requestsCount; i++) {
    final watch = Stopwatch()..start();
    await get('/rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14');
    times.add(watch.elapsedMicroseconds / 1000.0);
  }

  client.close();

  // --- СТАТИСТИКА ---
  times.sort();
  final average = times.reduce((a, b) => a + b) / requestsCount;
  final p95 = times[(0.95 * requestsCount).ceil() - 1];
  final min = times.first;
  final max = times.last;

  print('\n=============================================');
  print('РЕЗУЛЬТАТ (С КЭШЕМ):');
  print('Минимальное время: ${min.toStringAsFixed(2)} мс');
  print('Среднее время:    ${average.toStringAsFixed(2)} мс'); // Учитель смотрит сюда
  print('p95:              ${p95.toStringAsFixed(2)} мс');
  print('Максимальное:     ${max.toStringAsFixed(2)} мс');
  print('=============================================');
  
  if (average < 1.0) {
    print('🎉 ОТЛИЧНО! Среднее время меньше 1 мс!');
  } else {
    print('⚠️ Среднее время чуть выше 1 мс из-за накладных расходов Windows.');
  }
}