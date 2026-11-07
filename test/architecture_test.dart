// The three borders between the modules. Run them with the other tests:  dart test
import 'dart:io';

import 'package:test/test.dart';

typedef Use = ({String file, String import, String module, bool internal});

/// Every import in one module's code: the module it points into ("rooms", "reservations" ...)
/// and whether it reaches that module's src/ folder.
List<Use> importsOf(String module) {
  final uses = <Use>[];
  for (final entity in Directory('lib/$module').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final file = entity.path.replaceAll(r'\', '/');
    for (final match in RegExp(r"^import '([^']+)'", multiLine: true).allMatches(entity.readAsStringSync())) {
      final target = match[1]!;
      final ours = target.startsWith('package:hotel_booking/');
      if (!ours && target.contains(':')) continue; // dart:io, package:test and other packages
      final path = ours ? 'lib/${target.substring('package:hotel_booking/'.length)}' : Uri.parse(file).resolve(target).path;
      final parts = path.split('/'); // lib, module, then src or the contract file
      uses.add((file: file, import: target, module: parts[1], internal: parts[2] == 'src'));
    }
  }
  return uses;
}

void main() {
  test('Reservations uses only the public contracts of other modules', () {
    for (final use in importsOf('reservations')) {
      expect(use.module == 'reservations' || !use.internal, isTrue, reason: '${use.file} imports ${use.import}');
    }
  });

  test('Rooms does not depend on any other module', () {
    for (final use in importsOf('rooms')) {
      expect(['reservations', 'payments', 'notifications'], isNot(contains(use.module)),
          reason: '${use.file} imports ${use.import}');
    }
  });

  test('Payments and Notifications do not depend on Reservations', () {
    for (final use in [...importsOf('payments'), ...importsOf('notifications')]) {
      expect(use.module, isNot('reservations'), reason: '${use.file} imports ${use.import}');
    }
  });
}
