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
import 'rippers/free_comic_online_ripper.dart';
import 'rippers/furaffinity_ripper.dart';
import 'rippers/fuskator_ripper.dart';
import 'rippers/girls_of_desire_ripper.dart';
import 'rippers/hentai2read_ripper.dart';
import 'rippers/hentai_nexus_ripper.dart';
import 'rippers/hentaifoundry_ripper.dart';
import 'rippers/hentaifox_ripper.dart';
import 'rippers/hentaiimage_ripper.dart';
import 'rippers/hitomi_ripper.dart';
import 'rippers/hqporner_ripper.dart';
import 'rippers/hypnohub_ripper.dart';
import 'rippers/imagebam_ripper.dart';
import 'rippers/imagefap_ripper.dart';
import 'rippers/imagevenue_ripper.dart';
import 'rippers/imgbox_ripper.dart';
import 'rippers/imgur_ripper.dart';
import 'rippers/instagram_ripper.dart';
import 'rippers/jabarchives_ripper.dart';
import 'rippers/jagodibuja_ripper.dart';
import 'rippers/jpg3_ripper.dart';
import 'rippers/kingcomix_ripper.dart';
import 'rippers/listal_ripper.dart';
import 'rippers/luscious_ripper.dart';
import 'rippers/mangadex_ripper.dart';
import 'rippers/mastodon_ripper.dart';
import 'rippers/mastodon_xyz_ripper.dart';
import 'rippers/modelmayhem_ripper.dart';
import 'rippers/motherless_ripper.dart';
import 'rippers/motherless_video_ripper.dart';
import 'rippers/mrcong_ripper.dart';
import 'rippers/multporn_ripper.dart';
import 'rippers/myhentaicomics_ripper.dart';
import 'rippers/myhentaigallery_ripper.dart';
import 'rippers/myreadingmanga_ripper.dart';
import 'rippers/natalie_mu_ripper.dart';
import 'rippers/newgrounds_ripper.dart';
import 'rippers/nfsfw_ripper.dart';
import 'rippers/nsfw_album_ripper.dart';
import 'rippers/nsfw_xxx_ripper.dart';
import 'rippers/nude_gals_ripper.dart';
import 'rippers/nhentai_ripper.dart';
import 'rippers/oglaf_ripper.dart';
import 'rippers/paheal_ripper.dart';
import 'rippers/pawoo_ripper.dart';
import 'rippers/photobucket_ripper.dart';
import 'rippers/pichunter_ripper.dart';
import 'rippers/picstatio_ripper.dart';
import 'rippers/porncomix_ripper.dart';
import 'rippers/porncomixinfo_ripper.dart';
import 'rippers/pornhub_ripper.dart';
import 'rippers/pornpics_ripper.dart';
import 'rippers/readcomic_ripper.dart';
import 'rippers/reddit_ripper.dart';
import 'rippers/redgifs_ripper.dart';
import 'rippers/rule34_ripper.dart';
import 'rippers/ruleporn_ripper.dart';
import 'rippers/sankaku_complex_ripper.dart';
import 'rippers/scrolller_ripper.dart';
import 'rippers/shesfreaky_ripper.dart';
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
    if (host.endsWith('freecomiconline.me')) {
      return FreeComicOnlineRipper(uri);
    }
    if (host.endsWith('furaffinity.net')) return FuraffinityRipper(uri);
    if (host.endsWith('fuskator.com')) return FuskatorRipper(uri);
    if (host.endsWith('girlsofdesire.org')) {
      return GirlsOfDesireRipper(uri);
    }
    if (host.endsWith('hentai2read.com')) return Hentai2readRipper(uri);
    if (host.endsWith('hentainexus.com')) return HentaiNexusRipper(uri);
    if (host.endsWith('hentai-foundry.com')) {
      return HentaifoundryRipper(uri);
    }
    if (host.endsWith('hentaifox.com')) return HentaifoxRipper(uri);
    final hentaiimageRipper = HentaiimageRipper(uri);
    if (hentaiimageRipper.canRip(uri)) return hentaiimageRipper;
    final hitomiRipper = HitomiRipper(uri);
    if (hitomiRipper.canRip(uri)) return hitomiRipper;
    final hqpornerRipper = HqpornerRipper(uri);
    if (hqpornerRipper.canRip(uri)) return hqpornerRipper;
    if (host.endsWith('hypnohub.net')) return HypnohubRipper(uri);
    if (host.endsWith('imagebam.com')) return ImagebamRipper(uri);
    if (host.endsWith('imagevenue.com')) return ImagevenueRipper(uri);
    if (host.endsWith('imgbox.com')) return ImgboxRipper(uri);
    if (host.contains('8muses.com')) return EightmusesRipper(uri);
    if (host.contains('flickr.com')) return FlickrRipper(uri);
    if (host.contains('imagefap.com')) return ImagefapRipper(uri);
    if (host.contains('imgur.com')) return ImgurRipper(uri);
    if (host.contains('instagram.com')) return InstagramRipper(uri);
    if (host.endsWith('jabarchives.com')) return JabArchivesRipper(uri);
    if (host.endsWith('jagodibuja.com')) return JagodibujaRipper(uri);
    if (host.endsWith('jpg3.su')) return Jpg3Ripper(uri);
    if (host.endsWith('kingcomix.com')) return KingcomixRipper(uri);
    if (host.endsWith('listal.com')) return ListalRipper(uri);
    final lusciousRipper = LusciousRipper(uri);
    if (lusciousRipper.canRip(uri)) return lusciousRipper;
    if (host.endsWith('mangadex.org')) return MangadexRipper(uri);
    if (host.contains('mastodon.social')) return MastodonRipper(uri);
    if (host.contains('mastodon.xyz')) return MastodonXyzRipper(uri);
    if (host.endsWith('modelmayhem.com')) return ModelmayhemRipper(uri);
    if (host.contains('motherless.com')) {
      final motherlessRipper = MotherlessRipper(uri);
      if (motherlessRipper.canRip(uri)) return motherlessRipper;
      final motherlessVideoRipper = MotherlessVideoRipper(uri);
      if (motherlessVideoRipper.canRip(uri)) return motherlessVideoRipper;
    }
    if (host.endsWith('misskon.com')) return MrCongRipper(uri);
    if (host.endsWith('multporn.net')) return MultpornRipper(uri);
    if (host.endsWith('myhentaicomics.com')) {
      return MyhentaicomicsRipper(uri);
    }
    if (host.endsWith('myhentaigallery.com')) {
      return MyhentaigalleryRipper(uri);
    }
    if (host.endsWith('myreadingmanga.info')) {
      return MyreadingmangaRipper(uri);
    }
    if (host.contains('natalie.mu')) {
      final natalieMuRipper = NatalieMuRipper(uri);
      if (natalieMuRipper.canRip(uri)) return natalieMuRipper;
    }
    if (host.endsWith('newgrounds.com')) return NewgroundsRipper(uri);
    if (host.endsWith('nfsfw.com')) return NfsfwRipper(uri);
    if (host.endsWith('nsfwalbum.com')) return NsfwAlbumRipper(uri);
    if (host.endsWith('nsfw.xxx')) return NsfwXxxRipper(uri);
    if (host.endsWith('nude-gals.com')) return NudeGalsRipper(uri);
    if (host.contains('nhentai.net')) return NhentaiRipper(uri);
    if (host.endsWith('oglaf.com')) return OglafRipper(uri);
    if (host.endsWith('rule34.paheal.net')) return PahealRipper(uri);
    if (host.contains('pawoo.net')) return PawooRipper(uri);
    final photobucketRipper = PhotobucketRipper(uri);
    if (photobucketRipper.canRip(uri)) return photobucketRipper;
    final pichunterRipper = PichunterRipper(uri);
    if (pichunterRipper.canRip(uri)) return pichunterRipper;
    final picstatioRipper = PicstatioRipper(uri);
    if (picstatioRipper.canRip(uri)) return picstatioRipper;
    final porncomixRipper = PorncomixRipper(uri);
    if (porncomixRipper.canRip(uri)) return porncomixRipper;
    final porncomixinfoRipper = PorncomixinfoRipper(uri);
    if (porncomixinfoRipper.canRip(uri)) return porncomixinfoRipper;
    final pornhubRipper = PornhubRipper(uri);
    if (pornhubRipper.canRip(uri)) return pornhubRipper;
    final pornpicsRipper = PornpicsRipper(uri);
    if (pornpicsRipper.canRip(uri)) return pornpicsRipper;
    final readcomicRipper = ReadcomicRipper(uri);
    if (readcomicRipper.canRip(uri)) return readcomicRipper;
    if (host.contains('reddit.com')) return RedditRipper(uri);
    if (host.contains('redgifs.com') ||
        host.contains('gifdeliverynetwork.com')) {
      return RedgifsRipper(uri);
    }
    final rule34Ripper = Rule34Ripper(uri);
    if (rule34Ripper.canRip(uri)) return rule34Ripper;
    final rulepornRipper = RulePornRipper(uri);
    if (rulepornRipper.canRip(uri)) return rulepornRipper;
    final sankakuComplexRipper = SankakuComplexRipper(uri);
    if (sankakuComplexRipper.canRip(uri)) return sankakuComplexRipper;
    final scrolllerRipper = ScrolllerRipper(uri);
    if (scrolllerRipper.canRip(uri)) return scrolllerRipper;
    final shesFreakyRipper = ShesFreakyRipper(uri);
    if (shesFreakyRipper.canRip(uri)) return shesFreakyRipper;
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
