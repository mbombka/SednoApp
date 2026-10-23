import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.localesTestValue = const [Locale('pl', 'PL')];
  await testMain();
}
