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
import 'rippers/erofus_ripper.dart';
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
import 'rippers/pornhub_video_ripper.dart';
import 'rippers/pornpics_ripper.dart';
import 'rippers/readcomic_ripper.dart';
import 'rippers/reddit_ripper.dart';
import 'rippers/redgifs_ripper.dart';
import 'rippers/rule34_ripper.dart';
import 'rippers/ruleporn_ripper.dart';
import 'rippers/sankaku_complex_ripper.dart';
import 'rippers/scrolller_ripper.dart';
import 'rippers/shesfreaky_ripper.dart';
import 'rippers/sinfest_ripper.dart';
import 'rippers/smutty_ripper.dart';
import 'rippers/soundgasm_ripper.dart';
import 'rippers/spankbang_ripper.dart';
import 'rippers/sta_ripper.dart';
import 'rippers/tapastic_ripper.dart';
import 'rippers/teenplanet_ripper.dart';
import 'rippers/thechive_ripper.dart';
import 'rippers/theyiffgallery_ripper.dart';
import 'rippers/tsumino_ripper.dart';
import 'rippers/tumblr_ripper.dart';
import 'rippers/twitch_video_ripper.dart';
import 'rippers/twodgalleries_ripper.dart';
import 'rippers/twitter_ripper.dart';
import 'rippers/vidble_ripper.dart';
import 'rippers/viddme_ripper.dart';
import 'rippers/videarn_ripper.dart';
import 'rippers/viewcomic_ripper.dart';
import 'rippers/vk_ripper.dart';
import 'rippers/vk_video_ripper.dart';
import 'rippers/vsco_ripper.dart';
import 'rippers/webtoons_ripper.dart';
import 'rippers/wordpress_comic_ripper.dart';
import 'rippers/xcartx_ripper.dart';
import 'rippers/xhamster_ripper.dart';
import 'rippers/xlecx_ripper.dart';
import 'rippers/xvideos_ripper.dart';
import 'rippers/youporn_ripper.dart';
import 'rippers/yuvutu_ripper.dart';
import 'rippers/yuvutu_video_ripper.dart';
import 'rippers/zizki_ripper.dart';
import 'unsupported_legacy_ripper.dart';

typedef _RipperBuilder = AbstractRipper Function(Uri uri);

