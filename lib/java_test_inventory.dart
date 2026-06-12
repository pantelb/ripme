class JavaTestInventory {
  static const Map<String, String> coverageAliases = {
    'AbstractRipperTest': 'abstract_ripper_download',
    'ArtStationRipperTest': 'artstation_ripper',
    'BaraagRipperTest': 'mastodon_ripper',
    'Base64Test': 'base64_compat',
    'FapDungeonRipperTest': 'fapdungeon_ripper',
    'HentainexusRipperTest': 'hentai_nexus_ripper',
    'JabArchivesRipperTest': 'jabarchives_ripper',
    'LabelsBundlesTest': 'app_localizations',
    'MastodonXyzRipperTest': 'mastodon_ripper',
    'MrCongRipperTest': 'mrcong_ripper',
    'PawooRipperTest': 'mastodon_ripper',
    'proxyTest': 'proxy_config',
    'RipButtonHandlerTest': 'rip_manager',
    'RippersTest': 'ripper_factory',
    'RulePornRipperTest': 'ruleporn_ripper',
    'ShesFreakyRipperTest': 'shesfreaky_ripper',
    'SpankBangRipperTest': 'spankbang_ripper',
    'UIContextMenuTests': 'text_field_context_actions',
    'UpdateUtilsTest': 'update_checker',
    'VideoRippersTest': 'abstract_video_ripper',
  };

  static Set<String> classNamesFromPaths(Iterable<String> paths) {
    return {
      for (final path in paths)
        if (path.endsWith('.java'))
          path.split('/').last.substring(0, path.split('/').last.length - 5),
    };
  }

  static String directDartStem(String javaClass) {
    final withoutSuffix = javaClass.replaceFirst(RegExp(r'Tests?$'), '');
    return withoutSuffix
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
  }

  static String coverageStem(String javaClass) {
    return coverageAliases[javaClass] ?? directDartStem(javaClass);
  }
}
