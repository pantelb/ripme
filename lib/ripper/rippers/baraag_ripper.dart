import 'mastodon_ripper.dart';

class BaraagRipper extends MastodonRipper {
  BaraagRipper(super.url);

  @override
  String getHost() => 'baraag';

  @override
  String getDomain() => 'baraag.net';
}
