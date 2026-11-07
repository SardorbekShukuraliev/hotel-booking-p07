import 'package:hotel_booking/rooms/rooms.dart';

// The stay: check-in day included, check-out day excluded (half-open).
class DateRange {
  DateRange(this.checkIn, this.checkOut);

  final DateTime checkIn;
  final DateTime checkOut;

  bool isValid() => checkOut.isAfter(checkIn);

  // Two stays overlap when they share at least one night.
  bool overlaps(DateRange other) =>
      checkIn.isBefore(other.checkOut) && other.checkIn.isBefore(checkOut);
}

class Guest {
  Guest(this.name, this.email);

  final String name;
  final String email;
}

enum ReservationStatus { confirmed, cancelled }

class Reservation {
  Reservation(this.id, this.guest, this.room, this.stay);

  final String id;
  final Guest guest;
  final Room room;
  final DateRange stay;
  ReservationStatus status = ReservationStatus.confirmed;

  // A reservation blocks a request when it is still Confirmed for the same room and shares a night.
  bool blocks(Room room, DateRange stay) =>
      status == ReservationStatus.confirmed && this.room == room && this.stay.overlaps(stay);

  bool cancel() {
    if (status == ReservationStatus.cancelled) return false;
    status = ReservationStatus.cancelled;
    return true;
  }
}
