import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/about/presentation/about_screen.dart';
import 'package:sedno_app/features/account/presentation/user_menu_screen.dart';

void main() {
  testWidgets('about opens from the menu and returns to it', (tester) async {
    await tester.pumpWidget(const SednoApp());
    await tester.tap(find.byTooltip('Menu użytkownika'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('O aplikacji'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('O aplikacji'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.byTooltip('Wróć'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UserMenuScreen), findsOneWidget);
  });

  testWidgets('menu opens full screen and closing preserves the editor', (
    tester,
  ) async {
    await tester.pumpWidget(const SednoApp());
    await tester.enterText(find.byType(TextField), 'Mój tekst');
    await tester.tap(find.byTooltip('Menu użytkownika'));
    await tester.pumpAndSettle();
    expect(find.byType(UserMenuScreen), findsOneWidget);
    expect(find.text('Witaj w Sedno'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Konto'), findsOneWidget);
    expect(find.text('Historia'), findsOneWidget);
    expect(find.byType(PopupMenuItem<int>), findsNothing);
    await tester.tap(find.byTooltip('Zamknij menu'));
    await tester.pumpAndSettle();
    expect(find.byType(UserMenuScreen), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mój tekst',
    );
  });

  testWidgets('system back dismisses menu without changing the active screen', (
    tester,
  ) async {
    await tester.pumpWidget(const SednoApp());
    await tester.tap(find.byTooltip('Menu użytkownika'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UserMenuScreen), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('privacy is accessible from the panel and returns to it', (
    tester,
  ) async {
    await tester.pumpWidget(const SednoApp());
    await tester.tap(find.byTooltip('Menu użytkownika'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prywatność i dane'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prywatność i dane'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Zdjęcia zostają na urządzeniu'),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Zamknij menu'), findsOneWidget);
  });

  testWidgets(
    'menu supports large text, scrolling and accessible touch targets',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2.5)),
            child: child!,
          ),
          home: const UserMenuScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byTooltip('Zamknij menu')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, 'Konto')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.ensureVisible(find.text('Historia'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.widgetWithText(ListTile, 'Historia')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.scrollUntilVisible(
        find.text('Prywatność i dane'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
