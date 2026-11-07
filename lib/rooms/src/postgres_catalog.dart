import 'package:postgres/postgres.dart';

import '../rooms.dart';

// Reads the hotel's rooms from the rooms table. Only bin/main.dart creates it.
class PostgresRoomCatalog implements RoomCatalog {
  PostgresRoomCatalog(this._pool);

  final Pool<void> _pool;

  @override
  Future<List<Room>> all() async {
    final rows = await _pool.execute('SELECT number, type FROM rooms');
    return [for (final [number, type] in rows) Room(number as String, type as String)];
  }
}
