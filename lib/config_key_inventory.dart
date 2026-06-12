class JavaConfigKeyInventory {
  static final RegExp _literalAccessor = RegExp(
    r'Utils\.(?:get|set)Config(?:String|StringArray|Integer|Boolean|List)'
    r'\(\s*"([^"]+)"(?!\s*\+)',
  );
  static final RegExp _dynamicAccessor = RegExp(
    r'Utils\.(?:get|set)Config(?:String|StringArray|Integer|Boolean|List)'
    r'\(\s*"([^"]+)"\s*\+',
  );
  static final RegExp _identifierAccessor = RegExp(
    r'Utils\.(?:get|set)Config(?:String|StringArray|Integer|Boolean|List)'
    r'\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,)]',
  );
  static final RegExp _stringConstant = RegExp(
    r'(?:static\s+)?(?:final\s+)?String\s+([A-Za-z_][A-Za-z0-9_]*)'
    r'\s*=\s*"([^"]+)"',
  );
  static final RegExp _containsKey =
      RegExp(r'\bconfig\.containsKey\(\s*"([^"]+)"\s*\)');
  static final RegExp _localLiteralAccessor = RegExp(
    r'(?<!\.)\b(?:get|set)Config'
    r'(?:String|StringArray|Integer|Boolean|List)'
    r'\(\s*"([^"]+)"(?!\s*\+)',
  );
  static final RegExp _localDynamicAccessor = RegExp(
    r'(?<!\.)\b(?:get|set)Config'
    r'(?:String|StringArray|Integer|Boolean|List)'
    r'\(\s*"([^"]+)"\s*\+',
  );
  static final RegExp _property = RegExp(r'^([^#!\s][^=]*)\s*=');

  static Set<String> keysFromSources(Iterable<String> sources) {
    final sourceList = sources.toList();
    final constants = <String, String>{};
    for (final source in sourceList) {
      for (final match in _stringConstant.allMatches(source)) {
        constants[match.group(1)!] = match.group(2)!;
      }
    }

    final keys = <String>{};
    for (final source in sourceList) {
      for (final match in _literalAccessor.allMatches(source)) {
        keys.add(match.group(1)!);
      }
      for (final match in _dynamicAccessor.allMatches(source)) {
        keys.add('${match.group(1)!}*');
      }
      for (final match in _identifierAccessor.allMatches(source)) {
        final value = constants[match.group(1)];
        if (value != null) keys.add(value);
      }
      for (final match in _containsKey.allMatches(source)) {
        keys.add(match.group(1)!);
      }
      if (source.contains('class Utils')) {
        for (final match in _localLiteralAccessor.allMatches(source)) {
          keys.add(match.group(1)!);
        }
        for (final match in _localDynamicAccessor.allMatches(source)) {
          keys.add('${match.group(1)!}*');
        }
      }
    }
    return keys;
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
