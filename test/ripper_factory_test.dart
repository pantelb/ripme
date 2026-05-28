import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/ripper_factory.dart';
import 'package:ripme/ripper/ripper_migration_catalog.dart';
import 'package:ripme/ripper/rippers/allporncomic_ripper.dart';
import 'package:ripme/ripper/rippers/artstation_ripper.dart';
import 'package:ripme/ripper/rippers/artstn_ripper.dart';
import 'package:ripme/ripper/rippers/baraag_ripper.dart';
import 'package:ripme/ripper/rippers/bato_ripper.dart';
import 'package:ripme/ripper/rippers/booru_ripper.dart';
import 'package:ripme/ripper/rippers/cfake_ripper.dart';
import 'package:ripme/ripper/rippers/chan_ripper.dart';
import 'package:ripme/ripper/rippers/chevereto_ripper.dart';
import 'package:ripme/ripper/rippers/cliphunter_ripper.dart';
import 'package:ripme/ripper/rippers/coomer_party_ripper.dart';
import 'package:ripme/ripper/rippers/danbooru_ripper.dart';
import 'package:ripme/ripper/rippers/derpi_ripper.dart';
import 'package:ripme/ripper/rippers/deviantart_ripper.dart';
import 'package:ripme/ripper/rippers/dribbble_ripper.dart';
import 'package:ripme/ripper/rippers/dynastyscans_ripper.dart';
import 'package:ripme/ripper/rippers/e621_ripper.dart';
import 'package:ripme/ripper/rippers/eightmuses_ripper.dart';
import 'package:ripme/ripper/rippers/ehentai_ripper.dart';
import 'package:ripme/ripper/rippers/flickr_ripper.dart';
import 'package:ripme/ripper/rippers/imagefap_ripper.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';
import 'package:ripme/ripper/rippers/instagram_ripper.dart';
import 'package:ripme/ripper/rippers/mastodon_ripper.dart';
import 'package:ripme/ripper/rippers/mastodon_xyz_ripper.dart';
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
      Uri.parse('https://allporncomic.com/porncomic/title/chapter/'),
    );
    final artstation = RipperFactory.getRipper(
      Uri.parse('https://www.artstation.com/artwork/abc123'),
    );
    final artstn = RipperFactory.getRipper(
      Uri.parse('https://artstn.co/p/JlE15Z'),
    );
    final baraag = RipperFactory.getRipper(
      Uri.parse('https://baraag.net/@artist'),
    );
    final bato = RipperFactory.getRipper(
      Uri.parse('https://bato.to/chapter/12345/'),
    );
    final booru = RipperFactory.getRipper(
      Uri.parse('https://xbooru.com/index.php?page=post&s=list&tags=furry'),
    );
    final cfake = RipperFactory.getRipper(
      Uri.parse('https://cfake.com/images/celebrity/Zooey_Deschanel/1264'),
    );
    final chan = RipperFactory.getRipper(
      Uri.parse('https://boards.4chan.org/hr/thread/3015701'),
    );
    final chevereto = RipperFactory.getRipper(
      Uri.parse('https://kenzato.uk/album/TnEc'),
    );
    final cliphunter = RipperFactory.getRipper(
      Uri.parse('https://www.cliphunter.com/w/12345/example-video'),
    );
    final coomer = RipperFactory.getRipper(
      Uri.parse('https://coomer.su/onlyfans/user/soogsx'),
    );
    final danbooru = RipperFactory.getRipper(
      Uri.parse('https://danbooru.donmai.us/posts?tags=brown_necktie'),
    );
    final derpi = RipperFactory.getRipper(
      Uri.parse('https://derpibooru.org/search?q=twilight+sparkle'),
    );
    final deviantart = RipperFactory.getRipper(
      Uri.parse(
          'https://www.deviantart.com/apofiss/gallery/41388863/sceneries'),
    );
    final dribbble = RipperFactory.getRipper(
      Uri.parse('https://dribbble.com/typogriff'),
    );
    final dynastyscans = RipperFactory.getRipper(
      Uri.parse('https://dynasty-scans.com/chapters/under_one_roof_ch01'),
    );
    final e621 = RipperFactory.getRipper(
      Uri.parse('https://e621.net/posts?tags=beach'),
    );
    final ehentai = RipperFactory.getRipper(
      Uri.parse('https://e-hentai.org/g/1144492/e823bdf9a5/'),
    );
    final eightmuses = RipperFactory.getRipper(
      Uri.parse('https://www.8muses.com/comics/album/example'),
    );
    final flickr = RipperFactory.getRipper(
      Uri.parse('https://www.flickr.com/photos/user/sets/12345/'),
    );
    final imagefap = RipperFactory.getRipper(
      Uri.parse('https://www.imagefap.com/gallery/abcdef12'),
    );
    final imgur = RipperFactory.getRipper(
      Uri.parse('https://imgur.com/a/G058j5F'),
    );
    final instagram = RipperFactory.getRipper(
      Uri.parse('https://www.instagram.com/p/abc/'),
    );
    final mastodon = RipperFactory.getRipper(
      Uri.parse('https://mastodon.social/@alice'),
    );
    final mastodonXyz = RipperFactory.getRipper(
      Uri.parse('https://mastodon.xyz/@bob'),
    );
    final motherless = RipperFactory.getRipper(
      Uri.parse('https://motherless.com/GABCDEF1'),
    );
    final nhentai = RipperFactory.getRipper(
      Uri.parse('https://nhentai.net/g/123456/'),
    );
    final reddit = RipperFactory.getRipper(
      Uri.parse('https://www.reddit.com/r/pics'),
    );
    final redgifs = RipperFactory.getRipper(
      Uri.parse('https://www.redgifs.com/watch/abc'),
    );
    final tumblr = RipperFactory.getRipper(
      Uri.parse('https://example.tumblr.com/post/1'),
    );
    final twitter = RipperFactory.getRipper(Uri.parse('https://x.com/example'));

    expect(allporncomic, isA<AllporncomicRipper>());
    expect(artstation, isA<ArtStationRipper>());
    expect(artstn, isA<ArtstnRipper>());
    expect(baraag, isA<BaraagRipper>());
    expect(bato, isA<BatoRipper>());
    expect(booru, isA<BooruRipper>());
    expect(cfake, isA<CfakeRipper>());
    expect(chan, isA<ChanRipper>());
    expect(chevereto, isA<CheveretoRipper>());
    expect(cliphunter, isA<CliphunterRipper>());
    expect(coomer, isA<CoomerPartyRipper>());
    expect(danbooru, isA<DanbooruRipper>());
    expect(derpi, isA<DerpiRipper>());
    expect(deviantart, isA<DeviantartRipper>());
    expect(dribbble, isA<DribbbleRipper>());
    expect(dynastyscans, isA<DynastyscansRipper>());
    expect(e621, isA<E621Ripper>());
    expect(ehentai, isA<EHentaiRipper>());
    expect(eightmuses, isA<EightmusesRipper>());
    expect(flickr, isA<FlickrRipper>());
    expect(imagefap, isA<ImagefapRipper>());
    expect(imgur, isA<ImgurRipper>());
    expect(instagram, isA<InstagramRipper>());
    expect(mastodon, isA<MastodonRipper>());
    expect(mastodonXyz, isA<MastodonXyzRipper>());
    expect(motherless, isA<MotherlessRipper>());
    expect(nhentai, isA<NhentaiRipper>());
    expect(reddit, isA<RedditRipper>());
    expect(redgifs, isA<RedgifsRipper>());
    expect(tumblr, isA<TumblrRipper>());
    expect(twitter, isA<TwitterRipper>());
  });

  test(
    'known Java-only URLs resolve to an explicit unsupported legacy ripper',
    () {
      final ripper = RipperFactory.getRipper(
        Uri.parse('https://erome.com/a/albumid'),
      );

      expect(ripper, isA<UnsupportedLegacyRipper>());
      expect(
        (ripper as UnsupportedLegacyRipper).match.javaClass,
        'EromeRipper',
      );
    },
  );

  test('migration catalog tracks feature parity progress', () {
    expect(RipperMigrationCatalog.totalLegacyRippers, 116);
    expect(RipperMigrationCatalog.portedRipperCount, 31);
    expect(RipperMigrationCatalog.unportedRipperCount, 85);
  });
}
