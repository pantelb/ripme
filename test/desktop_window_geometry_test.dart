import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/desktop_window_geometry.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restores valid Java window bounds on supported desktop', () async {
    SharedPreferences.setMockInitialValues({
      'window.position': true,
      'window.x': 10,
      'window.y': 20,
      'window.w': 900,
      'window.h': 700,
    });
    await Utils.init();
    final window = _FakeGeometryWindow();
    final controller = DesktopWindowGeometryController(
      window: window,
      isDesktop: true,
      isWindows: false,
    );

    await controller.restore();

    expect(window.bounds, const Rect.fromLTWH(10, 20, 900, 700));
    expect(window.centerCalls, 0);
  });

  test('invalid or disabled Java geometry centers the desktop window',
      () async {
    SharedPreferences.setMockInitialValues({
      'window.position': true,
      'window.x': -1,
      'window.y': 20,
      'window.w': 900,
      'window.h': 700,
    });
    await Utils.init();
    final invalidWindow = _FakeGeometryWindow();
    await DesktopWindowGeometryController(
      window: invalidWindow,
      isDesktop: true,
      isWindows: false,
    ).restore();
    expect(invalidWindow.centerCalls, 1);

    SharedPreferences.setMockInitialValues({'window.position': false});
    await Utils.init();
    final disabledWindow = _FakeGeometryWindow();
    await DesktopWindowGeometryController(
      window: disabledWindow,
      isDesktop: true,
      isWindows: false,
    ).restore();
    expect(disabledWindow.centerCalls, 1);
  });

  test('saves Linux and macOS geometry using Java integer truncation',
      () async {
    SharedPreferences.setMockInitialValues({'window.position': true});
    await Utils.init();
    final window = _FakeGeometryWindow(
      position: const Offset(12.9, 24.8),
      size: const Size(1024.7, 768.6),
    );
    final controller = DesktopWindowGeometryController(
      window: window,
      isDesktop: true,
      isWindows: false,
    );

    await controller.save();

    expect(Utils.getConfigInteger('window.x', -1), 12);
    expect(Utils.getConfigInteger('window.y', -1), 24);
    expect(Utils.getConfigInteger('window.w', -1), 1024);
    expect(Utils.getConfigInteger('window.h', -1), 768);
  });

  test('matches Java Windows exclusion and Android no-op', () async {
    SharedPreferences.setMockInitialValues({
      'window.position': true,
      'window.x': 10,
      'window.y': 20,
      'window.w': 900,
      'window.h': 700,
    });
    await Utils.init();
    final windows = _FakeGeometryWindow();
    final windowsController = DesktopWindowGeometryController(
      window: windows,
      isDesktop: true,
      isWindows: true,
    );
    await windowsController.restore();
    await windowsController.save();
    expect(windows.centerCalls, 1);
    expect(windows.getPositionCalls, 0);

    final android = _FakeGeometryWindow();
    final androidController = DesktopWindowGeometryController(
      window: android,
      isDesktop: false,
      isWindows: false,
    );
    await androidController.restore();
    await androidController.save();
    expect(android.centerCalls, 0);
    expect(android.getPositionCalls, 0);
  });
}

class _FakeGeometryWindow implements DesktopWindowGeometryOperations {
  _FakeGeometryWindow({
    this.position = Offset.zero,
    this.size = const Size(800, 600),
  });

  final Offset position;
  final Size size;
  Rect? bounds;
  int centerCalls = 0;
  int getPositionCalls = 0;

  @override
  Future<void> center() async {
    centerCalls++;
  }

  @override
  Future<Offset> getPosition() async {
    getPositionCalls++;
    return position;
  }

  @override
  Future<Size> getSize() async => size;

  @override
  Future<void> setBounds(Rect bounds) async {
    this.bounds = bounds;
  }
}
