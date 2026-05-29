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
import 'package:ripme/ripper/rippers/erome_ripper.dart';
import 'package:ripme/ripper/rippers/fapdungeon_ripper.dart';
import 'package:ripme/ripper/rippers/fapwiz_ripper.dart';
import 'package:ripme/ripper/rippers/femjoyhunter_ripper.dart';
import 'package:ripme/ripper/rippers/fitnakedgirls_ripper.dart';
import 'package:ripme/ripper/rippers/fivehundredpx_ripper.dart';
import 'package:ripme/ripper/rippers/flickr_ripper.dart';
import 'package:ripme/ripper/rippers/free_comic_online_ripper.dart';
import 'package:ripme/ripper/rippers/furaffinity_ripper.dart';
import 'package:ripme/ripper/rippers/fuskator_ripper.dart';
import 'package:ripme/ripper/rippers/girls_of_desire_ripper.dart';
import 'package:ripme/ripper/rippers/hentai2read_ripper.dart';
import 'package:ripme/ripper/rippers/hentai_nexus_ripper.dart';
import 'package:ripme/ripper/rippers/hentaifoundry_ripper.dart';
import 'package:ripme/ripper/rippers/hentaifox_ripper.dart';
import 'package:ripme/ripper/rippers/hentaiimage_ripper.dart';
import 'package:ripme/ripper/rippers/hitomi_ripper.dart';
import 'package:ripme/ripper/rippers/hqporner_ripper.dart';
import 'package:ripme/ripper/rippers/hypnohub_ripper.dart';
import 'package:ripme/ripper/rippers/imagebam_ripper.dart';
import 'package:ripme/ripper/rippers/imagefap_ripper.dart';
import 'package:ripme/ripper/rippers/imagevenue_ripper.dart';
import 'package:ripme/ripper/rippers/imgbox_ripper.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';
import 'package:ripme/ripper/rippers/instagram_ripper.dart';
import 'package:ripme/ripper/rippers/jabarchives_ripper.dart';
import 'package:ripme/ripper/rippers/jagodibuja_ripper.dart';
import 'package:ripme/ripper/rippers/jpg3_ripper.dart';
import 'package:ripme/ripper/rippers/kingcomix_ripper.dart';
import 'package:ripme/ripper/rippers/listal_ripper.dart';
import 'package:ripme/ripper/rippers/luscious_ripper.dart';
import 'package:ripme/ripper/rippers/mangadex_ripper.dart';
import 'package:ripme/ripper/rippers/mastodon_ripper.dart';
import 'package:ripme/ripper/rippers/mastodon_xyz_ripper.dart';
import 'package:ripme/ripper/rippers/modelmayhem_ripper.dart';
import 'package:ripme/ripper/rippers/motherless_ripper.dart';
import 'package:ripme/ripper/rippers/motherless_video_ripper.dart';
import 'package:ripme/ripper/rippers/mrcong_ripper.dart';
import 'package:ripme/ripper/rippers/multporn_ripper.dart';
import 'package:ripme/ripper/rippers/myhentaicomics_ripper.dart';
import 'package:ripme/ripper/rippers/myhentaigallery_ripper.dart';
import 'package:ripme/ripper/rippers/myreadingmanga_ripper.dart';
import 'package:ripme/ripper/rippers/natalie_mu_ripper.dart';
import 'package:ripme/ripper/rippers/newgrounds_ripper.dart';
import 'package:ripme/ripper/rippers/nfsfw_ripper.dart';
import 'package:ripme/ripper/rippers/nsfw_album_ripper.dart';
import 'package:ripme/ripper/rippers/nsfw_xxx_ripper.dart';
import 'package:ripme/ripper/rippers/nude_gals_ripper.dart';
import 'package:ripme/ripper/rippers/nhentai_ripper.dart';
import 'package:ripme/ripper/rippers/oglaf_ripper.dart';
import 'package:ripme/ripper/rippers/paheal_ripper.dart';
import 'package:ripme/ripper/rippers/pawoo_ripper.dart';
import 'package:ripme/ripper/rippers/photobucket_ripper.dart';
import 'package:ripme/ripper/rippers/pichunter_ripper.dart';
import 'package:ripme/ripper/rippers/picstatio_ripper.dart';
import 'package:ripme/ripper/rippers/porncomix_ripper.dart';
import 'package:ripme/ripper/rippers/porncomixinfo_ripper.dart';
import 'package:ripme/ripper/rippers/pornhub_ripper.dart';
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
    final erome = RipperFactory.getRipper(
      Uri.parse('https://erome.com/a/albumid'),
    );
    final fapDungeon = RipperFactory.getRipper(
      Uri.parse('https://fapdungeon.com/white/example-album/'),
    );
    final fapwiz = RipperFactory.getRipper(
      Uri.parse(
          'https://fapwiz.com/petiteasiantravels/riding-at-9-months-pregnant/'),
    );
    final femjoyhunter = RipperFactory.getRipper(
      Uri.parse('https://www.femjoyhunter.com/gallery-id/'),
    );
    final fitnakedgirls = RipperFactory.getRipper(
      Uri.parse('https://fitnakedgirls.com/photos/gallery/erin-ashford-nude/'),
    );
    final fivehundredpx = RipperFactory.getRipper(
      Uri.parse('https://500px.com/tsyganov'),
    );
    final freeComicOnline = RipperFactory.getRipper(
      Uri.parse('https://freecomiconline.me/comic/perfect-half/chapter-01/'),
    );
    final furaffinity = RipperFactory.getRipper(
      Uri.parse('https://www.furaffinity.net/gallery/mustardgas/'),
    );
    final fuskator = RipperFactory.getRipper(
      Uri.parse('https://fuskator.com/thumbs/hqt6pPXAf9z/example.html'),
    );
    final girlsOfDesire = RipperFactory.getRipper(
      Uri.parse('http://www.girlsofdesire.org/galleries/krillia/'),
    );
    final hentai2read = RipperFactory.getRipper(
      Uri.parse('https://hentai2read.com/sm_school_memorial/1/'),
    );
    final hentaiNexus = RipperFactory.getRipper(
      Uri.parse('https://hentainexus.com/view/9202#001'),
    );
    final hentaifoundry = RipperFactory.getRipper(
      Uri.parse('https://www.hentai-foundry.com/pictures/user/personalami'),
    );
    final hentaifox = RipperFactory.getRipper(
      Uri.parse('https://hentaifox.com/gallery/38544/'),
    );
    final hentaiimage = RipperFactory.getRipper(
      Uri.parse('https://hentai-img-xxx.com/image/example/'),
    );
    final hitomi = RipperFactory.getRipper(
      Uri.parse('https://hitomi.la/manga/example-gallery-123.html'),
    );
    final hqporner = RipperFactory.getRipper(
      Uri.parse('https://hqporner.com/actress/kali-roses'),
    );
    final hypnohub = RipperFactory.getRipper(
      Uri.parse('https://hypnohub.net/index.php?page=pool&s=show&id=6717'),
    );
    final imagebam = RipperFactory.getRipper(
      Uri.parse(
        'http://www.imagebam.com/gallery/488cc796sllyf7o5srds8kpaz1t4m78i',
      ),
    );
    final imagevenue = RipperFactory.getRipper(
      Uri.parse(
        'http://img120.imagevenue.com/galshow.php?gal=gallery_1373818527696_191lo',
      ),
    );
    final imgbox = RipperFactory.getRipper(
      Uri.parse('https://imgbox.com/g/FJPF7t26FD'),
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
    final jabArchives = RipperFactory.getRipper(
      Uri.parse('https://jabarchives.com/main/view/example_album'),
    );
    final jagodibuja = RipperFactory.getRipper(
      Uri.parse('https://www.jagodibuja.com/comic-in-me/'),
    );
    final jpg3 = RipperFactory.getRipper(
      Uri.parse('https://jpg3.su/a/abcdef'),
    );
    final kingcomix = RipperFactory.getRipper(
      Uri.parse('https://kingcomix.com/aunt-cumming-tracy-scops/'),
    );
    final listal = RipperFactory.getRipper(
      Uri.parse('https://www.listal.com/list/evolution-emma-stone'),
    );
    final luscious = RipperFactory.getRipper(
      Uri.parse('https://luscious.net/albums/my-album_12345/'),
    );
    final mangadex = RipperFactory.getRipper(
      Uri.parse('https://mangadex.org/chapter/467904/'),
    );
    final mastodon = RipperFactory.getRipper(
      Uri.parse('https://mastodon.social/@alice'),
    );
    final mastodonXyz = RipperFactory.getRipper(
      Uri.parse('https://mastodon.xyz/@bob'),
    );
    final modelmayhem = RipperFactory.getRipper(
      Uri.parse('https://www.modelmayhem.com/portfolio/123456/viewall'),
    );
    final motherless = RipperFactory.getRipper(
      Uri.parse('https://motherless.com/GABCDEF1'),
    );
    final motherlessVideo = RipperFactory.getRipper(
      Uri.parse('https://motherless.com/0D2D897'),
    );
    final mrCong = RipperFactory.getRipper(
      Uri.parse('https://misskon.com/xiaoyu-vol-799-lin-xing-lan-87-anh/'),
    );
    final multporn = RipperFactory.getRipper(
      Uri.parse('https://multporn.net/node/12345/example-comic'),
    );
    final myhentaicomics = RipperFactory.getRipper(
      Uri.parse('https://myhentaicomics.com/index.php/Nienna-Lost-Tales'),
    );
    final myhentaigallery = RipperFactory.getRipper(
      Uri.parse('https://myhentaigallery.com/gallery/thumbnails/9201'),
    );
    final myreadingmanga = RipperFactory.getRipper(
      Uri.parse(
        'https://myreadingmanga.info/zelo-lee-brave-lover-dj-slave-market-jp/',
      ),
    );
    final natalieMu = RipperFactory.getRipper(
      Uri.parse('http://cdn2.natalie.mu/music/news/140411'),
    );
    final newgrounds = RipperFactory.getRipper(
      Uri.parse('https://zone-sama.newgrounds.com/art'),
    );
    final nfsfw = RipperFactory.getRipper(
      Uri.parse('http://nfsfw.com/gallery/v/Kitten/'),
    );
    final nsfwAlbum = RipperFactory.getRipper(
      Uri.parse('https://nsfwalbum.com/album/905816'),
    );
    final nsfwXxx = RipperFactory.getRipper(
      Uri.parse('https://nsfw.xxx/user/smay3991'),
    );
    final nudeGals = RipperFactory.getRipper(
      Uri.parse('https://nude-gals.com/photoshoot.php?photoshoot_id=5541'),
    );
    final nhentai = RipperFactory.getRipper(
      Uri.parse('https://nhentai.net/g/123456/'),
    );
    final oglaf = RipperFactory.getRipper(
      Uri.parse('http://oglaf.com/plumes/'),
    );
    final paheal = RipperFactory.getRipper(
      Uri.parse('http://rule34.paheal.net/post/list/bimbo/1'),
    );
    final pawoo = RipperFactory.getRipper(
      Uri.parse('https://pawoo.net/@halki/media'),
    );
    final photobucket = RipperFactory.getRipper(
      Uri.parse(
        'http://s844.photobucket.com/user/SpazzySpizzy/library/Album%20Covers',
      ),
    );
    final pichunter = RipperFactory.getRipper(
      Uri.parse('https://www.pichunter.com/models/Madison_Ivy'),
    );
    final picstatio = RipperFactory.getRipper(
      Uri.parse('https://www.picstatio.com/aerial-view-wallpapers'),
    );
    final porncomix = RipperFactory.getRipper(
      Uri.parse('http://www.porncomix.info/lust-unleashed-desire-to-submit/'),
    );
    final porncomixinfo = RipperFactory.getRipper(
      Uri.parse(
        'https://porncomixinfo.net/chapter/comic-title/chapter-title/',
      ),
    );
    final pornhub = RipperFactory.getRipper(
      Uri.parse('https://www.pornhub.com/album/15680522?page=2'),
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
    expect(erome, isA<EromeRipper>());
    expect(fapDungeon, isA<FapDungeonRipper>());
    expect(fapwiz, isA<FapwizRipper>());
    expect(femjoyhunter, isA<FemjoyhunterRipper>());
    expect(fitnakedgirls, isA<FitnakedgirlsRipper>());
    expect(fivehundredpx, isA<FivehundredpxRipper>());
    expect(freeComicOnline, isA<FreeComicOnlineRipper>());
    expect(furaffinity, isA<FuraffinityRipper>());
    expect(fuskator, isA<FuskatorRipper>());
    expect(girlsOfDesire, isA<GirlsOfDesireRipper>());
    expect(hentai2read, isA<Hentai2readRipper>());
    expect(hentaiNexus, isA<HentaiNexusRipper>());
    expect(hentaifoundry, isA<HentaifoundryRipper>());
    expect(hentaifox, isA<HentaifoxRipper>());
    expect(hentaiimage, isA<HentaiimageRipper>());
    expect(hitomi, isA<HitomiRipper>());
    expect(hqporner, isA<HqpornerRipper>());
    expect(hypnohub, isA<HypnohubRipper>());
    expect(imagebam, isA<ImagebamRipper>());
    expect(imagevenue, isA<ImagevenueRipper>());
    expect(imgbox, isA<ImgboxRipper>());
    expect(eightmuses, isA<EightmusesRipper>());
    expect(flickr, isA<FlickrRipper>());
    expect(imagefap, isA<ImagefapRipper>());
    expect(imgur, isA<ImgurRipper>());
    expect(instagram, isA<InstagramRipper>());
    expect(jabArchives, isA<JabArchivesRipper>());
    expect(jagodibuja, isA<JagodibujaRipper>());
    expect(jpg3, isA<Jpg3Ripper>());
    expect(kingcomix, isA<KingcomixRipper>());
    expect(listal, isA<ListalRipper>());
    expect(luscious, isA<LusciousRipper>());
    expect(mangadex, isA<MangadexRipper>());
    expect(mastodon, isA<MastodonRipper>());
    expect(mastodonXyz, isA<MastodonXyzRipper>());
    expect(modelmayhem, isA<ModelmayhemRipper>());
    expect(motherless, isA<MotherlessRipper>());
    expect(motherlessVideo, isA<MotherlessVideoRipper>());
    expect(mrCong, isA<MrCongRipper>());
    expect(multporn, isA<MultpornRipper>());
    expect(myhentaicomics, isA<MyhentaicomicsRipper>());
    expect(myhentaigallery, isA<MyhentaigalleryRipper>());
    expect(myreadingmanga, isA<MyreadingmangaRipper>());
    expect(natalieMu, isA<NatalieMuRipper>());
    expect(newgrounds, isA<NewgroundsRipper>());
    expect(nfsfw, isA<NfsfwRipper>());
    expect(nsfwAlbum, isA<NsfwAlbumRipper>());
    expect(nsfwXxx, isA<NsfwXxxRipper>());
    expect(nudeGals, isA<NudeGalsRipper>());
    expect(nhentai, isA<NhentaiRipper>());
    expect(oglaf, isA<OglafRipper>());
    expect(paheal, isA<PahealRipper>());
    expect(pawoo, isA<PawooRipper>());
    expect(photobucket, isA<PhotobucketRipper>());
    expect(pichunter, isA<PichunterRipper>());
    expect(picstatio, isA<PicstatioRipper>());
    expect(porncomix, isA<PorncomixRipper>());
    expect(porncomixinfo, isA<PorncomixinfoRipper>());
    expect(pornhub, isA<PornhubRipper>());
    expect(reddit, isA<RedditRipper>());
    expect(redgifs, isA<RedgifsRipper>());
    expect(tumblr, isA<TumblrRipper>());
    expect(twitter, isA<TwitterRipper>());
  });

  test(
    'known Java-only URLs resolve to an explicit unsupported legacy ripper',
    () {
      final ripper = RipperFactory.getRipper(
        Uri.parse('https://www.pornpics.com/galleries/example-gallery/'),
      );

      expect(ripper, isA<UnsupportedLegacyRipper>());
      expect(
        (ripper as UnsupportedLegacyRipper).match.javaClass,
        'PornpicsRipper',
      );
    },
  );

  test('migration catalog tracks feature parity progress', () {
    expect(RipperMigrationCatalog.totalLegacyRippers, 116);
    expect(RipperMigrationCatalog.portedRipperCount, 81);
    expect(RipperMigrationCatalog.unportedRipperCount, 35);
  });
}
