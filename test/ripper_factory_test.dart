import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/ripper_factory.dart';
import 'package:ripme/ripper/ripper_migration_catalog.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';
import 'package:ripme/ripper/unsupported_legacy_ripper.dart';

void main() {
  test('ported URLs still resolve to their Dart ripper', () {
    final ripper =
        RipperFactory.getRipper(Uri.parse('https://imgur.com/a/G058j5F'));

    expect(ripper, isA<ImgurRipper>());
  });

  test('known Java-only URLs resolve to an explicit unsupported legacy ripper',
      () {
    final ripper = RipperFactory.getRipper(
        Uri.parse('https://www.deviantart.com/example/gallery'));

    expect(ripper, isA<UnsupportedLegacyRipper>());
    expect((ripper as UnsupportedLegacyRipper).match.javaClass,
        'DeviantartRipper');
  });

  test('migration catalog tracks feature parity progress', () {
    expect(RipperMigrationCatalog.totalLegacyRippers, 116);
    expect(RipperMigrationCatalog.portedRipperCount, 11);
    expect(RipperMigrationCatalog.unportedRipperCount, 105);
  });
}
