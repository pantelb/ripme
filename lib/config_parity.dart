import 'config_defaults.dart';

enum HiddenConfigDisposition {
  active,
  migrationAlias,
  sentinelOnly,
  retired,
  explicitlyUnsupported,
}

class ConfigParity {
  static const Map<String, String> flutterOnlyReplacementKeys = {
    'history.skip_downloaded_urls':
        'Legacy Flutter fallback for Java remember.url_history',
    'proxy.enabled': 'Structured Flutter UI for Java proxy.http',
    'proxy.host': 'Structured Flutter UI for Java proxy.http',
    'proxy.port': 'Structured Flutter UI for Java proxy.http',
    'proxy.username': 'Structured Flutter UI for Java proxy.http',
    'proxy.password': 'Structured Flutter UI for Java proxy.http',
  };

  static const Set<String> separatelyTrackedControlKeys = {
    'album_titles.save',
    'auto.update',
    'clipboard.autorip',
    'descriptions.save',
    'download.retries',
    'download.retry.sleep',
    'download.save_order',
    'download.show_popup',
    'download.timeout',
    'file.overwrite',
    'history.warn_before_delete',
    'lang',
    'log.level',
    'log.save',
    'play.sound',
    'prefer.mp4',
    'remember.url_history',
    'rips.directory',
    'ssl.verify.off',
    'threads.size',
    'urls_only.save',
    'window.h',
    'window.position',
    'window.w',
    'window.x',
    'window.y',
  };

  static const Map<String, HiddenConfigDisposition> hiddenKeyDispositions = {
    'chans.chan_sites': HiddenConfigDisposition.active,
    'cookies.*': HiddenConfigDisposition.active,
    'derpi.key': HiddenConfigDisposition.active,
    'DeviantartCustomLoginPassword': HiddenConfigDisposition.retired,
    'DeviantartCustomLoginUsername': HiddenConfigDisposition.retired,
    'DeviantartLogin.cookies': HiddenConfigDisposition.retired,
    'download.history': HiddenConfigDisposition.active,
    'download.ignore_extensions': HiddenConfigDisposition.active,
    'download.max_size': HiddenConfigDisposition.sentinelOnly,
    'e621.cookies': HiddenConfigDisposition.active,
    'e621.useragent': HiddenConfigDisposition.active,
    'ehentai.blacklist.tags': HiddenConfigDisposition.active,
    'enable.finish.command': HiddenConfigDisposition.active,
    'erome.laravel_session': HiddenConfigDisposition.active,
    'error.skip404': HiddenConfigDisposition.migrationAlias,
    'errors.skip404': HiddenConfigDisposition.active,
    'finish.command': HiddenConfigDisposition.active,
    'furaffinity.cookies': HiddenConfigDisposition.active,
    'furaffinity.login': HiddenConfigDisposition.active,
    'gw.api': HiddenConfigDisposition.sentinelOnly,
    'hentai-foundry.filter_order': HiddenConfigDisposition.active,
    'hentai-foundry.use_prefix': HiddenConfigDisposition.active,
    'history.end_rip_after_already_seen': HiddenConfigDisposition.active,
    'history.location': HiddenConfigDisposition.active,
    'imgur.client_id': HiddenConfigDisposition.active,
    'instagram.download_images_only': HiddenConfigDisposition.active,
    'instagram.session_id': HiddenConfigDisposition.active,
    'nhentai.blacklist.tags': HiddenConfigDisposition.active,
    'page.timeout': HiddenConfigDisposition.active,
    'proxy.http': HiddenConfigDisposition.active,
    'proxy.socks': HiddenConfigDisposition.explicitlyUnsupported,
    'queue': HiddenConfigDisposition.active,
    'reddit.max_upvotes': HiddenConfigDisposition.active,
    'reddit.min_upvotes': HiddenConfigDisposition.active,
    'reddit.rip_by_upvote': HiddenConfigDisposition.active,
    'reddit.use_sub_dirs': HiddenConfigDisposition.active,
    'security.check_update_hash': HiddenConfigDisposition.retired,
    'testing.always_try_to_update': HiddenConfigDisposition.active,
    'tsumino.blacklist.tags': HiddenConfigDisposition.active,
    'tumblr.auth': HiddenConfigDisposition.active,
    'twitter.auth': HiddenConfigDisposition.active,
    'twitter.exclude_replies': HiddenConfigDisposition.active,
    'twitter.max_items_request': HiddenConfigDisposition.active,
    'twitter.max_requests': HiddenConfigDisposition.active,
    'twitter.rip_retweets': HiddenConfigDisposition.active,
  };

  static Set<String> get coveredJavaKeys => {
        ...separatelyTrackedControlKeys,
        ...hiddenKeyDispositions.keys,
      };

  static Set<String> get missingJavaKeys =>
      ConfigDefaults.javaRuntimeKeys.difference(coveredJavaKeys);

  static Set<String> get unknownJavaKeys =>
      coveredJavaKeys.difference(ConfigDefaults.javaRuntimeKeys);
}
