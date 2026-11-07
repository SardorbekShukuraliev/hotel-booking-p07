// The four API tests: HTTP in, HTTP out, with the reservations in a list.
// Run them with the other tests from the hotel-booking folder:  dart test
import 'dart:async';
import 'dart:convert';

import 'package:hotel_booking/api.dart';
import 'package:hotel_booking/notifications/src/email.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/reservations/src/store.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:hotel_booking/api_cache.dart';

final rooms = [Room('R7', 'Standard'), Room('R8', 'Deluxe')];
const search = '/rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14';
const maya = {
  'guestName': 'Maya',
  'guestEmail': 'maya@example.com',
  'room': 'R7',
  'checkIn': '2026-11-12',
  'checkOut': '2026-11-14'
};
const omar = {
  'guestName': 'Omar',
  'guestEmail': 'omar@example.com',
  'room': 'R7',
  'checkIn': '2026-11-13',
  'checkOut': '2026-11-15'
};

// The web app with the in-memory store. A shelf app is a function from Request to Response, so the
// tests call it directly, without a network.
Handler newApp() {
  final stats = Stats();
  final store = CountingReservationStore(InMemoryReservationStore(), stats);
  final service = BookingService(rooms, store, EmailNotificationSender());
  Future<T> unitOfWork<T>(FutureOr<T> Function(BookingService service) work) async => work(service);
  
  // Передаем кэш:
  return createApi(rooms, unitOfWork, stats, AvailabilityCache(InMemoryKeyValueStore()));
}

Future<Response> send(Handler app, String method, String path, [Object? body]) async =>
    app(Request(method, Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {'content-type': 'application/json'}));

void main() {
  test('search answers 200 with the free rooms', () async {
    final response = await send(newApp(), 'GET', search);
    expect(response.statusCode, 200);
    expect(await response.readAsString(),
        '{"checkIn":"2026-11-12","checkOut":"2026-11-14","rooms":[{"number":"R7","type":"Standard"},{"number":"R8","type":"Deluxe"}],"next":null}');
  });

  test('booking answers 201, then 409 for a shared night', () async {
    final app = newApp();
    final first = await send(app, 'POST', '/reservations', maya);
    expect(first.statusCode, 201);
    expect(await first.readAsString(),
        '{"id":"R101","status":"Confirmed","notificationFailed":false}');
    final second = await send(app, 'POST', '/reservations', omar);
    expect(second.statusCode, 409);
    expect(jsonDecode(await second.readAsString())['title'], 'Unavailable');
  });

  test('wrong dates answer 400 with problem details', () async {
    final response =
        await send(newApp(), 'POST', '/reservations', {...maya, 'checkOut': '2026-11-12'});
    expect(response.statusCode, 400);
    expect(response.headers['content-type'], 'application/problem+json');
    expect(await response.readAsString(),
        '{"title":"InvalidDates","status":400,"detail":"checkOut must be after checkIn."}');
  });

  test('cancel answers 204, then 404', () async {
    final app = newApp();
    await send(app, 'POST', '/reservations', maya);
    expect((await send(app, 'DELETE', '/reservations/R101')).statusCode, 204);
    final second = await send(app, 'DELETE', '/reservations/R101');
    expect(second.statusCode, 404);
    expect(jsonDecode(await second.readAsString())['title'], 'NotFound');
  });
}

class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> get(String key) async => _values[key];

  @override
  Future<void> set(String key, String value, int ttlSeconds) async {
    _values[key] = value;
  }

  @override
  Future<void> increment(String key) async {
    _values[key] = '${int.parse(_values[key] ?? '0') + 1}';
  }
}