class RipperReconciliationInventory {
  static const String javaRoot =
      'src/main/java/com/rarchives/ripme/ripper/rippers/';

  static const Map<String, String> videoClassOverrides = {
    'PornhubRipper': 'PornhubVideoRipper',
    'VkRipper': 'VkVideoRipper',
    'YuvutuRipper': 'YuvutuVideoRipper',
  };

  static String dartClassForJavaPath(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final fileName = normalized.split('/').last;
    if (!fileName.endsWith('.java')) {
      throw ArgumentError.value(path, 'path', 'Expected a Java source path');
    }
    final javaClass = fileName.substring(0, fileName.length - '.java'.length);
    if (normalized.contains('/video/')) {
      return videoClassOverrides[javaClass] ?? javaClass;
    }
    return javaClass;
  }

  static bool isHelperPath(String path) =>
      path.replaceAll(r'\', '/').contains('/ripperhelpers/');

  static bool isVideoPath(String path) =>
      path.replaceAll(r'\', '/').contains('/video/');
}
