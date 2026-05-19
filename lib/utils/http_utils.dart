import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import '../utils/utils.dart';

class Http {
  static const String userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";

  static Future<Document> get(Uri url, {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final combinedHeaders = _buildHeaders(headers, cookies);
    final response = await http.get(url, headers: combinedHeaders);

    if (response.statusCode == 200) {
      return parse(response.body);
    } else {
      throw HttpException('Failed to load $url: Status ${response.statusCode}');
    }
  }

  static Future<dynamic> getJSON(Uri url, {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final combinedHeaders = _buildHeaders(headers, cookies);
    final response = await http.get(url, headers: {
      ...combinedHeaders,
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw HttpException('Failed to load JSON from $url: Status ${response.statusCode}');
    }
  }

  static Future<void> downloadFile(Uri url, File saveAs, {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final combinedHeaders = _buildHeaders(headers, cookies);
    final response = await http.get(url, headers: combinedHeaders);

    if (response.statusCode == 200) {
      if (!await saveAs.parent.exists()) {
        await saveAs.parent.create(recursive: true);
      }
      await saveAs.writeAsBytes(response.bodyBytes);
    } else {
      throw HttpException('Failed to download $url: Status ${response.statusCode}');
    }
  }

  static Map<String, String> _buildHeaders(Map<String, String>? headers, Map<String, String>? cookies) {
    final Map<String, String> combined = {
      'User-Agent': userAgent,
      if (headers != null) ...headers,
    };

    if (cookies != null && cookies.isNotEmpty) {
      combined['Cookie'] = cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    return combined;
  }
}
