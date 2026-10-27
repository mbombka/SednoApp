// Run explicitly; this renders real app widgets with synthetic offline accounts.
// flutter test tool/account_guide_screenshots_test.dart --run-skipped
//   --dart-define=GUIDE_FONT_DIR=/path/to/flutter/bin/cache/artifacts/material_fonts
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/app/app_language.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';
import 'package:sedno_app/l10n/app_localizations.dart';

class _GuideAccount implements AccountRepository {
  Account account = Account(id: 'guide', provider: IdentityProvider.guest);
  bool confirmed = false;
  @override
  Future<Account> current() async => account;
  @override
  Future<Account> registerWithEmail(String email, String password) async =>
      account = Account(
        id: 'guide',
        provider: IdentityProvider.email,
        email: email,
        emailVerificationRequired: true,
      );
  @override
  Future<Account> checkEmailVerification() async => account = Account(
    id: 'guide',
    provider: IdentityProvider.email,
    email: 'anna@example.com',
    emailVerificationRequired: !confirmed,
  );
  @override
  Future<void> resendVerificationEmail() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount({String? password}) async {}
  @override
  Future<Account> signInWithEmail(String email, String password) =>
      throw UnimplementedError();
  @override
  Future<Account> signInWithGoogle() => throw UnimplementedError();
}

void main() {
  const fonts = String.fromEnvironment('GUIDE_FONT_DIR');
  testWidgets('render account guide in every app language', (tester) async {
    final loader = FontLoader('Roboto');
    for (final name in [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ]) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('$fonts/$name').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final output = Directory('../website/SednoWebsite/public/img/account');
    await tester.runAsync(() => output.create(recursive: true));
    for (final language in AppLanguage.values) {
      final slug = language.code.toLowerCase();
      final strings = lookupAppLocalizations(language.locale);
      final controller = LanguageController(deviceLocales: [language.locale]);
      final repository = _GuideAccount();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: SednoApp(
            languageController: controller,
            accountRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> capture(String name, List<Finder> targets) async {
        final rects = targets.map(tester.getRect).toList();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final original = await boundary.toImage(pixelRatio: 2);
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder)
            ..scale(2)
            ..drawImageRect(
              original,
              Rect.fromLTWH(
                0,
                0,
                original.width.toDouble(),
                original.height.toDouble(),
              ),
              const Rect.fromLTWH(0, 0, 412, 915),
              Paint(),
            );
          for (final rect in rects) {
            canvas.drawOval(
              rect.inflate(5).intersect(const Rect.fromLTWH(4, 4, 404, 907)),
              Paint()
                ..color = const Color(0xFFD71920)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 5,
            );
          }
          final picture = recorder.endRecording();
          final image = await picture.toImage(824, 1830);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${output.path}/$slug-$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
          original.dispose();
        });
        expect(tester.takeException(), isNull, reason: '$slug/$name');
      }

      await capture('home', [find.byTooltip(strings.userMenu)]);
      await tester.tap(find.byTooltip(strings.userMenu));
      await tester.pumpAndSettle();
      await capture('menu', [
        find.widgetWithText(OutlinedButton, strings.account),
      ]);
      await tester.tap(find.widgetWithText(OutlinedButton, strings.account));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(strings.createAccountLink));
      await capture('sign-in', [
        find.widgetWithText(TextButton, strings.createAccountLink),
      ]);
      await tester.tap(find.text(strings.createAccountLink));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'anna@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'sample-password');
      await tester.enterText(find.byType(TextField).at(2), 'sample-password');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(strings.createAccount));
      await capture('register', [
        find.widgetWithText(FilledButton, strings.createAccount),
      ]);
      await tester.tap(find.text(strings.createAccount));
      await tester.pumpAndSettle();
      await capture('verify', [
        find.widgetWithText(FilledButton, strings.checkVerification),
      ]);
      repository.confirmed = true;
      await tester.tap(find.text(strings.checkVerification));
      await tester.pumpAndSettle();
      await capture('done', []);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  }, skip: fonts.isEmpty);
}
