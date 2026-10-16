import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_information.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/about/presentation/about_screen.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';
import 'package:sedno_app/features/shared/presentation/website_information.dart';

void main() {
  testWidgets('about explains the app, allowance, AI and contact', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AboutScreen()),
    );
    expect(find.textContaining('osobach słabosłyszących'), findsOneWidget);
    expect(find.textContaining('4000 znaków'), findsOneWidget);
    expect(find.textContaining('9,99 zł'), findsOneWidget);
    expect(find.textContaining('00:00 UTC'), findsOneWidget);
    expect(find.textContaining('AI może popełniać błędy'), findsOneWidget);
    expect(find.text('Kontakt: ${AppInformation.contact}'), findsOneWidget);
    expect(find.text(AppInformation.website), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Prywatność i dane'), 200);
    await tester.tap(find.text('Prywatność i dane'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.byTooltip('Wróć'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets('copies the HTTPS website address', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.scrollUntilVisible(find.text('Kopiuj adres strony'), 200);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kopiuj adres strony'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kopiuj adres strony'));
    await tester.pumpAndSettle();
    expect(copied, 'https://sedno.xyz');
    expect(find.text('Skopiowano adres strony.'), findsOneWidget);
  });

  for (final address in [
    AppInformation.privacyUrl,
    AppInformation.deletionUrl,
  ]) {
    testWidgets('copies the requested policy address $address', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WebsiteInformation(address: address)),
        ),
      );
      await tester.tap(find.text('Kopiuj adres strony'));
      await tester.pumpAndSettle();
      expect(copied, address);
    });
  }

  for (final screen in [const AboutScreen(), const PrivacyScreen()]) {
    testWidgets(
      '${screen.runtimeType} supports 250% text and accessibility guidelines',
      (tester) async {
        final semantics = tester.ensureSemantics();
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
            home: screen,
          ),
        );
        await tester.scrollUntilVisible(find.text('Kopiuj adres strony'), 150);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .getSize(
                find.widgetWithText(OutlinedButton, 'Kopiuj adres strony'),
              )
              .height,
          greaterThanOrEqualTo(48),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      },
    );
  }
}
