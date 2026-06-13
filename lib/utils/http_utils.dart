import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import '../utils/proxy_config.dart';
import '../utils/utils.dart';

class Http {
  static const String userAgent =
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";
  static Future<void> Function(Duration duration) delay = Future.delayed;

  static Future<Document> get(Uri url,
      {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final response =
        await _getResponse(url, headers: headers, cookies: cookies);

    if (response.statusCode == 200) {
      return parse(response.body);
    } else {
      throw HttpException('Failed to load $url: Status ${response.statusCode}');
    }
  }

  static JavaHttpRequest url(Object url) {
    return JavaHttpRequest(
      url is Uri ? url : Uri.parse(url.toString()),
    );
  }

  static Future<dynamic> getJSON(Uri url,
      {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final response = await _getResponse(
      url,
      headers: {
        if (headers != null) ...headers,
        'Accept': 'application/json',
      },
      cookies: cookies,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw HttpException(
          'Failed to load JSON from $url: Status ${response.statusCode}');
    }
  }

  static Future<String> getText(Uri url,
      {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final response =
        await _getResponse(url, headers: headers, cookies: cookies);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw HttpException('Failed to load $url: Status ${response.statusCode}');
    }
  }

  static Future<http.Response> getResponse(Uri url,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      String timeoutKey = 'page.timeout',
      int defaultTimeoutMs = 5000}) {
    return _getResponse(
      url,
      headers: headers,
      cookies: cookies,
      timeoutKey: timeoutKey,
      defaultTimeoutMs: defaultTimeoutMs,
    );
  }

  static Future<File> downloadFile(
    Uri url,
    File saveAs, {
    Map<String, String>? headers,
    Map<String, String>? cookies,
    bool Function()? shouldStop,
    void Function(int totalBytes)? onTotalBytes,
    void Function(int completedBytes)? onBytesCompleted,
    bool includeCookieHeader = true,
    bool getFileExtFromMIME = false,
  }) async {
    final combinedHeaders = _buildHeaders(
      url,
      headers,
      cookies,
      isDownload: true,
      includeDownloadCookieHeader: includeCookieHeader,
    );
    final attempts = Utils.getConfigInteger('download.retries', 3) + 1;
    final timeout = Duration(
      milliseconds: Utils.getConfigInteger('download.timeout', 60000),
    );
    final retrySleep = Duration(
      milliseconds: Utils.getConfigInteger('download.retry.sleep', 0),
    );
    Object? lastError;
    var completedBytes = 0;

    for (var attempt = 0; attempt < attempts; attempt++) {
      http.Client? client;
      IOSink? sink;
      try {
        if (shouldStop?.call() ?? false) {
          throw const DownloadInterruptedException();
        }
        client = _createClient();
        final request = http.Request('GET', url)
          ..headers.addAll(combinedHeaders);
        final response = await client.send(request).timeout(timeout);

        if (response.statusCode ~/ 100 == 4) {
          throw _NonRetriableHttpException(
            'Non-retriable status code ${response.statusCode} '
            'while downloading $url',
          );
        }
        if (response.statusCode ~/ 100 == 5) {
          lastError = HttpException(
            'Retriable status code ${response.statusCode} '
            'while downloading $url',
          );
        } else if (response.statusCode != 200) {
          lastError = HttpException(
              'Failed to load $url: Status ${response.statusCode}');
        } else {
          onTotalBytes?.call(_javaInt32(response.contentLength ?? -1));
          if (getFileExtFromMIME) {
            final iterator = StreamIterator<List<int>>(
              response.stream.timeout(timeout),
            );
            final bufferedChunks = <List<int>>[];
            final probe = <int>[];
            while (probe.length < 16 && await iterator.moveNext()) {
              final chunk = iterator.current;
              bufferedChunks.add(chunk);
              probe.addAll(chunk.take(16 - probe.length));
            }
            final extension = fileExtensionFromBytes(probe);
            if (extension != null) {
              saveAs = File('${saveAs.path}.$extension');
            }
            if (!await saveAs.parent.exists()) {
              await saveAs.parent.create(recursive: true);
            }
            sink = saveAs.openWrite();
            for (final chunk in bufferedChunks) {
              if (shouldStop?.call() ?? false) {
                throw const DownloadInterruptedException();
              }
              sink.add(chunk);
              completedBytes = _javaInt32(completedBytes + chunk.length);
              onBytesCompleted?.call(completedBytes);
            }
            while (await iterator.moveNext()) {
              if (shouldStop?.call() ?? false) {
                throw const DownloadInterruptedException();
              }
              final chunk = iterator.current;
              sink.add(chunk);
              completedBytes = _javaInt32(completedBytes + chunk.length);
              onBytesCompleted?.call(completedBytes);
            }
          } else {
            if (!await saveAs.parent.exists()) {
              await saveAs.parent.create(recursive: true);
            }
            sink = saveAs.openWrite();
            await for (final chunk in response.stream.timeout(timeout)) {
              if (shouldStop?.call() ?? false) {
                throw const DownloadInterruptedException();
              }
              sink.add(chunk);
              completedBytes = _javaInt32(completedBytes + chunk.length);
              onBytesCompleted?.call(completedBytes);
            }
          }
          await sink.close();
          sink = null;
          return saveAs;
        }
      } on DownloadInterruptedException {
        rethrow;
      } on _NonRetriableHttpException {
        rethrow;
      } on TimeoutException {
        rethrow;
      } on IOException catch (e) {
        lastError = e;
      } finally {
        await sink?.close();
        client?.close();
      }

      if (retrySleep.inMilliseconds > 0) {
        await delay(retrySleep);
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }
    throw HttpException('Failed to download $url');
  }

  static String? fileExtensionFromBytes(List<int> bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff &&
        (bytes[3] == 0xe0 || bytes[3] == 0xee)) {
      return 'jpeg';
    }
    if (bytes.length >= 11 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff &&
        bytes[3] == 0xe1 &&
        bytes[6] == 0x45 &&
        bytes[7] == 0x78 &&
        bytes[8] == 0x69 &&
        bytes[9] == 0x66 &&
        bytes[10] == 0) {
      return 'jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'gif';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x23 &&
        bytes[1] == 0x64 &&
        bytes[2] == 0x65 &&
        bytes[3] == 0x66) {
      return 'x-bitmap';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x21 &&
        bytes[1] == 0x20 &&
        bytes[2] == 0x58 &&
        bytes[3] == 0x50 &&
        bytes[4] == 0x4d &&
        bytes[5] == 0x32) {
      return 'x-pixmap';
    }
    if (bytes.length >= 4 &&
        ((bytes[0] == 0x49 &&
                bytes[1] == 0x49 &&
                bytes[2] == 0x2a &&
                bytes[3] == 0) ||
            (bytes[0] == 0x4d &&
                bytes[1] == 0x4d &&
                bytes[2] == 0 &&
                bytes[3] == 0x2a))) {
      return 'tiff';
    }
    if (bytes.length >= 5 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff &&
        bytes[3] == 0xdb &&
        bytes[4] == 0) {
      return 'jpeg';
    }
    if (bytes.length >= 5 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d) {
      return 'png';
    }
    return null;
  }

  static Future<int> getDownloadContentLength(
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? cookies,
    bool includeCookieHeader = true,
  }) async {
    final client = _createClient();
    try {
      final request = http.Request('HEAD', url)
        ..headers.addAll(_buildHeaders(
          url,
          headers,
          cookies,
          isDownload: true,
          includeDownloadCookieHeader: includeCookieHeader,
        ));
      final response = await client.send(request);
      return _javaInt32(response.contentLength ?? -1);
    } finally {
      client.close();
    }
  }

