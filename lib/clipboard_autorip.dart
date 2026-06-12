class ClipboardAutoripTracker {
  static const pollInterval = Duration(seconds: 1);

  static final RegExp _urlPattern = RegExp(
    r'^(https?|ftp|file)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*'
    r'[-a-zA-Z0-9+&@#/%=~_|]',
  );

  final Set<String> _rippedUrls = <String>{};

  String? takeNewUrl(String? clipboardText) {
    if (clipboardText == null) return null;
    final match = _urlPattern.firstMatch(clipboardText);
    if (match == null) return null;
    final url = match.group(0)!;
    return _rippedUrls.add(url) ? url : null;
  }
}
