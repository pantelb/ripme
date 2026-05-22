import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/ripper_factory.dart';
import 'package:ripme/ripper/ripper_migration_catalog.dart';
import 'package:ripme/ripper/rippers/allporncomic_ripper.dart';
import 'package:ripme/ripper/rippers/artstation_ripper.dart';
import 'package:ripme/ripper/rippers/artstn_ripper.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';
import 'package:ripme/ripper/rippers/reddit_ripper.dart';
import 'package:ripme/ripper/rippers/redgifs_ripper.dart';
import 'package:ripme/ripper/rippers/twitter_ripper.dart';
import 'package:ripme/ripper/unsupported_legacy_ripper.dart';

void main() {
  test('ported URLs still resolve to their Dart ripper', () {
    final allporncomic = RipperFactory.getRipper(
        Uri.parse('https://allporncomic.com/porncomic/title/chapter/'));
    final artstation = RipperFactory.getRipper(
        Uri.parse('https://www.artstation.com/artwork/abc123'));
    final artstn =
        RipperFactory.getRipper(Uri.parse('https://artstn.co/p/JlE15Z'));
    final imgur =
        RipperFactory.getRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    final reddit =
        RipperFactory.getRipper(Uri.parse('https://www.reddit.com/r/pics'));
    final redgifs =
        RipperFactory.getRipper(Uri.parse('https://www.redgifs.com/watch/abc'));

    expect(allporncomic, isA<AllporncomicRipper>());
    expect(artstation, isA<ArtStationRipper>());
    expect(artstn, isA<ArtstnRipper>());
    expect(imgur, isA<ImgurRipper>());
    expect(reddit, isA<RedditRipper>());
    expect(redgifs, isA<RedgifsRipper>());
  });

  test('known Java-only URLs resolve to an explicit unsupported legacy ripper',
      () {
    final ripper = RipperFactory.getRipper(
        Uri.parse('https://www.deviantart.com/example/gallery'));

    expect(ripper, isA<UnsupportedLegacyRipper>());
    expect((ripper as UnsupportedLegacyRipper).match.javaClass,
        'DeviantartRipper');
  });

  test('partially implemented rippers return their actual class', () {
    final imgur =
        RipperFactory.getRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    final twitter =
        RipperFactory.getRipper(Uri.parse('https://x.com/example/status/123'));

    expect(imgur, isA<ImgurRipper>());
    expect(twitter, isA<TwitterRipper>());
  });

  test('migration catalog tracks feature parity progress', () {
    expect(RipperMigrationCatalog.totalLegacyRippers, 116);
    expect(RipperMigrationCatalog.portedRipperCount, 8);
    expect(RipperMigrationCatalog.unportedRipperCount, 108);
  });
}
