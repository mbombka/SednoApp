import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/ios_installation_initializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sedno/installation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('fresh install clears credentials before committing marker', () async {
    final events = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      events.add(call.method);
      return call.method == 'isFreshInstallation' ? true : null;
    });
    expect(
      await const IosInstallationInitializer().initialize(() async {
        events.add('clear');
      }),
      true,
    );
    expect(events, ['isFreshInstallation', 'clear', 'markInitialized']);
  });
  test('failed cleanup never commits installation marker', () async {
    final events = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      events.add(call.method);
      return true;
    });
    await expectLater(
      const IosInstallationInitializer().initialize(() async {
        throw StateError('locked');
      }),
      throwsStateError,
    );
    expect(events, ['isFreshInstallation']);
  });
  test('update preserves credentials and consent', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    expect(
      await const IosInstallationInitializer().initialize(() async {
        fail('must retain preferences');
      }),
      false,
    );
  });
}
