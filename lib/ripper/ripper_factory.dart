import '../ripper/abstract_ripper.dart';
import 'rippers/imgur_ripper.dart';
import 'rippers/reddit_ripper.dart';
import 'rippers/tumblr_ripper.dart';
import 'rippers/twitter_ripper.dart';
import 'rippers/flickr_ripper.dart';
import 'rippers/instagram_ripper.dart';
import 'rippers/imagefap_ripper.dart';
import 'rippers/redgifs_ripper.dart';
import 'rippers/motherless_ripper.dart';
import 'rippers/eightmuses_ripper.dart';
import 'rippers/nhentai_ripper.dart';

class RipperFactory {
  static AbstractRipper? getRipper(Uri uri) {
    String host = uri.host.toLowerCase();
    if (host.contains('imgur.com')) return ImgurRipper(uri);
    if (host.contains('reddit.com')) return RedditRipper(uri);
    if (host.contains('tumblr.com')) return TumblrRipper(uri);
    if (host.contains('twitter.com') || host.contains('x.com')) return TwitterRipper(uri);
    if (host.contains('flickr.com')) return FlickrRipper(uri);
    if (host.contains('instagram.com')) return InstagramRipper(uri);
    if (host.contains('imagefap.com')) return ImagefapRipper(uri);
    if (host.contains('redgifs.com') || host.contains('gifdeliverynetwork.com')) return RedgifsRipper(uri);
    if (host.contains('motherless.com')) return MotherlessRipper(uri);
    if (host.contains('8muses.com')) return EightmusesRipper(uri);
    if (host.contains('nhentai.net')) return NhentaiRipper(uri);
    return null;
  }
}
