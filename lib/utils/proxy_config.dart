class ProxyConfig {
  final String server;
  final int? port;
  final String? user;
  final String? password;

  const ProxyConfig({
    required this.server,
    this.port,
    this.user,
    this.password,
  });

  static ProxyConfig parseJavaServer(String value) {
    var serverValue = value;
    String? user;
    String? password;

    final at = serverValue.lastIndexOf('@');
    if (at >= 0) {
      final credentials = serverValue.substring(0, at).split(':');
      if (credentials.length < 2) {
        throw const FormatException(
          'Proxy credentials must use user:password format',
        );
      }
      user = credentials[0];
      password = credentials[1];
      serverValue = serverValue.substring(at + 1);
    }

    final serverParts = serverValue.split(':');
    final server = serverParts[0];
    if (server.isEmpty) {
      throw const FormatException('Proxy server must not be empty');
    }

    int? port;
    if (serverParts.length == 2) {
      port = int.tryParse(serverParts[1]);
      if (port == null) {
        throw FormatException('Invalid proxy port: ${serverParts[1]}');
      }
    }

    return ProxyConfig(
      server: server,
      port: port,
      user: user,
      password: password,
    );
  }
}
