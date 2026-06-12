import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/desktop_tray_controller.dart';

void main() {
  test('tray toggle hides an active visible window like Java', () async {
    final window = _FakeWindow(visible: true, focused: true);
    final handler = DesktopTrayActionHandler(
      window: window,
      onAbout: () {},
      onAutoripChanged: (_) async {},
    );

    await handler.handle(DesktopTrayAction.toggleWindow);

    expect(window.calls, ['hide']);
  });

  test('tray toggle restores and focuses an inactive window like Java',
      () async {
    final window = _FakeWindow(visible: true, focused: false);
    final handler = DesktopTrayActionHandler(
      window: window,
      onAbout: () {},
      onAutoripChanged: (_) async {},
    );

    await handler.handle(DesktopTrayAction.toggleWindow);

    expect(window.calls, ['showAndFocus']);
  });

  test('tray actions dispatch about, autorip, and exit', () async {
    final window = _FakeWindow(visible: true, focused: true);
    var aboutOpened = false;
    bool? autorip;
    final handler = DesktopTrayActionHandler(
      window: window,
      onAbout: () => aboutOpened = true,
      onAutoripChanged: (enabled) async => autorip = enabled,
    );

    await handler.handle(DesktopTrayAction.about);
    await handler.handle(DesktopTrayAction.autorip, checked: true);
    await handler.handle(DesktopTrayAction.exit);

    expect(aboutOpened, isTrue);
    expect(autorip, isTrue);
    expect(window.calls, ['showAndFocus', 'exit']);
  });
}

class _FakeWindow implements DesktopWindowOperations {
  _FakeWindow({required this.visible, required this.focused});

  final bool visible;
  final bool focused;
  final calls = <String>[];

  @override
  Future<void> exit() async => calls.add('exit');

  @override
  Future<void> hide() async => calls.add('hide');

  @override
  Future<bool> isFocused() async => focused;

  @override
  Future<bool> isVisible() async => visible;

  @override
  Future<void> showAndFocus() async => calls.add('showAndFocus');
}
