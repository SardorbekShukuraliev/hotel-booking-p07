// Tests for the booking service after the P06 move into modules.
// Run them from the hotel-booking folder:  dart test
import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/notifications/src/sms.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/reservations/src/store.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:test/test.dart';

final r7 = Room('R7', 'Standard');
final r8 = Room('R8', 'Deluxe');
final maya = Guest('Maya', 'maya@example.com');
final omar = Guest('Omar', 'omar@example.com');
final nora = Guest('Nora', 'nora@example.com');

DateRange nov(int checkIn, int checkOut) =>
    DateRange(DateTime.utc(2026, 11, checkIn), DateTime.utc(2026, 11, checkOut));

// A stand-in sender for tests: remembers what it would send, or fails on purpose.
class FakeNotificationSender implements NotificationSender {
  FakeNotificationSender({this.fail = false});

  final bool fail;
  final List<String> sent = [];

  @override
  void sendConfirmation(Confirmation confirmation) {
    if (fail) throw StateError('The mail server is down.');
    sent.add(confirmation.reservationId);
  }
}

// The only place that builds the service: after the refactoring it takes any sender.
({BookingService service, InMemoryReservationStore store, FakeNotificationSender sender})
    newService({bool failingSender = false}) {
  final store = InMemoryReservationStore();
  final sender = FakeNotificationSender(fail: failingSender);
  return (
    service: BookingService([r7, r8], store, sender),
    store: store,
    sender: sender,
  );
}

void main() {
  test('Maya gets R7 when it is free', () async {
    final fixture = newService();
    expect('${await fixture.service.reserve(maya, r7, nov(12, 14))}', 'Accepted R101');
  });

  test('Omar is refused when a night is shared', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    expect('${await fixture.service.reserve(omar, r7, nov(13, 15))}', 'Unavailable');
    expect(fixture.store.count, 1);
  });

  test('Nora can arrive on the day Maya leaves', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    expect('${await fixture.service.reserve(nora, r7, nov(14, 16))}', 'Accepted R102');
  });

  test('check-out must be after check-in', () async {
    final fixture = newService();
    expect('${await fixture.service.reserve(omar, r8, nov(15, 15))}', 'InvalidDates');
    expect(fixture.store.count, 0);
  });

  test('cancelling frees the room again', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    expect(await fixture.service.cancel('R101'), isTrue);
    expect(await fixture.service.findFreeRooms(nov(12, 14)), contains(r7));
  });

  test('one confirmation per accepted booking', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    await fixture.service.reserve(omar, r7, nov(13, 15));
    await fixture.service.reserve(nora, r7, nov(14, 16));
    expect(fixture.sender.sent, ['R101', 'R102']);
  });

  test('a failed confirmation keeps the booking', () async {
    final fixture = newService(failingSender: true);
    final result = await fixture.service.reserve(maya, r7, nov(12, 14));
    expect('$result', 'Accepted R101');
    expect(result.notificationFailed, isTrue);
    expect(fixture.store.count, 1);
  });

  test('SMS confirmations need no change to BookingService', () async {
    final sms = SmsNotificationSender();
    final service = BookingService([r7, r8], InMemoryReservationStore(), sms);
    await service.reserve(maya, r7, nov(12, 14));
    expect(sms.sent, 1);
  });
}
