import '../ripper/abstract_ripper.dart';
import 'ripper_migration_catalog.dart';
import 'rippers/allporncomic_ripper.dart';
import 'rippers/artstation_ripper.dart';
import 'rippers/artstn_ripper.dart';
import 'rippers/imgur_ripper.dart';
import 'rippers/reddit_ripper.dart';
import 'rippers/redgifs_ripper.dart';
import 'unsupported_legacy_ripper.dart';

class RipperFactory {
  static AbstractRipper? getRipper(Uri uri) {
    String host = uri.host.toLowerCase();
    if (host.contains('allporncomic.com')) return AllporncomicRipper(uri);
    if (host.contains('artstation.com')) return ArtStationRipper(uri);
    if (host.contains('artstn.co')) return ArtstnRipper(uri);
    if (host.contains('imgur.com')) return ImgurRipper(uri);
    if (host.contains('reddit.com')) return RedditRipper(uri);
    if (host.contains('redgifs.com') ||
        host.contains('gifdeliverynetwork.com')) {
      return RedgifsRipper(uri);
    }

    final legacyMatch = RipperMigrationCatalog.findUnportedLegacyRipper(uri);
    if (legacyMatch != null) return UnsupportedLegacyRipper(uri, legacyMatch);

    return null;
  }
}
