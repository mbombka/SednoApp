import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_information.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/about/presentation/about_screen.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';
import 'package:sedno_app/features/shared/presentation/website_information.dart';

void main() {
  testWidgets('about explains the app, allowance, AI and contact', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AboutScreen()),
    );
    expect(find.textContaining('osób słabosłyszących'), findsOneWidget);
    expect(find.textContaining('4000 znaków'), findsOneWidget);
    // Prices depend on the Google Play country; the screen names none.
    expect(find.textContaining(RegExp(r'\d,\d\d')), findsNothing);
    expect(find.text('Z subskrypcją: 400 tekstów dziennie.'), findsOneWidget);
    expect(
      find.text(
        'Nowy limit codziennie o ${QuotaReset.localTime()} (00:00 UTC).',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('AI może popełniać błędy'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kontakt: ${AppInformation.contact}'),
      200,
    );
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

  testWidgets('website address is a link that opens the browser', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          openUrl: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text(AppInformation.website), 200);
    await tester.ensureVisible(find.text(AppInformation.website));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppInformation.website));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse(AppInformation.website)]);
    expect(find.textContaining('Kopiuj'), findsNothing);
  });

  for (final address in [
    AppInformation.privacyUrl,
    AppInformation.deletionUrl,
  ]) {
    testWidgets('opens the requested policy address $address', (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WebsiteInformation(
              address: address,
              opener: (uri) async {
                opened.add(uri);
                return true;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text(address));
      await tester.pumpAndSettle();
      expect(opened, [Uri.parse(address)]);
    });
  }

  testWidgets('explains when no browser can open a link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WebsiteInformation(opener: (_) async => false)),
      ),
    );
    await tester.tap(find.text(AppInformation.website));
    await tester.pumpAndSettle();
    expect(
      find.text('Nie można otworzyć strony. Sprawdź przeglądarkę.'),
      findsOneWidget,
    );
  });

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
        await tester.scrollUntilVisible(
          find.text(AppInformation.website),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .getSize(find.widgetWithText(TextButton, AppInformation.website))
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
