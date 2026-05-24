import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/ripper_factory.dart';
import 'package:ripme/ripper/ripper_migration_catalog.dart';
import 'package:ripme/ripper/rippers/allporncomic_ripper.dart';
import 'package:ripme/ripper/rippers/artstation_ripper.dart';
import 'package:ripme/ripper/rippers/artstn_ripper.dart';
import 'package:ripme/ripper/rippers/eightmuses_ripper.dart';
import 'package:ripme/ripper/rippers/flickr_ripper.dart';
import 'package:ripme/ripper/rippers/imagefap_ripper.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';
import 'package:ripme/ripper/rippers/instagram_ripper.dart';
import 'package:ripme/ripper/rippers/motherless_ripper.dart';
import 'package:ripme/ripper/rippers/nhentai_ripper.dart';
import 'package:ripme/ripper/rippers/reddit_ripper.dart';
import 'package:ripme/ripper/rippers/redgifs_ripper.dart';
import 'package:ripme/ripper/rippers/tumblr_ripper.dart';
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
    final eightmuses = RipperFactory.getRipper(
        Uri.parse('https://www.8muses.com/comics/album/example'));
    final flickr = RipperFactory.getRipper(
        Uri.parse('https://www.flickr.com/photos/user/sets/12345/'));
    final imagefap = RipperFactory.getRipper(
        Uri.parse('https://www.imagefap.com/gallery/abcdef12'));
    final imgur =
        RipperFactory.getRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    final instagram =
        RipperFactory.getRipper(Uri.parse('https://www.instagram.com/p/abc/'));
    final motherless =
        RipperFactory.getRipper(Uri.parse('https://motherless.com/GABCDEF1'));
    final nhentai =
        RipperFactory.getRipper(Uri.parse('https://nhentai.net/g/123456/'));
    final reddit =
        RipperFactory.getRipper(Uri.parse('https://www.reddit.com/r/pics'));
    final redgifs =
        RipperFactory.getRipper(Uri.parse('https://www.redgifs.com/watch/abc'));
    final tumblr =
        RipperFactory.getRipper(Uri.parse('https://example.tumblr.com/post/1'));
    final twitter = RipperFactory.getRipper(Uri.parse('https://x.com/example'));

    expect(allporncomic, isA<AllporncomicRipper>());
    expect(artstation, isA<ArtStationRipper>());
    expect(artstn, isA<ArtstnRipper>());
    expect(eightmuses, isA<EightmusesRipper>());
    expect(flickr, isA<FlickrRipper>());
    expect(imagefap, isA<ImagefapRipper>());
    expect(imgur, isA<ImgurRipper>());
    expect(instagram, isA<InstagramRipper>());
    expect(motherless, isA<MotherlessRipper>());
    expect(nhentai, isA<NhentaiRipper>());
    expect(reddit, isA<RedditRipper>());
    expect(redgifs, isA<RedgifsRipper>());
    expect(tumblr, isA<TumblrRipper>());
    expect(twitter, isA<TwitterRipper>());
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
    expect(RipperMigrationCatalog.portedRipperCount, 14);
    expect(RipperMigrationCatalog.unportedRipperCount, 102);
  });
}
