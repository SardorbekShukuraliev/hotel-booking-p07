// tool/measure.dart
import 'dart:convert';
import 'dart:io';

const searches = 1000;
const names = ['searches', 'databaseQueries', 'cacheHits', 'cacheMisses'];

final client = HttpClient();

Future<String> get(String path) async {
  final request = await client.getUrl(Uri.parse('http://localhost:5080$path'));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    stderr.writeln('GET $path answered ${response.statusCode}: $body');
    exit(1);
  }
  return body;
}

Future<void> main(List<String> args) async {
  final checkIn = args.length >= 2 ? args[0] : '2026-11-12';
  final checkOut = args.length >= 2 ? args[1] : '2026-11-14';

  final before = jsonDecode(await get('/stats')) as Map<String, dynamic>;
  final times = <double>[];
  final total = Stopwatch()..start();
  
  for (var i = 0; i < searches; i++) {
    final watch = Stopwatch()..start();
    await get('/rooms/availability?checkIn=$checkIn&checkOut=$checkOut');
    times.add(watch.elapsedMicroseconds / 1000);
  }
  
  final seconds = total.elapsedMicroseconds / 1000000;
  final after = jsonDecode(await get('/stats')) as Map<String, dynamic>;
  client.close();

  times.sort();
  final p95 = times[(0.95 * searches).ceil() - 1];
  final average = times.reduce((a, b) => a + b) / searches;
  final difference = names.map((name) => '"$name":${(after[name] as int) - (before[name] as int)}').join(',');
  
  print('$searches searches for $checkIn to $checkOut');
  print('Average: ${average.toStringAsFixed(1)} ms');
  print('p95: ${p95.toStringAsFixed(1)} ms');
  print('Total: ${seconds.toStringAsFixed(1)} s');
  print('GET /stats difference: {$difference}');
}