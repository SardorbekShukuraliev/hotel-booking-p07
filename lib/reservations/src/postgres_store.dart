import 'package:hotel_booking/rooms/rooms.dart';
import 'package:postgres/postgres.dart' hide DateRange; // the stay is our own DateRange

import 'booking.dart';
import 'domain.dart';

// Confirmed reservations of a room that share at least one night with a stay.
const confirmedOverlaps = "FROM reservations WHERE room = @room AND status = 'Confirmed' "
    'AND check_in < @checkOut:date AND @checkIn:date < check_out';

// Keeps reservations in PostgreSQL. bin/main.dart creates one per request (a unit of work): it
// remembers the reservations it hands out, and saveChanges writes their changes.
class PostgresReservationStore implements ReservationStore {
  PostgresReservationStore(this._pool, this._rooms);

  final Pool<void> _pool;
  final List<Room> _rooms;
  // Each found reservation and the status it had in the database.
  final Map<Reservation, ReservationStatus> _loaded = {};

  @override
  Future<int> get count => _number('SELECT count(*) FROM reservations', {});

  @override
  Future<bool> hasOverlap(Room room, DateRange stay) async =>
      await _number('SELECT count(*) $confirmedOverlaps', _overlapValues(room, stay)) > 0;

  // INSERT now: a second R101 is refused here.
  @override
  Future<void> save(Reservation reservation) => _pool.execute(
          Sql.named('INSERT INTO reservations '
              'VALUES (@id, @name, @email, @room, @checkIn:date, @checkOut:date, @status)'),
          parameters: {
            'id': reservation.id,
            'name': reservation.guest.name,
            'email': reservation.guest.email,
            'room': reservation.room.number,
            'checkIn': reservation.stay.checkIn,
            'checkOut': reservation.stay.checkOut,
            'status': statusName(reservation.status),
          });

  // Returns null when no reservation has that id.
  @override
  Future<Reservation?> find(String id) async {
    final rows = await _pool.execute(
        Sql.named('SELECT guest_name, guest_email, room, check_in, check_out, status '
            'FROM reservations WHERE id = @id'),
        parameters: {'id': id});
    if (rows.isEmpty) return null;
    final [guestName, guestEmail, roomNumber, checkIn, checkOut, status] = rows.first;
    final room = _rooms.firstWhere((room) => room.number == roomNumber);
    final reservation = Reservation(id, Guest(guestName as String, guestEmail as String), room,
        DateRange(checkIn as DateTime, checkOut as DateTime));
    if (status == 'Cancelled') reservation.cancel();
    _loaded[reservation] = reservation.status;
    return reservation;
  }

  @override
  Future<int> countConfirmed(Room room, DateRange stay) =>
      _number('SELECT count(*) $confirmedOverlaps', _overlapValues(room, stay));

  // The end of the request: write the status of every loaded reservation that changed.
  Future<void> saveChanges() async {
    for (final MapEntry(key: reservation, value: statusInDatabase) in _loaded.entries) {
      if (reservation.status != statusInDatabase) {
        await _pool.execute(Sql.named('UPDATE reservations SET status = @status WHERE id = @id'),
            parameters: {'status': statusName(reservation.status), 'id': reservation.id});
      }
    }
  }

  Map<String, Object> _overlapValues(Room room, DateRange stay) =>
      {'room': room.number, 'checkIn': stay.checkIn, 'checkOut': stay.checkOut};

  Future<int> _number(String sql, Map<String, Object> values) async =>
      (await _pool.execute(Sql.named(sql), parameters: values)).first.first as int;
}

// The status as the reservations table writes it: Confirmed or Cancelled.
String statusName(ReservationStatus status) =>
    status == ReservationStatus.confirmed ? 'Confirmed' : 'Cancelled';
