import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/account/presentation/account_screen.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_panel.dart';

class Store implements SubscriptionStore {
  final events = StreamController<List<StorePurchase>>.broadcast(sync: true);
  String? binding;
  bool restored = false;
  Completer<SubscriptionOffer>? delayedOffer;
  @override
  Stream<List<StorePurchase>> get purchases => events.stream;
  @override
  Future<SubscriptionOffer> offer() async => delayedOffer == null
      ? const SubscriptionOffer('12,34 zł')
      : await delayedOffer!.future;
  @override
  Future<void> buy(String accountBinding) async {
    binding = accountBinding;
  }

  @override
  Future<void> restore() async {
    restored = true;
  }

  int manages = 0;
  bool manageFails = false;
  @override
  Future<void> manage() async {
    manages++;
    if (manageFails) throw StateError('no store');
  }
}

class Backend implements SubscriptionRepository {
  bool active = false;
  bool fail = false;
  int verifications = 0;
  int reads = 0;
  @override
  Future<SubscriptionStatus> current() async {
    reads++;
    return SubscriptionStatus(
      active: active,
      state: active ? 'ACTIVE' : 'none',
      accountBinding: 'server-binding',
    );
  }

  @override
  Future<SubscriptionStatus> verify(String token) async {
    verifications++;
    if (fail) throw StateError('offline');
    return current();
  }
}