class RipperFactory {
  static final List<_RipperBuilder> _portedRippers = [
    (uri) => AllporncomicRipper(uri),
    (uri) => ArtStationRipper(uri),
    (uri) => ArtstnRipper(uri),
    (uri) => BaraagRipper(uri),
    (uri) => BatoRipper(uri),
    (uri) => BooruRipper(uri),
    (uri) => CfakeRipper(uri),
    (uri) => ChanRipper(uri),
    (uri) => CheveretoRipper(uri),
    (uri) => CliphunterRipper(uri),
    (uri) => CoomerPartyRipper(uri),
    (uri) => DanbooruRipper(uri),
    (uri) => DerpiRipper(uri),
    (uri) => DeviantartRipper(uri),
    (uri) => DribbbleRipper(uri),
    (uri) => DynastyscansRipper(uri),
    (uri) => E621Ripper(uri),
    (uri) => EHentaiRipper(uri),
    (uri) => ErofusRipper(uri),
    (uri) => EromeRipper(uri),
    (uri) => FapDungeonRipper(uri),
    (uri) => FapwizRipper(uri),
    (uri) => FemjoyhunterRipper(uri),
    (uri) => FitnakedgirlsRipper(uri),
    (uri) => FivehundredpxRipper(uri),
    (uri) => FreeComicOnlineRipper(uri),
    (uri) => FuraffinityRipper(uri),
    (uri) => FuskatorRipper(uri),
    (uri) => GirlsOfDesireRipper(uri),
    (uri) => Hentai2readRipper(uri),
    (uri) => HentaiNexusRipper(uri),
    (uri) => HentaifoundryRipper(uri),
    (uri) => HentaifoxRipper(uri),
    (uri) => HentaiimageRipper(uri),
    (uri) => HitomiRipper(uri),
    (uri) => HqpornerRipper(uri),
    (uri) => HypnohubRipper(uri),
    (uri) => ImagebamRipper(uri),
    (uri) => ImagevenueRipper(uri),
    (uri) => ImgboxRipper(uri),
    (uri) => EightmusesRipper(uri),
    (uri) => FlickrRipper(uri),
    (uri) => ImagefapRipper(uri),
    (uri) => ImgurRipper(uri),
    (uri) => InstagramRipper(uri),
    (uri) => JabArchivesRipper(uri),
    (uri) => JagodibujaRipper(uri),
    (uri) => Jpg3Ripper(uri),
    (uri) => KingcomixRipper(uri),
    (uri) => ListalRipper(uri),
    (uri) => LusciousRipper(uri),
    (uri) => MangadexRipper(uri),
    (uri) => MastodonRipper(uri),
    (uri) => MastodonXyzRipper(uri),
    (uri) => ModelmayhemRipper(uri),
    (uri) => MotherlessRipper(uri),
    (uri) => MotherlessVideoRipper(uri),
    (uri) => MrCongRipper(uri),
    (uri) => MultpornRipper(uri),
    (uri) => MyhentaicomicsRipper(uri),
    (uri) => MyhentaigalleryRipper(uri),
    (uri) => MyreadingmangaRipper(uri),
    (uri) => NatalieMuRipper(uri),
    (uri) => NewgroundsRipper(uri),
    (uri) => NfsfwRipper(uri),
    (uri) => NsfwAlbumRipper(uri),
    (uri) => NsfwXxxRipper(uri),
    (uri) => NudeGalsRipper(uri),
    (uri) => NhentaiRipper(uri),
    (uri) => OglafRipper(uri),
    (uri) => PahealRipper(uri),
    (uri) => PawooRipper(uri),
    (uri) => PhotobucketRipper(uri),
    (uri) => PichunterRipper(uri),
    (uri) => PicstatioRipper(uri),
    (uri) => PorncomixRipper(uri),
    (uri) => PorncomixinfoRipper(uri),
    (uri) => PornhubRipper(uri),
    (uri) => PornhubVideoRipper(uri),
    (uri) => PornpicsRipper(uri),
    (uri) => ReadcomicRipper(uri),
    (uri) => RedditRipper(uri),
    (uri) => RedgifsRipper(uri),
    (uri) => Rule34Ripper(uri),
    (uri) => RulePornRipper(uri),
    (uri) => SankakuComplexRipper(uri),
    (uri) => ScrolllerRipper(uri),
    (uri) => ShesFreakyRipper(uri),
    (uri) => SinfestRipper(uri),
    (uri) => SmuttyRipper(uri),
    (uri) => SoundgasmRipper(uri),
    (uri) => SpankbangRipper(uri),
    (uri) => StaRipper(uri),
    (uri) => TapasticRipper(uri),
    (uri) => TeenplanetRipper(uri),
    (uri) => ThechiveRipper(uri),
    (uri) => TheyiffgalleryRipper(uri),
    (uri) => TsuminoRipper(uri),
    (uri) => TumblrRipper(uri),
    (uri) => TwitchVideoRipper(uri),
    (uri) => TwodgalleriesRipper(uri),
    (uri) => TwitterRipper(uri),
    (uri) => VidbleRipper(uri),
    (uri) => ViddmeRipper(uri),
    (uri) => VidearnRipper(uri),
    (uri) => ViewcomicRipper(uri),
    (uri) => VkRipper(uri),
    (uri) => VkVideoRipper(uri),
    (uri) => VscoRipper(uri),
    (uri) => WebtoonsRipper(uri),
    (uri) => WordpressComicRipper(uri),
    (uri) => XcartxRipper(uri),
    (uri) => XhamsterRipper(uri),
    (uri) => XlecxRipper(uri),
    (uri) => XvideosRipper(uri),
    (uri) => YoupornRipper(uri),
    (uri) => YuvutuRipper(uri),
    (uri) => YuvutuVideoRipper(uri),
    (uri) => ZizkiRipper(uri),
  ];

  static AbstractRipper? getRipper(Uri uri) {
    for (final buildRipper in _portedRippers) {
      try {
        final ripper = buildRipper(uri);
        if (ripper.canRip(uri)) return ripper;
      } on Exception {
        // Java dispatch catches incompatible constructor failures and keeps
        // scanning the remaining ripper constructors.
      }
    }

    final legacyMatch = RipperMigrationCatalog.findUnportedLegacyRipper(uri);
    if (legacyMatch != null) return UnsupportedLegacyRipper(uri, legacyMatch);

    return null;
  }
}
