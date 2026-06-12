import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

enum DesktopTrayAction {
  toggleWindow,
  about,
  autorip,
  exit,
}

class DesktopTrayLabels {
  const DesktopTrayLabels({
    required this.show,
    required this.hide,
    required this.about,
    required this.autorip,
    required this.exit,
  });

  final String show;
  final String hide;
  final String about;
  final String autorip;
  final String exit;
}

abstract class DesktopWindowOperations {
  Future<bool> isVisible();
  Future<bool> isFocused();
  Future<void> showAndFocus();
  Future<void> hide();
  Future<void> exit();
}

class DesktopTrayActionHandler {
  DesktopTrayActionHandler({
    required this.window,
    required this.onAbout,
    required this.onAutoripChanged,
  });

  final DesktopWindowOperations window;
  final VoidCallback onAbout;
  final Future<void> Function(bool enabled) onAutoripChanged;

  Future<void> handle(DesktopTrayAction action, {bool? checked}) async {
    switch (action) {
      case DesktopTrayAction.toggleWindow:
        final shouldShow =
            !await window.isVisible() || !await window.isFocused();
        if (shouldShow) {
          await window.showAndFocus();
        } else {
          await window.hide();
        }
      case DesktopTrayAction.about:
        await window.showAndFocus();
        onAbout();
      case DesktopTrayAction.autorip:
        await onAutoripChanged(checked ?? false);
      case DesktopTrayAction.exit:
        await window.exit();
    }
  }
}

class DesktopTrayController with TrayListener, WindowListener {
  DesktopTrayController({
    required this.labels,
    required this.autoripEnabled,
    required this.actionHandler,
  });

  static const toggleKey = 'toggle';
  static const aboutKey = 'about';
  static const autoripKey = 'autorip';
  static const exitKey = 'exit';

  final DesktopTrayLabels labels;
  final bool autoripEnabled;
  final DesktopTrayActionHandler actionHandler;

  bool _windowActive = true;

  static bool get isSupportedDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> initialize() async {
    if (!isSupportedDesktop) return;
    trayManager.addListener(this);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await trayManager.setIcon('assets/icon.png');
    await trayManager.setToolTip('RipMe');
    await _updateMenu();
  }

  Future<void> dispose() async {
    if (!isSupportedDesktop) return;
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await trayManager.destroy();
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(actionHandler.handle(DesktopTrayAction.toggleWindow));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final action = switch (menuItem.key) {
      toggleKey => DesktopTrayAction.toggleWindow,
      aboutKey => DesktopTrayAction.about,
      autoripKey => DesktopTrayAction.autorip,
      exitKey => DesktopTrayAction.exit,
      _ => null,
    };
    if (action == null) return;
    unawaited(actionHandler.handle(action, checked: menuItem.checked));
  }

  @override
  void onWindowFocus() {
    _windowActive = true;
    unawaited(_updateMenu());
  }

  @override
  void onWindowBlur() {
    _windowActive = false;
    unawaited(_updateMenu());
  }

  @override
  void onWindowMinimize() {
    _windowActive = false;
    unawaited(_updateMenu());
  }

  @override
  void onWindowRestore() {
    _windowActive = true;
    unawaited(_updateMenu());
  }

  @override
  void onWindowClose() {
    unawaited(actionHandler.handle(DesktopTrayAction.exit));
  }

  Future<void> _updateMenu() {
    return trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: toggleKey,
            label: _windowActive ? labels.hide : labels.show,
          ),
          MenuItem(key: aboutKey, label: labels.about),
          MenuItem.separator(),
          MenuItem.checkbox(
            key: autoripKey,
            label: labels.autorip,
            checked: autoripEnabled,
          ),
          MenuItem.separator(),
          MenuItem(key: exitKey, label: labels.exit),
        ],
      ),
    );
  }
}

class WindowManagerOperations implements DesktopWindowOperations {
  const WindowManagerOperations({this.beforeExit});

  final Future<void> Function()? beforeExit;

  @override
  Future<void> exit() async {
    await beforeExit?.call();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  Future<void> hide() => windowManager.hide();

  @override
  Future<bool> isFocused() => windowManager.isFocused();

  @override
  Future<bool> isVisible() => windowManager.isVisible();

  @override
  Future<void> showAndFocus() async {
    await windowManager.show();
    await windowManager.restore();
    await windowManager.focus();
  }
}