  static int _javaInt32(int value) => value.toSigned(32);

  static Map<String, String> _buildHeaders(
    Uri url,
    Map<String, String>? headers,
    Map<String, String>? cookies, {
    bool isDownload = false,
    bool includeDownloadCookieHeader = true,
  }) {
    final configuredCookies =
        isDownload ? const <String, String>{} : configuredCookiesForUrl(url);
    final allCookies = <String, String>{
      if (!isDownload || includeDownloadCookieHeader) ...configuredCookies,
      if ((!isDownload || includeDownloadCookieHeader) && cookies != null)
        ...cookies,
    };
    final Map<String, String> combined = {
      'User-Agent': userAgent,
      if (isDownload) 'Accept': '*/*',
      if (headers != null) ...headers,
    };

    if (((isDownload && includeDownloadCookieHeader) ||
            allCookies.isNotEmpty) &&
        !combined.containsKey('Cookie')) {
      combined['Cookie'] =
          allCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    return combined;
  }

  static Future<http.Response> _getResponse(
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? cookies,
    String timeoutKey = 'page.timeout',
    int defaultTimeoutMs = 5000,
    bool isDownload = false,
    String method = 'GET',
    Map<String, String>? data,
    int? attemptsOverride,
    Duration? timeoutOverride,
  }) async {
    final combinedHeaders =
        _buildHeaders(url, headers, cookies, isDownload: isDownload);
    final configuredAttempts =
        attemptsOverride ?? Utils.getConfigInteger('download.retries', 3);
    final attempts = isDownload && attemptsOverride == null
        ? configuredAttempts + 1
        : configuredAttempts;
    final timeout = timeoutOverride ??
        Duration(
          milliseconds: Utils.getConfigInteger(timeoutKey, defaultTimeoutMs),
        );
    final retrySleep = Duration(
      milliseconds: Utils.getConfigInteger(
        'download.retry.sleep',
        isDownload ? 0 : 5000,
      ),
    );
    Object? lastError;

    for (var attempt = 0; attempt < attempts; attempt++) {
      http.Client? client;
      try {
        client = _createClient();
        final response = await _send(
          client,
          method,
          url,
          combinedHeaders,
          data,
        ).timeout(timeout);
        if (response.statusCode == 200) {
          return response;
        }

        if (!isDownload &&
            (response.statusCode == 401 || response.statusCode == 403)) {
          throw _NonRetriableHttpException(
            'Failed to load $url: Status Code ${response.statusCode}. '
            'You might be able to circumvent this error by setting cookies '
            'for this domain',
          );
        }

        if (!isDownload && response.statusCode == 404) {
          throw _NonRetriableHttpException(
            'File not found $url: Status Code 404. ',
          );
        }

        if (isDownload && response.statusCode ~/ 100 == 4) {
          throw _NonRetriableHttpException(
            'Non-retriable status code ${response.statusCode} '
            'while downloading $url',
          );
        }

        if (isDownload && response.statusCode ~/ 100 == 5) {
          lastError = HttpException(
            'Retriable status code ${response.statusCode} '
            'while downloading $url',
          );
        } else {
          lastError = HttpException(
              'Failed to load $url: Status ${response.statusCode}');
        }
      } on _NonRetriableHttpException {
        rethrow;
      } on TimeoutException catch (e) {
        if (isDownload) {
          rethrow;
        }
        lastError = e;
      } on IOException catch (e) {
        lastError = e;
      } finally {
        client?.close();
      }

      if (retrySleep.inMilliseconds > 0) {
        await delay(retrySleep);
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }
    throw HttpException('Failed to load $url');
  }

  static Future<http.Response> _send(
    http.Client client,
    String method,
    Uri url,
    Map<String, String> headers,
    Map<String, String>? data,
  ) {
    switch (method.toUpperCase()) {
      case 'GET':
        return client.get(url, headers: headers);
      case 'POST':
        return client.post(url, headers: headers, body: data);
      default:
        final request = http.Request(method.toUpperCase(), url)
          ..headers.addAll(headers);
        if (data != null && data.isNotEmpty) {
          request.bodyFields = data;
        }
        return client.send(request).then(http.Response.fromStream);
    }
  }

  static http.Client _createClient() {
    final client = HttpClient();
    configureCertificateVerification(client);
    configureProxy(client);

    return IOClient(client);
  }

  static void configureCertificateVerification(HttpClient client) {
    client.badCertificateCallback =
        Utils.getConfigBoolean('ssl.verify.off', false)
            ? (_, __, ___) => true
            : null;
  }

  static void configureProxy(HttpClient client) {
    final javaHttpProxy = Utils.getConfigString('proxy.http', null);
    if (javaHttpProxy != null) {
      _applyProxy(client, ProxyConfig.parseJavaServer(javaHttpProxy));
      return;
    }

    final javaSocksProxy = Utils.getConfigString('proxy.socks', null);
    if (javaSocksProxy != null) {
      ProxyConfig.parseJavaServer(javaSocksProxy);
      throw UnsupportedError(
        'SOCKS proxy is not supported by the dart:io HttpClient backend',
      );
    }

    if (!Utils.getConfigBoolean('proxy.enabled', false)) {
      return;
    }

    final host = Utils.getConfigString('proxy.host', '')?.trim() ?? '';
    if (host.isEmpty) {
      return;
    }

    _applyProxy(
      client,
      ProxyConfig(
        server: host,
        port: Utils.getConfigInteger('proxy.port', 8080),
        user: Utils.getConfigString('proxy.username', ''),
        password: Utils.getConfigString('proxy.password', ''),
      ),
    );
  }

  static void _applyProxy(HttpClient client, ProxyConfig proxy) {
    final port = proxy.port ?? 80;
    client.findProxy = (_) => 'PROXY ${proxy.server}:$port';

    if (proxy.user != null && proxy.password != null) {
      client.addProxyCredentials(
        proxy.server,
        port,
        '',
        HttpClientBasicCredentials(proxy.user!, proxy.password!),
      );
    }
  }

  static Map<String, String> configuredCookiesForUrl(Uri? url) {
    if (url == null || url.host.isEmpty) return const {};
    var parts = url.host.toLowerCase().split('.');
    while (parts.length > 1) {
      final domain = parts.join('.');
      final cookieText = Utils.getConfigString('cookies.$domain', '') ?? '';
      if (cookieText.trim().isNotEmpty) {
        return _parseConfiguredCookies(cookieText);
      }
      parts = parts.sublist(1);
    }
    return const {};
  }

  static Map<String, String> _parseConfiguredCookies(String cookieText) {
    final cookies = <String, String>{};
    final pairs = cookieText.trim().split(';');
    while (pairs.isNotEmpty && pairs.last.isEmpty) {
      pairs.removeLast();
    }
    for (final pair in pairs) {
      final keyValue = pair.split('=');
      cookies[keyValue[0].trim()] = keyValue[1];
    }
    return cookies;
  }
}

class _NonRetriableHttpException extends HttpException {
  _NonRetriableHttpException(super.message);
}

class DownloadInterruptedException implements IOException {
  const DownloadInterruptedException();

