import '../helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/app/app_theme.dart';

void main() {
  final systemCalls = <MethodCall>[];

  setUp(() {
    systemCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          systemCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('system back retraces screens and exits only from Start', (
    tester,
  ) async {
    await tester.pumpWidget(const SednoApp());
    await tester.enterText(find.byType(TextField), 'Mój tekst');
    await navigateTo(tester, 'Historia');
    await navigateTo(tester, 'Konto');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Nie masz jeszcze zapisanych tekstów.'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mój tekst',
    );
    expect(
      systemCalls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );

    await tester.binding.handlePopRoute();
    expect(
      systemCalls.where((call) => call.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  });

  testWidgets('selecting the same screen does not add a back step', (
    tester,
  ) async {
    await tester.pumpWidget(const SednoApp());
    await navigateTo(tester, 'Konto');
    await navigateTo(tester, 'Konto');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('selecting Start clears the previous screens', (tester) async {
    await tester.pumpWidget(const SednoApp());
    await navigateTo(tester, 'Historia');
    await navigateTo(tester, 'Start');
    await navigateTo(tester, 'Konto');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.binding.handlePopRoute();
    expect(
      systemCalls.where((call) => call.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  });

  testWidgets('system back closes the menu before returning from Konto', (
    tester,
  ) async {
    await tester.pumpWidget(const SednoApp());
    await navigateTo(tester, 'Konto');
    await tester.tap(find.byTooltip('Menu użytkownika'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Zamknij menu'), findsNothing);
    expect(find.text('Tutaj pojawią się opcje konta.'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      systemCalls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );
  });

  testWidgets('opens Start with the Polish application name', (tester) async {
    await tester.pumpWidget(const SednoApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Sedno - uprość tekst:'), findsOneWidget);
    expect(find.text('Witaj w Sedno'), findsNothing);
    expect(find.byTooltip('Menu użytkownika'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(Tab), findsNothing);
  });

  testWidgets('navigates between top tabs', (tester) async {
    await tester.pumpWidget(const SednoApp());

    await navigateTo(tester, 'Historia');
    await tester.pumpAndSettle();
    expect(find.text('Nie masz jeszcze zapisanych tekstów.'), findsOneWidget);

    await navigateTo(tester, 'Konto');
    await tester.pumpAndSettle();
    expect(find.text('Tutaj pojawią się opcje konta.'), findsOneWidget);

    await navigateTo(tester, 'Start');
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('preserves entered text after switching tabs', (tester) async {
    await tester.pumpWidget(const SednoApp());
    await tester.enterText(find.byType(TextField), 'Przykładowy tekst');

    await navigateTo(tester, 'Historia');
    await tester.pumpAndSettle();
    await navigateTo(tester, 'Konto');
    await tester.pumpAndSettle();
    await navigateTo(tester, 'Start');
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Przykładowy tekst',
    );
  });

  testWidgets('tabs and input expose accessible semantics and touch targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const SednoApp());

    expect(
      tester.getSize(find.byTooltip('Menu użytkownika')).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.bySemanticsLabel('Aparat'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('cameraButton'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('simplifyButton'))).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  testWidgets('uses a light high contrast theme', (tester) async {
    await tester.pumpWidget(const SednoApp());
    final theme = Theme.of(tester.element(find.byType(TextField)));

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppTheme.blue);
    expect(theme.colorScheme.onSurface, AppTheme.navy);
    expect(theme.scaffoldBackgroundColor, Colors.white);
  });

  for (final screenHeight in [640.0, 892.0, 1280.0]) {
    testWidgets(
      'home actions keep compact bottom spacing at height $screenHeight',
      (tester) async {
        tester.view.physicalSize = Size(412, screenHeight);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        await tester.pumpWidget(const SednoApp());
        final submit = tester.getRect(find.byKey(const Key('simplifyButton')));
        final camera = tester.getRect(find.byKey(const Key('cameraButton')));
        expect(screenHeight - submit.bottom, closeTo(32 + 24, .1));
        expect(camera.bottom, lessThanOrEqualTo(submit.bottom));
        expect(submit.center.dx, closeTo(206, .1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('large text remains usable on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2.5)),
        child: SednoApp(),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);

    await navigateTo(tester, 'Konto');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tutaj pojawią się opcje konta.'), findsOneWidget);
  });
}
