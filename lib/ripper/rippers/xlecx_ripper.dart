import 'xcartx_ripper.dart';

class XlecxRipper extends XcartxRipper {
  static final RegExp _gidPattern =
      RegExp(r'^https?://xlecx.org/([a-zA-Z0-9_\-]+).html');

  XlecxRipper(super.url);

  @override
  String getHost() => 'xlecx';

  @override
  String getDomain() => 'xlecx.org';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null && match.group(0) == url.toString()) {
      return match.group(1)!;
    }
    throw FormatException(
      'Expected URL format: http://xlecx.org/comic, got: $url',
    );
  }
}