  @override
  String toString() => 'Download interrupted';
}

class JavaHttpRequest {
  final Uri _url;
  final Map<String, String> _headers = {};
  final Map<String, String> _cookies = {};
  final Map<String, String> _data = {};
  String _method = 'GET';
  int? _retries;
  Duration? _timeout;

  JavaHttpRequest(this._url);

  JavaHttpRequest ignoreContentType() => this;

  JavaHttpRequest referrer(Object referrer) {
    _headers['Referer'] = referrer.toString();
    return this;
  }

  JavaHttpRequest userAgent(String userAgent) {
    _headers['User-Agent'] = userAgent;
    return this;
  }

  JavaHttpRequest retries(int attempts) {
    _retries = attempts;
    return this;
  }

  JavaHttpRequest timeout(int milliseconds) {
    _timeout = Duration(milliseconds: milliseconds);
    return this;
  }

  JavaHttpRequest header(String name, String value) {
    _headers[name] = value;
    return this;
  }

  JavaHttpRequest cookies(Map<String, String> values) {
    _cookies.addAll(values);
    return this;
  }

  JavaHttpRequest data(Object values, [String? value]) {
    if (values is Map<String, String>) {
      _data.addAll(values);
      return this;
    }
    if (values is String && value != null) {
      _data[values] = value;
      return this;
    }
    throw ArgumentError('data expects Map<String, String> or name/value');
  }

  JavaHttpRequest method(String method) {
    _method = method.toUpperCase();
    return this;
  }

  Future<http.Response> response() {
    return Http._getResponse(
      _url,
      headers: _headers,
      cookies: _cookies,
      method: _method,
      data: _data,
      attemptsOverride: _retries,
      timeoutOverride: _timeout,
    );
  }

  Future<Document> get() async {
    _method = 'GET';
    final result = await response();
    return parse(result.body);
  }

  Future<Document> post() async {
    _method = 'POST';
    final result = await response();
    return parse(result.body);
  }

  Future<dynamic> getJSON() async {
    final value = jsonDecode((await response()).body);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return value;
  }

  Future<List<dynamic>> getJSONArray() async {
    final value = jsonDecode((await response()).body);
    if (value is! List<dynamic>) {
      throw const FormatException('Expected a JSON array');
    }
    return value;
  }
}
