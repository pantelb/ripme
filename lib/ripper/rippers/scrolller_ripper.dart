import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/utils.dart';
import '../abstract_ripper.dart';

class ScrolllerRipper extends AbstractRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://scrolller\.com/r/([a-zA-Z0-9]+).*?$',
  );
  static const String _queryNoSort =
      r'query SubredditQuery( $url: String! $filter: SubredditPostFilter $iterator: String ) { getSubreddit(url: $url) { children( limit: 50 iterator: $iterator filter: $filter ) { iterator items { __typename url title subredditTitle subredditUrl redditPath isNsfw albumUrl isFavorite mediaSources { url width height isOptimized } } } } }';
  static const String _querySort =
      r'subscription SubredditSubscription( $url: String! $sortBy: SubredditSortBy $timespan: SubredditTimespan $iterator: String $limit: Int $filter: SubredditPostFilter ) { fetchSubreddit( url: $url sortBy: $sortBy timespan: $timespan iterator: $iterator limit: $limit filter: $filter ) { __typename ... on Subreddit { __typename url title secondaryTitle description createdAt isNsfw subscribers isComplete itemCount videoCount pictureCount albumCount isFollowing } ... on SubredditPost { __typename url title subredditTitle subredditUrl redditPath isNsfw albumUrl isFavorite mediaSources { url width height isOptimized } } ... on Iterator { iterator } ... on Error { message } } }';
  static const Map<String, String> requestHeaders = {
    'Accept-Language': 'en-US,en;q=0.8',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
    'Referer': 'scrolller.com',
  };

  final Uri apiUri;
  final Uri webSocketUri;
  final http.Client? _apiClient;

  ScrolllerRipper(
    super.url, {
    Uri? apiUri,
    Uri? webSocketUri,
    http.Client? apiClient,
  })  : apiUri =
            apiUri ?? Uri.parse('https://api.scrolller.com/api/v2/graphql'),
        webSocketUri =
            webSocketUri ?? Uri.parse('wss://api.scrolller.com/api/v2/graphql'),
        _apiClient = apiClient;

  @override
  String getHost() => 'scrolller';

  String getDomain() => 'scrolller.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected scrolller.com URL format: '
      'scrolller.com/r/subreddit OR scroller.com/r/subreddit?filter= - got ${url}instead',
    );
  }

  @override
  Future<void> rip() async {
    var index = 0;
    Map<String, dynamic>? page;

    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    while (page != null && !isStopped) {
      final downloads = <RipperDownload>[];
      for (final urlText in urlsFromJson(page)) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(urlText);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(
              p.join(workingDir.path, fileNameForUrl(uri, index)),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      try {
        page = await getNextPage(page);
      } catch (e) {
        sendUpdate(RipStatus.ripErrored, e.toString());
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Map<String, dynamic>?> getFirstPage() async {
    return prepareQuery(null, await getGID(url), getParameter(url, 'sort'));
  }

  Future<Map<String, dynamic>?> getNextPage(Map<String, dynamic> source) async {
    final iterator = iteratorFromJson(source);
    if (iterator.toString() == 'null') return null;
    return prepareQuery(
        iterator.toString(), await getGID(url), getParameter(url, 'sort'));
  }

  Future<Map<String, dynamic>?> prepareQuery(
    String? iterator,
    String gid,
    String sortByString,
  ) async {
    final filterString = convertFilterString(getParameter(url, 'filter'));
    final variables = <String, dynamic>{
      'url': '/r/$gid',
      'sortBy': sortByString.toUpperCase(),
      if (iterator != null) 'iterator': iterator,
      if (filterString != 'NOFILTER') 'filter': filterString,
    };
    final data = {
      'variables': variables,
      'query': sortByString == '' ? _queryNoSort : _querySort,
    };

    return sortByString == '' ? getPosts(data) : getPostsSorted(data);
  }

  Future<Map<String, dynamic>> getPosts(Map<String, dynamic> data) async {
    final client = _apiClient ?? http.Client();
    try {
      final response = await client.post(
        apiUri,
        headers: requestHeaders,
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Expected Scrolller GraphQL object response');
    } finally {
      if (_apiClient == null) client.close();
    }
  }

  Future<Map<String, dynamic>?> getPostsSorted(
    Map<String, dynamic> data,
  ) async {
    final socket = await WebSocket.connect(webSocketUri.toString());
    final posts = <Map<String, dynamic>>[];
    try {
      socket.add(jsonEncode(data));
      await for (final message in socket) {
        if (message is! String) continue;
        final decoded = jsonDecode(message);
        if (decoded is! Map<String, dynamic>) continue;
        posts.add(decoded);
        final fetchSubreddit = _fetchSubreddit(decoded);
        if (fetchSubreddit is Map && fetchSubreddit.containsKey('iterator')) {
          await socket.close();
        }
      }
    } finally {
      await socket.close();
    }

    if (posts.length == 1 &&
        _mediaSourcesFromSortedItem(posts.single) == null) {
      return null;
    }

    return {
      'iterator': posts.isEmpty ? null : posts.last,
      'posts': posts,
    };
  }

  String convertFilterString(String filterParameter) {
    switch (filterParameter.toLowerCase()) {
      case 'pictures':
        return 'PICTURE';
      case 'videos':
        return 'VIDEO';
      case 'albums':
        return 'ALBUM';
      case '':
        return 'NOFILTER';
      default:
        return '';
    }
  }

  String getParameter(Uri url, String parameter) {
    final gid = _gidPattern.firstMatch(url.toString())?.group(1);
    final toReplace = 'https://scrolller.com/r/$gid?';

    final rawQuery = url.query;
    if (rawQuery.isEmpty) return '';
    for (final pair in rawQuery.split('&')) {
      final separator = pair.indexOf('=');
      final rawName = separator < 0 ? pair : pair.substring(0, separator);
      final rawValue = separator < 0 ? '' : pair.substring(separator + 1);
      final name = Uri.decodeQueryComponent(rawName)
          .replaceFirst(toReplace, '')
          .toLowerCase();
      if (name == parameter) return Uri.decodeQueryComponent(rawValue);
    }
    return '';
  }

  static Object? iteratorFromJson(Map<String, dynamic> json) {
    if (json.containsKey('iterator')) {
      final fetchSubreddit = _fetchSubreddit(json['iterator'] as Map?);
      return fetchSubreddit is Map ? fetchSubreddit['iterator'] : null;
    }
    final data = json['data'];
    final subreddit = data is Map ? data['getSubreddit'] : null;
    final children = subreddit is Map ? subreddit['children'] : null;
    return children is Map ? children['iterator'] : null;
  }

  static List<String> urlsFromJson(Map<String, dynamic> json) {
    final sortRequested = json.containsKey('posts');
    final itemsList = sortRequested
        ? json['posts']
        : (((json['data'] as Map?)?['getSubreddit'] as Map?)?['children']
            as Map?)?['items'];
    if (itemsList is! List) return const [];

    final urls = <String>[];
    for (final item in itemsList) {
      final sources = sortRequested
          ? _mediaSourcesFromSortedItem(item)
          : item is Map
              ? item['mediaSources']
              : null;
      if (sources is! List) continue;

      var bestArea = 0;
      var bestUrl = '';
      for (final source in sources) {
        if (source is! Map) continue;
        final width = source['width'];
        final height = source['height'];
        final url = source['url'];
        if (width is! int || height is! int || url is! String) continue;
        final area = width * height;
        if (area > bestArea) {
          bestArea = width;
          bestUrl = url;
        }
      }
      urls.add(bestUrl);
    }
    return urls;
  }

  static Object? _mediaSourcesFromSortedItem(Object? item) {
    final fetchSubreddit = item is Map ? _fetchSubreddit(item) : null;
    return fetchSubreddit is Map ? fetchSubreddit['mediaSources'] : null;
  }

  static Object? _fetchSubreddit(Map? item) {
    final data = item?['data'];
    return data is Map ? data['fetchSubreddit'] : null;
  }

  static String fileNameForUrl(Uri uri, int index) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('${prefixForIndex(index)}$fileName');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
