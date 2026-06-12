import 'package:local_notifier/local_notifier.dart';

import 'app_version.dart';
import 'desktop_tray_controller.dart';

typedef DesktopNotificationPresenter = Future<void> Function({
  required String title,
  required String body,
});

class DesktopRipStartNotifier {
  DesktopRipStartNotifier({
    required this.window,
    DesktopNotificationPresenter? presenter,
  }) : _presenter = presenter ?? _showLocalNotification;

  final DesktopWindowOperations window;
  final DesktopNotificationPresenter _presenter;

  Future<void> notify(String url, {required bool enabled}) async {
    if (!enabled || !DesktopTrayController.isSupportedDesktop) return;
    try {
      final isVisible = await window.isVisible();
      final isFocused = isVisible && await window.isFocused();
      if (isVisible && isFocused) return;
      await _presenter(
        title: 'Ripping - RipMe v$appVersion',
        body: 'Started ripping $url',
      );
    } catch (_) {
      // Java logs and continues when tray notifications are unavailable.
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) {
    return LocalNotification(title: title, body: body).show();
  }
}
