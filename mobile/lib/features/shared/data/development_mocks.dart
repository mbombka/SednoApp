import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';
import 'package:sedno_app/features/quota/domain/quota_repository.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

typedef Clock = DateTime Function();

void _developmentOnly() {
  if (const bool.fromEnvironment('dart.vm.product')) {
    throw StateError('Makiety są niedostępne w wersji produkcyjnej.');
  }
}

class MockQuotaRepository implements QuotaRepository {
  MockQuotaRepository({required this.clock, this.tier = QuotaTier.free}) {
    _developmentOnly();
  }

  final Clock clock;
  final QuotaTier tier;
  DateTime? _day;
  int _used = 0;

  @override
  Future<QuotaState> current() async => _snapshot();

  QuotaState _snapshot() {
    final now = clock().toUtc();
    final day = DateTime.utc(now.year, now.month, now.day);
    if (_day != day) {
      _day = day;
      _used = 0;
    }
    final limit = tier == QuotaTier.free ? 5 : 400;
    return QuotaState(
      tier: tier,
      limit: limit,
      used: _used,
      remaining: limit - _used,
      serverTime: now,
      resetAt: day.add(const Duration(days: 1)),
    );
  }

  QuotaState consume() {
    final state = _snapshot();
    if (state.remaining == 0) throw const QuotaExceededException();
    _used++;
    return _snapshot();
  }
}

class QuotaExceededException implements Exception {
  const QuotaExceededException();
}

/// Deterministic development stand-in. It does not call or imitate an AI provider.
class MockSimplificationRepository implements SimplificationRepository {
  MockSimplificationRepository({required this.quota, required this.clock}) {
    _developmentOnly();
  }

  final MockQuotaRepository quota;
  final Clock clock;
  final Map<String, SimplificationResponse> _responses = {};
  final Map<String, String> _requestTexts = {};

  @override
  Future<SimplificationResponse> simplify(SimplificationRequest request) async {
    final previous = _responses[request.requestId];
    if (previous != null) {
      if (_requestTexts[request.requestId] != request.input.value) {
        throw const FormatException('Identyfikator żądania jest już użyty.');
      }
      return previous;
    }
    final quotaState = quota.consume();
    final response = SimplificationResponse(
      result: SimplificationResult(
        id: request.requestId,
        text: 'Przykładowe uproszczenie: ${request.input.value}',
        createdAt: clock().toUtc(),
      ),
      quota: quotaState,
    );
    _responses[request.requestId] = response;
    _requestTexts[request.requestId] = request.input.value;
    return response;
  }
}

/// In-memory history mock. Real encrypted storage is a later task.
class MockHistoryRepository implements HistoryRepository {
  MockHistoryRepository({required this.clock}) {
    _developmentOnly();
  }

  final Clock clock;
  final Map<String, HistoryEntry> _entries = {};

  void _purge() =>
      _entries.removeWhere((_, entry) => entry.isExpiredAt(clock()));

  @override
  Future<void> save(HistoryEntry entry) async {
    _purge();
    if (!entry.isExpiredAt(clock())) _entries[entry.id] = entry;
  }

  @override
  Future<List<HistoryEntry>> readAll() async {
    _purge();
    final entries = _entries.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<void> delete(String id) async {
    _purge();
    _entries.remove(id);
  }

  @override
  Future<void> clear() async => _entries.clear();
}

class MockAccountRepository implements AccountRepository {
  MockAccountRepository({required this.history}) {
    _developmentOnly();
  }

  final HistoryRepository history;
  Account _account = Account(id: 'dev-guest', provider: IdentityProvider.guest);

  @override
  Future<Account> current() async => _account;

  @override
  Future<Account> signInWithGoogle() async =>
      _account = Account(id: 'dev-google', provider: IdentityProvider.google);

  @override
  Future<Account> signInWithEmail(String email, String password) async =>
      _account = Account(
        id: 'dev-email',
        provider: IdentityProvider.email,
        email: email,
      );

  @override
  Future<Account> registerWithEmail(String email, String password) async =>
      _account = Account(
        id: 'dev-email',
        provider: IdentityProvider.email,
        email: email.trim(),
        emailVerificationRequired: true,
      );

  @override
  Future<void> resendVerificationEmail() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<Account> checkEmailVerification() async => _account = Account(
    id: _account.id,
    provider: _account.provider,
    email: _account.email,
  );

  @override
  Future<void> signOut() async {
    await history.clear();
    _account = Account(id: 'dev-guest', provider: IdentityProvider.guest);
  }

  @override
  Future<void> deleteAccount() async => signOut();
}
