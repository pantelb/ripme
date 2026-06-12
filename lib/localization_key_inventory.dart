class JavaLocalizationKeyInventory {
  static final RegExp _localizedStringCall =
      RegExp(r'Utils\.getLocalizedString\(\s*"([^"]+)"\s*\)');
  static final RegExp _property = RegExp(r'^([^#!\s][^=]*)\s*=');

  static Set<String> keysFromSources(Iterable<String> sources) {
    return {
      for (final source in sources)
        for (final match in _localizedStringCall.allMatches(source))
          match.group(1)!,
    };
  }

  static Set<String> keysFromProperties(String source) {
    final keys = <String>{};
    for (final rawLine in source.split(RegExp(r'\r?\n'))) {
      final match = _property.firstMatch(rawLine.trim());
      if (match != null) keys.add(match.group(1)!.trim());
    }
    return keys;
  }
}
