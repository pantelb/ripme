import '../ripper/abstract_ripper.dart';
import 'ripper_migration_catalog.dart';
import 'rippers/allporncomic_ripper.dart';
import 'rippers/artstation_ripper.dart';
import 'rippers/artstn_ripper.dart';
import 'rippers/baraag_ripper.dart';
import 'rippers/bato_ripper.dart';
import 'rippers/booru_ripper.dart';
import 'rippers/cfake_ripper.dart';
import 'rippers/chan_ripper.dart';
import 'rippers/chevereto_ripper.dart';
import 'rippers/cliphunter_ripper.dart';
import 'rippers/coomer_party_ripper.dart';
import 'rippers/danbooru_ripper.dart';
import 'rippers/derpi_ripper.dart';
import 'rippers/deviantart_ripper.dart';
import 'rippers/dribbble_ripper.dart';
import 'rippers/dynastyscans_ripper.dart';
import 'rippers/e621_ripper.dart';
import 'rippers/eightmuses_ripper.dart';
import 'rippers/ehentai_ripper.dart';
import 'rippers/erome_ripper.dart';
import 'rippers/fapdungeon_ripper.dart';
import 'rippers/fapwiz_ripper.dart';
import 'rippers/femjoyhunter_ripper.dart';
import 'rippers/fitnakedgirls_ripper.dart';
import 'rippers/fivehundredpx_ripper.dart';
import 'rippers/flickr_ripper.dart';
import 'rippers/imagefap_ripper.dart';
import 'rippers/imgur_ripper.dart';
import 'rippers/instagram_ripper.dart';
import 'rippers/mastodon_ripper.dart';
import 'rippers/mastodon_xyz_ripper.dart';
import 'rippers/motherless_ripper.dart';
import 'rippers/nhentai_ripper.dart';
import 'rippers/reddit_ripper.dart';
import 'rippers/redgifs_ripper.dart';
import 'rippers/tumblr_ripper.dart';
import 'rippers/twitter_ripper.dart';
import 'unsupported_legacy_ripper.dart';

class RipperFactory {
  static AbstractRipper? getRipper(Uri uri) {
    String host = uri.host.toLowerCase();
    if (host.contains('allporncomic.com')) return AllporncomicRipper(uri);
    if (host.contains('artstation.com')) return ArtStationRipper(uri);
    if (host.contains('artstn.co')) return ArtstnRipper(uri);
    if (host.contains('baraag.net')) return BaraagRipper(uri);
    if (host.contains('bato.to')) return BatoRipper(uri);
    if (host.contains('xbooru.com') || host.contains('gelbooru.com')) {
      return BooruRipper(uri);
    }
    if (host == 'cfake.com') return CfakeRipper(uri);
    final chanRipper = ChanRipper(uri);
    if (chanRipper.canRip(uri)) return chanRipper;
    if (CheveretoRipper.explicitDomains.contains(host)) {
      return CheveretoRipper(uri);
    }
    if (host.contains('cliphunter.com')) return CliphunterRipper(uri);
    if (host.endsWith('coomer.party') || host.endsWith('coomer.su')) {
      return CoomerPartyRipper(uri);
    }
    if (host.endsWith('danbooru.donmai.us')) return DanbooruRipper(uri);
    if (host.endsWith('derpibooru.org')) return DerpiRipper(uri);
    if (host.endsWith('deviantart.com')) return DeviantartRipper(uri);
    if (host.endsWith('dribbble.com')) return DribbbleRipper(uri);
    if (host.endsWith('dynasty-scans.com')) return DynastyscansRipper(uri);
    if (host.endsWith('e621.net')) return E621Ripper(uri);
    if (host.endsWith('e-hentai.org')) return EHentaiRipper(uri);
    if (host.endsWith('erome.com')) return EromeRipper(uri);
    if (host.endsWith('fapdungeon.com')) return FapDungeonRipper(uri);
    if (host.endsWith('fapwiz.com')) return FapwizRipper(uri);
    if (host.endsWith('femjoyhunter.com')) return FemjoyhunterRipper(uri);
    if (host.endsWith('fitnakedgirls.com')) return FitnakedgirlsRipper(uri);
    if (host.endsWith('500px.com')) return FivehundredpxRipper(uri);
    if (host.contains('8muses.com')) return EightmusesRipper(uri);
    if (host.contains('flickr.com')) return FlickrRipper(uri);
    if (host.contains('imagefap.com')) return ImagefapRipper(uri);
    if (host.contains('imgur.com')) return ImgurRipper(uri);
    if (host.contains('instagram.com')) return InstagramRipper(uri);
    if (host.contains('mastodon.social')) return MastodonRipper(uri);
    if (host.contains('mastodon.xyz')) return MastodonXyzRipper(uri);
    if (host.contains('motherless.com')) return MotherlessRipper(uri);
    if (host.contains('nhentai.net')) return NhentaiRipper(uri);
    if (host.contains('reddit.com')) return RedditRipper(uri);
    if (host.contains('redgifs.com') ||
        host.contains('gifdeliverynetwork.com')) {
      return RedgifsRipper(uri);
    }
    if (host.contains('tumblr.com')) return TumblrRipper(uri);
    if (host.endsWith('twitter.com') ||
        host == 'x.com' ||
        host.endsWith('.x.com')) {
      return TwitterRipper(uri);
    }

    final legacyMatch = RipperMigrationCatalog.findUnportedLegacyRipper(uri);
    if (legacyMatch != null) return UnsupportedLegacyRipper(uri, legacyMatch);

    return null;
  }
}
