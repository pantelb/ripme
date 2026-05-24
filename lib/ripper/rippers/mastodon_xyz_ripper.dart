import 'mastodon_ripper.dart';

class MastodonXyzRipper extends MastodonRipper {
  MastodonXyzRipper(super.url);

  @override
  String getHost() => 'mastodonxyz';

  @override
  String getDomain() => 'mastodon.xyz';
}
