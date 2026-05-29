class ConfigDefaults {
  static const Map<String, int> integers = {
    'threads.size': 5,
    'download.retries': 3,
    'download.timeout': 60000,
    'page.timeout': 5000,
    'download.max_size': 104857600,
    'download.retry.sleep': 5000,
    'twitter.max_requests': 10,
    'reddit.min_upvotes': 0,
    'reddit.max_upvotes': 10000,
    'history.end_rip_after_already_seen': 1000000000,
    'proxy.port': 8080,
  };

  static const Map<String, bool> booleans = {
    'file.overwrite': false,
    'error.skip404': true,
    'download.save_order': true,
    'album_titles.save': true,
    'twitter.rip_retweets': false,
    'twitter.exclude_replies': true,
    'clipboard.autorip': false,
    'reddit.rip_by_upvote': false,
    'reddit.use_sub_dirs': true,
    'remember.url_history': true,
    'history.skip_downloaded_urls': true,
    'urls_only.save': false,
    'play.sound': false,
    'proxy.enabled': false,
  };

  static const Map<String, String> strings = {
    'download.ignore_extensions': '',
    'twitter.auth':
        'VW9Ybjdjb1pkd2J0U3kwTUh2VXVnOm9GTzVQVzNqM29LQU1xVGhnS3pFZzhKbGVqbXU0c2lHQ3JrUFNNZm8=',
    'tumblr.auth': 'JFNLu3CbINQjRdUvZibXW9VpSEVYYtiPJ86o8YmvgLZIoKyuNX',
    'tsumino.blacklist.tags': '',
    'gw.api': 'gonewild',
    'erome.laravel_session': '',
    'proxy.host': '',
    'proxy.username': '',
    'proxy.password': '',
    'cookies.reddit.com': '',
    'cookies.imgur.com': '',
    'cookies.erome.com': '',
    'cookies.soundgasm.net': '',
    'cookies.vidble.com': '',
  };
}
