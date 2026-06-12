import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/java_test_inventory.dart';

void main() {
  test('extracts unique Java test class names from source paths', () {
    expect(
      JavaTestInventory.classNamesFromPaths([
        'src/test/java/example/UtilsTest.java',
        'src/test/java/example/UIContextMenuTests.java',
        'README.md',
      ]),
      {'UtilsTest', 'UIContextMenuTests'},
    );
  });

  test('derives direct Dart test stems with Java acronym behavior', () {
    expect(JavaTestInventory.directDartStem('E621RipperTest'), 'e621_ripper');
    expect(
      JavaTestInventory.directDartStem('NsfwXxxRipperTest'),
      'nsfw_xxx_ripper',
    );
    expect(
      JavaTestInventory.directDartStem('RipStatusMessageTest'),
      'rip_status_message',
    );
  });

  test('uses explicit aliases for naming and broader integration coverage', () {
    expect(
      JavaTestInventory.coverageStem('ArtStationRipperTest'),
      'artstation_ripper',
    );
    expect(
      JavaTestInventory.coverageStem('UIContextMenuTests'),
      'text_field_context_actions',
    );
    expect(
      JavaTestInventory.coverageStem('BaraagRipperTest'),
      'mastodon_ripper',
    );
  });
}
