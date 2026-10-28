import 'package:flutter/services.dart';

/// Keychain can survive uninstall. The app-container marker cannot; commit it
/// only after clearing secure preferences, so interrupted cleanup is retried.
class IosInstallationInitializer {
  const IosInstallationInitializer({
    this.channel = const MethodChannel('sedno/installation'),
  });
  final MethodChannel channel;

  Future<bool> initialize(Future<void> Function() clearPreferences) async {
    final fresh = await channel.invokeMethod<bool>('isFreshInstallation');
    if (fresh == null) throw StateError('Installation state unavailable.');
    if (fresh) {
      await clearPreferences();
      await channel.invokeMethod<void>('markInitialized');
    }
    return fresh;
  }
}
