import 'dart:async';

import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/rooms/rooms.dart';

import 'domain.dart';

// What BookingService needs from storage: a list in memory answers at once, a database
// answers later (a Future). FutureOr allows both, and BookingService awaits the answer.
abstract interface class ReservationStore {
  FutureOr<int> get count;

  FutureOr<bool> hasOverlap(Room room, DateRange stay);

  FutureOr<void> save(Reservation reservation);

  // Returns null when no reservation has that id.
  FutureOr<Reservation?> find(String id);

  FutureOr<int> countConfirmed(Room room, DateRange stay);
}

class BookingResult {
  BookingResult(this.outcome, [this.reservationId, this.notificationFailed = false]);

  final String outcome;
  final String? reservationId;
  final bool notificationFailed;

  @override
  String toString() => reservationId == null ? outcome : '$outcome $reservationId';
}

// Owns the booking rule. Uses only the public contracts of Rooms and Notifications.
class BookingService {
  BookingService(this.rooms, this.store, this.notifications, {this.slowStep = Duration.zero});

  final List<Room> rooms;
  final ReservationStore store;
  final NotificationSender notifications;
  final Duration slowStep;

  Future<List<Room>> findFreeRooms(DateRange stay) async => [
        for (final room in rooms)
          if (!await store.hasOverlap(room, stay)) room,
      ];

  Future<BookingResult> reserve(Guest guest, Room room, DateRange stay) async {
    if (!stay.isValid()) return BookingResult('InvalidDates');
    if (await store.hasOverlap(room, stay)) return BookingResult('Unavailable');

    // A pause that lets other requests run while this one waits.
    await Future<void>.delayed(slowStep);

    final reservation = Reservation('R${101 + await store.count}', guest, room, stay);
    await store.save(reservation);
    try {
      // Notifications gets its own message: the five fields it needs, not the Reservation.
      notifications.sendConfirmation(
          Confirmation(reservation.id, guest.email, room.number, stay.checkIn, stay.checkOut));
    } catch (failure) {
      // R6: the booking is already saved, so a failed message must not undo or hide it.
      return BookingResult('Accepted', reservation.id, true);
    }
    return BookingResult('Accepted', reservation.id);
  }

  Future<bool> cancel(String reservationId) async =>
      (await store.find(reservationId))?.cancel() ?? false;
}
