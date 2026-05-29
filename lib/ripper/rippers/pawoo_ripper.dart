import 'mastodon_ripper.dart';

class PawooRipper extends MastodonRipper {
  PawooRipper(super.url);

  @override
  String getHost() => 'pawoo';

  @override
  String getDomain() => 'pawoo.net';
}
