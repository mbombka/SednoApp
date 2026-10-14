import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/app/app_theme.dart';

void main() {
  testWidgets('opens Start with the Polish application name', (tester) async {
    await tester.pumpWidget(const SednoApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text(SednoApp.displayName), findsOneWidget);
    expect(find.text('Witaj w Sedno'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(3));
  });

  testWidgets('navigates between top tabs', (tester) async {
    await tester.pumpWidget(const SednoApp());

    await tester.tap(find.text('Historia').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Tutaj pojawi się historia uproszczonych tekstów.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Konto').first);
    await tester.pumpAndSettle();
    expect(find.text('Tutaj pojawią się opcje konta.'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('preserves entered text after switching tabs', (tester) async {
    await tester.pumpWidget(const SednoApp());
    await tester.enterText(find.byType(TextField), 'Przykładowy tekst');

    await tester.tap(find.text('Historia').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konto').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
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

    final tabs = find.byType(Tab);
    expect(tester.getSemantics(tabs.at(0)).label, contains('Start'));
    expect(
      tester.getSemantics(tabs.at(0)).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(tester.getSemantics(tabs.at(1)).label, contains('Historia'));
    expect(tester.getSemantics(tabs.at(2)).label, contains('Konto'));
    for (var index = 0; index < 3; index++) {
      expect(tester.getSize(tabs.at(index)).height, greaterThanOrEqualTo(48));
    }
    expect(find.bySemanticsLabel('Tekst do uproszczenia'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Konto').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konto').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tutaj pojawią się opcje konta.'), findsOneWidget);
  });
}
