/// Rooms: which rooms the hotel sells. This file is the module's public contract.
library;

import 'dart:async';

class Room {
  Room(this.number, this.type);

  final String number;
  final String type;

  // Dart compares objects by identity until a class says what equal means.
  @override
  bool operator ==(Object other) => other is Room && other.number == number && other.type == type;

  @override
  int get hashCode => Object.hash(number, type);
}

// Rooms' public contract: which rooms the hotel sells. A list answers at once, the database later.
abstract interface class RoomCatalog {
  FutureOr<List<Room>> all();
}
