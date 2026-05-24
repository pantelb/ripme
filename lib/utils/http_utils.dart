import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
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

  static Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final response = await _getResponse(
      url,
      headers: headers,
      cookies: cookies,
      timeoutKey: 'download.timeout',
      defaultTimeoutMs: 60000,
    );

    if (response.statusCode == 200) {
      final maxSize = Utils.getConfigInteger('download.max_size', 104857600);
      if (response.bodyBytes.length > maxSize) {
        throw HttpException(
            'Download exceeds configured max size for $url: ${response.bodyBytes.length} > $maxSize');
      }
      if (!await saveAs.parent.exists()) {
        await saveAs.parent.create(recursive: true);
      }
      await saveAs.writeAsBytes(response.bodyBytes);
    } else {
      throw HttpException(
          'Failed to download $url: Status ${response.statusCode}');
    }
  }

  static Map<String, String> _buildHeaders(
      Uri url, Map<String, String>? headers, Map<String, String>? cookies) {
    final configuredCookies = _configuredCookiesForUrl(url);
    final allCookies = <String, String>{
      ...configuredCookies,
      if (cookies != null) ...cookies,
    };
    final Map<String, String> combined = {
      'User-Agent': userAgent,
      if (headers != null) ...headers,
    };

    if (allCookies.isNotEmpty && !combined.containsKey('Cookie')) {
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
  }) async {
    final combinedHeaders = _buildHeaders(url, headers, cookies);
    final retries = Utils.getConfigInteger('download.retries', 3);
    final timeout = Duration(
        milliseconds: Utils.getConfigInteger(timeoutKey, defaultTimeoutMs));
    final retrySleep = Duration(
        milliseconds: Utils.getConfigInteger('download.retry.sleep', 0));
    Object? lastError;

    for (var attempt = 0; attempt <= retries; attempt++) {
      http.Client? client;
      try {
        client = _createClient();
        final response =
            await client.get(url, headers: combinedHeaders).timeout(timeout);
        if (response.statusCode == 200) {
          return response;
        }

        if (response.statusCode == 404 &&
            Utils.getConfigBoolean('error.skip404', true)) {
          return response;
        }

        final rateLimitDelay = _retryAfterDelay(response);
        if (rateLimitDelay != null && attempt < retries) {
          await delay(rateLimitDelay);
          continue;
        }

        lastError =
            HttpException('Failed to load $url: Status ${response.statusCode}');
      } on TimeoutException catch (e) {
        lastError = e;
      } on IOException catch (e) {
        lastError = e;
      } finally {
        client?.close();
      }

      if (attempt < retries && retrySleep.inMilliseconds > 0) {
        await delay(retrySleep);
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }
    throw HttpException('Failed to load $url');
  }

  static http.Client _createClient() {
    if (!Utils.getConfigBoolean('proxy.enabled', false)) {
      return http.Client();
    }

    final host = Utils.getConfigString('proxy.host', '')?.trim() ?? '';
    if (host.isEmpty) {
      return http.Client();
    }

    final port = Utils.getConfigInteger('proxy.port', 8080);
    final client = HttpClient()..findProxy = (_) => 'PROXY $host:$port';

    final username = Utils.getConfigString('proxy.username', '') ?? '';
    final password = Utils.getConfigString('proxy.password', '') ?? '';
    if (username.isNotEmpty || password.isNotEmpty) {
      client.addProxyCredentials(
        host,
        port,
        '',
        HttpClientBasicCredentials(username, password),
      );
    }

    return IOClient(client);
  }

  static Map<String, String> _configuredCookiesForUrl(Uri? url) {
    if (url == null || url.host.isEmpty) return const {};
    var parts = url.host.toLowerCase().split('.');
    while (parts.length > 1) {
      final domain = parts.join('.');
      final cookieText = Utils.getConfigString('cookies.$domain', '') ?? '';
      if (cookieText.trim().isNotEmpty) {
        return _parseCookieHeader(cookieText);
      }
      parts = parts.sublist(1);
    }
    return const {};
  }

  static Map<String, String> _parseCookieHeader(String cookieText) {
    final cookies = <String, String>{};
    for (final rawPart in cookieText.split(';')) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      final separator = part.indexOf('=');
      if (separator <= 0) continue;
      final name = part.substring(0, separator).trim();
      final value = part.substring(separator + 1).trim();
      if (name.isNotEmpty) cookies[name] = value;
    }
    return cookies;
  }

  static Duration? _retryAfterDelay(http.Response response) {
    if (response.statusCode != 429 && response.statusCode != 503) return null;
    final retryAfter = response.headers['retry-after'];
    if (retryAfter == null || retryAfter.trim().isEmpty) {
      return Utils.getConfigInteger('download.retry.sleep', 0) > 0
          ? null
          : Duration.zero;
    }

    final seconds = int.tryParse(retryAfter.trim());
    if (seconds != null) {
      return Duration(seconds: seconds < 0 ? 0 : seconds);
    }

    try {
      final retryAt = HttpDate.parse(retryAfter);
      final wait = retryAt.difference(DateTime.now().toUtc());
      return wait.isNegative ? Duration.zero : wait;
    } on FormatException {
      return null;
    }
  }
}
