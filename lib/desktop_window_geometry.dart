import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'utils/utils.dart';

abstract class DesktopWindowGeometryOperations {
  Future<Offset> getPosition();
  Future<Size> getSize();
  Future<void> setBounds(Rect bounds);
  Future<void> center();
}

class DesktopWindowGeometryController {
  const DesktopWindowGeometryController({
    required this.window,
    required this.isDesktop,
    required this.isWindows,
  });

  factory DesktopWindowGeometryController.platform() {
    return DesktopWindowGeometryController(
      window: const WindowManagerGeometryOperations(),
      isDesktop: Platform.isWindows || Platform.isLinux || Platform.isMacOS,
      isWindows: Platform.isWindows,
    );
  }

  final DesktopWindowGeometryOperations window;
  final bool isDesktop;
  final bool isWindows;

  bool get isEnabled =>
      isDesktop &&
      !isWindows &&
      Utils.getConfigBoolean('window.position', true);

  Future<void> restore() async {
    if (!isDesktop) return;
    if (!isEnabled) {
      await window.center();
      return;
    }

    final x = Utils.getConfigInteger('window.x', -1);
    final y = Utils.getConfigInteger('window.y', -1);
    final width = Utils.getConfigInteger('window.w', -1);
    final height = Utils.getConfigInteger('window.h', -1);
    if (x < 0 || y < 0 || width <= 0 || height <= 0) {
      await window.center();
      return;
    }
    await window.setBounds(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
    );
  }

  Future<void> save() async {
    if (!isEnabled) return;
    final position = await window.getPosition();
    final size = await window.getSize();
    await Utils.setConfigInteger('window.x', position.dx.toInt());
    await Utils.setConfigInteger('window.y', position.dy.toInt());
    await Utils.setConfigInteger('window.w', size.width.toInt());
    await Utils.setConfigInteger('window.h', size.height.toInt());
  }
}

class WindowManagerGeometryOperations
    implements DesktopWindowGeometryOperations {
  const WindowManagerGeometryOperations();

  @override
  Future<void> center() => windowManager.center();

  @override
  Future<Offset> getPosition() => windowManager.getPosition();

  @override
  Future<Size> getSize() => windowManager.getSize();

  @override
  Future<void> setBounds(Rect bounds) => windowManager.setBounds(bounds);
}
