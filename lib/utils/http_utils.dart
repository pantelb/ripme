import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import '../utils/utils.dart';

class Http {
  static const String userAgent =
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";

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
      Map<String, String>? headers, Map<String, String>? cookies) {
    final Map<String, String> combined = {
      'User-Agent': userAgent,
      if (headers != null) ...headers,
    };

    if (cookies != null && cookies.isNotEmpty) {
      combined['Cookie'] =
          cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
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
    final combinedHeaders = _buildHeaders(headers, cookies);
    final retries = Utils.getConfigInteger('download.retries', 3);
    final timeout = Duration(
        milliseconds: Utils.getConfigInteger(timeoutKey, defaultTimeoutMs));
    final retrySleep = Duration(
        milliseconds: Utils.getConfigInteger('download.retry.sleep', 0));
    Object? lastError;

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final response =
            await http.get(url, headers: combinedHeaders).timeout(timeout);
        if (response.statusCode == 200) {
          return response;
        }

        if (response.statusCode == 404 &&
            Utils.getConfigBoolean('error.skip404', true)) {
          return response;
        }

        lastError =
            HttpException('Failed to load $url: Status ${response.statusCode}');
      } on TimeoutException catch (e) {
        lastError = e;
      } on IOException catch (e) {
        lastError = e;
      }

      if (attempt < retries && retrySleep.inMilliseconds > 0) {
        await Future<void>.delayed(retrySleep);
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }
    throw HttpException('Failed to load $url');
  }
}
