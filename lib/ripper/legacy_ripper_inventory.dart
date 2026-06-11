class LegacyRipperInventory {
  static Set<String> classNamesFromPaths(Iterable<String> paths) {
    return paths
        .where((path) => path.endsWith('Ripper.java'))
        .map((path) => path.replaceAll(r'\', '/').split('/').last)
        .map((fileName) => fileName.substring(0, fileName.length - 5))
        .toSet();
  }
}