void main() {
  late Store store;
  late Backend backend;
  late SubscriptionViewModel model;
  var modelDisposed = false;
  setUp(() {
    modelDisposed = false;
    store = Store();
    backend = Backend();
    model = SubscriptionViewModel(
      store: store,
      repository: backend,
      productId: 'monthly',
    );
  });
  tearDown(() async {
    if (!modelDisposed) model.dispose();
    await store.events.close();
  });
  Future<void> event(
    StorePurchaseState state, {
    String product = 'monthly',
  }) async {
    store.events.add([StorePurchase(product, 'token', state)]);
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'manage opens Google Play and explains the manual path on failure',
    () async {
      await model.manage();
      expect(store.manages, 1);
      expect(model.message, isNull);
      store.manageFails = true;
      await model.manage();
      expect(model.message, contains('Płatności i subskrypcje'));
    },
  );

  testWidgets('account screen shows subscription below sign-in controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountScreen(
            repository: MockAccountRepository(
              history: MockHistoryRepository(clock: DateTime.now),
            ),
            subscriptionModel: model,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final signIn = tester.getTopLeft(find.text('Zaloguj przez Google')).dy;
    final subscription = tester.getTopLeft(find.text('Subskrypcja')).dy;
    expect(subscription, greaterThan(signIn));
    expect(find.text('Kup subskrypcję', skipOffstage: false), findsOneWidget);
  });

  testWidgets('reset time comes from the server quota as local time', (
    tester,
  ) async {
    final resetAt = DateTime.utc(2026, 10, 21);
    final quota = ValueNotifier<QuotaState?>(null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubscriptionPanel(model: model, quota: quota),
          ),
        ),
      ),
    );
    expect(find.textContaining('Nowy limit codziennie o '), findsOneWidget);
    quota.value = QuotaState(
      tier: QuotaTier.free,
      limit: 5,
      used: 0,
      remaining: 5,
      serverTime: DateTime.utc(2026, 10, 20, 12),
      resetAt: resetAt,
    );
    await tester.pump();
    expect(
      find.text(
        'Nowy limit codziennie o ${QuotaReset.localTime(resetAt: resetAt)}.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('UTC'), findsNothing);
  });

  testWidgets('sign-in hint is shown only to signed-out users', (tester) async {
    const hint =
        'Aby kupić lub przywrócić subskrypcję, zaloguj się na swoje konto Sedno.';
    for (final signedIn in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SubscriptionPanel(model: model, signedIn: signedIn),
            ),
          ),
        ),
      );
      expect(find.text(hint), signedIn ? findsNothing : findsOneWidget);
    }
  });

  testWidgets('active subscription shows only the Google Play manage action', (
    tester,
  ) async {
    Future<void> show() async {
      await model.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SubscriptionPanel(model: model)),
          ),
        ),
      );
    }

    const purchaseActions = [
      'Kup subskrypcję',
      'Przywróć zakupy',
      'Odśwież subskrypcję',
    ];
    await show();
    for (final label in purchaseActions) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Zarządzaj subskrypcją w Google Play'), findsNothing);

    backend.active = true;
    await show();
    for (final label in purchaseActions) {
      expect(find.text(label), findsNothing);
    }
    await tester.tap(find.text('Zarządzaj subskrypcją w Google Play'));
    expect(store.manages, 1);
  });

  test('server verification starts before the store offer resolves', () async {
    store.delayedOffer = Completer<SubscriptionOffer>();
    final starting = model.start();
    await Future<void>.delayed(Duration.zero);
    expect(backend.reads, 1);
    expect(model.status, isNotNull);
    store.delayedOffer!.complete(const SubscriptionOffer('9,99 zł'));
    await starting;
  });

  testWidgets('refreshes at startup and on resume without periodic polling', (
    tester,
  ) async {
    await tester.pumpWidget(SednoApp(subscriptionModel: model));
    await tester.pump();
    expect(backend.reads, 1);
    await tester.enterText(find.byType(TextField), 'Tekst do uproszczenia');
    expect(find.text('Tekst do uproszczenia'), findsOneWidget);
    // No periodic polling: refresh happens only at startup and on resume.
    await tester.pump(const Duration(minutes: 30));
    expect(backend.reads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(backend.reads, 2);
    model.dispose();
    modelDisposed = true;
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'purchase uses server account binding and pending never grants access',
    () async {
      await model.start();
      await model.buy();
      expect(store.binding, 'server-binding');
      await event(StorePurchaseState.pending);
      expect(model.status!.active, false);
      expect(backend.verifications, 0);
      expect(model.message, contains('oczekuje'));
      await event(StorePurchaseState.canceled);
      expect(model.message, 'Zakup anulowano.');
      await event(StorePurchaseState.error);
      expect(model.message, contains('Nie udało się'));
    },
  );
  test(
    'purchase and restore trust backend; retry follows failed verification',
    () async {
      await model.start();
      backend.fail = true;
      await event(StorePurchaseState.purchased);
      expect(model.status, isNull);
      expect(model.message, contains('przywróć'));
      backend.fail = false;
      backend.active = true;
      await model.restore();
      expect(store.restored, true);
      await event(StorePurchaseState.restored);
      expect(model.status!.active, true);
      backend.active = false; // expired, canceled after expiry, or refunded
      await model.refresh();
      expect(model.status!.active, false);
      await event(StorePurchaseState.purchased, product: 'other');
      expect(backend.verifications, 2);
    },
  );
  testWidgets('shows localized store price and purchase/restore controls', (
    tester,
  ) async {
    await model.start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SubscriptionPanel(model: model)),
      ),
    );
    expect(find.text('12,34 zł miesięcznie'), findsOneWidget);
    expect(find.textContaining('9,99'), findsNothing);
    await tester.tap(find.text('Kup subskrypcję'));
    await tester.pumpAndSettle();
    expect(store.binding, 'server-binding');
    await tester.tap(find.text('Przywróć zakupy'));
    await tester.pumpAndSettle();
    expect(store.restored, true);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
    modelDisposed = true;
  });
  testWidgets(
    'tester hides purchase until access expires but can restore purchases',
    (tester) async {
      final now = DateTime.utc(2026, 10, 22, 12);
      final quota = ValueNotifier<QuotaState?>(
        QuotaState(
          tier: QuotaTier.tester,
          limit: 400,
          used: 30,
          remaining: 370,
          serverTime: now,
          resetAt: DateTime.utc(2026, 10, 23),
          testerAccessExpiresAt: now.add(const Duration(days: 1)),
        ),
      );
      addTearDown(quota.dispose);
      await model.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SubscriptionPanel(
                model: model,
                signedIn: true,
                quota: quota,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Kup subskrypcję'), findsNothing);
      expect(find.text('Przywróć zakupy'), findsOneWidget);
      expect(find.text('Zarządzaj subskrypcją w Google Play'), findsNothing);
      quota.value = QuotaState(
        tier: QuotaTier.free,
        limit: 5,
        used: 30,
        remaining: 0,
        serverTime: now,
        resetAt: DateTime.utc(2026, 10, 23),
      );
      await tester.pump();
      expect(find.text('Kup subskrypcję'), findsOneWidget);
    },
  );
}
