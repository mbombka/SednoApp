/// Limits reset at 00:00 UTC on the server. Users see that moment as a time
/// on their phone's clock, so daylight saving time and travel need no wording.
abstract final class QuotaReset {
  /// The next 00:00 UTC after [now]; used when the server's time is not known.
  static DateTime next(DateTime now) {
    final utc = now.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day + 1);
  }

  /// Local clock time of [resetAt], e.g. "2:00". Prefer the server's
  /// `resetAt`; without it, the next reset is computed from [now].
  static String localTime({
    DateTime? resetAt,
    DateTime? now,
    DateTime Function(DateTime utc)? toLocal,
  }) {
    final moment = resetAt ?? next(now ?? DateTime.now());
    final local = (toLocal ?? (utc) => utc.toLocal())(moment.toUtc());
    return '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}
