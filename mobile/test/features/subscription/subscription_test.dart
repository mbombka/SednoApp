import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_panel.dart';

class Store implements SubscriptionStore {
  final events = StreamController<List<StorePurchase>>.broadcast(sync: true);
  String? binding;
  bool restored = false;
  @override
  Stream<List<StorePurchase>> get purchases => events.stream;
  @override
  Future<SubscriptionOffer> offer() async =>
      const SubscriptionOffer('12,34 zł');
  @override
  Future<void> buy(String accountBinding) async {
    binding = accountBinding;
  }

  @override
  Future<void> restore() async {
    restored = true;
  }
}

class Backend implements SubscriptionRepository {
  bool active = false;
  bool fail = false;
  int verifications = 0;
  @override
  Future<SubscriptionStatus> current() async => SubscriptionStatus(
    active: active,
    state: active ? 'ACTIVE' : 'none',
    accountBinding: 'server-binding',
  );
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
  setUp(() {
    store = Store();
    backend = Backend();
    model = SubscriptionViewModel(
      store: store,
      repository: backend,
      productId: 'monthly',
    );
  });
  tearDown(() async {
    model.dispose();
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
    expect(find.textContaining('12,34 zł miesięcznie'), findsOneWidget);
    expect(find.textContaining('9,99'), findsNothing);
    await tester.tap(find.text('Kup subskrypcję'));
    await tester.pumpAndSettle();
    expect(store.binding, 'server-binding');
    await tester.tap(find.text('Przywróć zakupy'));
    await tester.pumpAndSettle();
    expect(store.restored, true);
  });
}
