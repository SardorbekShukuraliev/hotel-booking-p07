import '../rooms.dart';

// Keeps the hotel's rooms in a list. Only bin/main.dart creates it.
class InMemoryRoomCatalog implements RoomCatalog {
  InMemoryRoomCatalog(List<Room> rooms) : _rooms = List.unmodifiable(rooms);

  final List<Room> _rooms;

  @override
  List<Room> all() => _rooms;
}
