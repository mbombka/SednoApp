import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';
import 'package:sedno_app/features/history/presentation/history_view_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.repository,
    required this.revision,
    this.clock = DateTime.now,
    super.key,
  });

  final HistoryRepository repository;
  final ValueListenable<int> revision;
  final DateTime Function() clock;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryViewModel _model;
  TabController? _tabs;
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _model = HistoryViewModel(widget.repository)..refresh();
    widget.revision.addListener(_refresh);
  }

  void _refresh() => _model.refresh();

  void _onTabChanged() {
    if (_tabs?.index == 1) _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabs = DefaultTabController.maybeOf(context);
    if (tabs != _tabs) {
      _tabs?.removeListener(_onTabChanged);
      _tabs = tabs;
      _tabs?.addListener(_onTabChanged);
    }
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      oldWidget.revision.removeListener(_refresh);
      widget.revision.addListener(_refresh);
    }
    if (oldWidget.repository != widget.repository) {
      _model.dispose();
      _model = HistoryViewModel(widget.repository)..refresh();
    }
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabChanged);
    widget.revision.removeListener(_refresh);
    _model.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(HistoryEntry entry) async {
    // Deletion cannot be undone, so it always asks first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć ten tekst z historii?'),
        content: const Text('Tego nie można cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _model.delete(entry.id);
    if (!mounted || _model.hasError) return;
    _expanded.remove(entry.id);
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Usunięto tekst.')));
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć całą historię?'),
        content: const Text(
          'Wszystkie zapisane teksty zostaną usunięte z tego telefonu. Tego nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń całą historię'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final cleared = await _model.clearAll();
    if (!mounted || !cleared) return;
    _expanded.clear();
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Usunięto całą historię.')));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _model,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Historia', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          // Plain Polish: one piece of information per line.
          const Text('Teksty są zapisane tylko na tym telefonie.'),
          const Text('Każdy tekst usuwa się sam po 7 dniach.'),
          const Text('Wylogowanie usuwa całą historię.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('clearHistoryButton'),
            onPressed:
                _model.isLoading ||
                    _model.isClearing ||
                    (_model.entries.isEmpty && !_model.hasError)
                ? null
                : _confirmClearAll,
            icon: const Icon(Icons.delete_outline),
            iconAlignment: IconAlignment.end,
            label: const Text('Usuń całą historię teraz'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          if (_model.actionError case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(liveRegion: true, child: Text(message)),
            ),
          const SizedBox(height: 16),
          if (_model.isClearing)
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Usuwanie historii',
              ),
            )
          else if (_model.isLoading)
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Wczytywanie historii',
              ),
            )
          else if (_model.hasError) ...[
            const Text('Nie udało się wczytać historii.'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _refresh,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Spróbuj ponownie'),
            ),
          ] else if (_model.entries.isEmpty) ...[
            const Text('Nie masz jeszcze zapisanych tekstów.'),
            const Text(
              'Każdy uproszczony lub poprawiony tekst pojawi się tutaj.',
            ),
          ] else
            ..._model.entries.map(_entry),
        ],
      ),
    ),
  );

  Widget _entry(HistoryEntry entry) {
    final textTheme = Theme.of(context).textTheme;
    final now = widget.clock();
    final created = HistoryDates.created(entry.createdAt, now);
    final expanded = _expanded.contains(entry.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(created, style: textTheme.titleSmall),
            Text('Zostanie usunięty ${HistoryDates.expires(entry.createdAt)}.'),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                entry.result.mode == TextMode.correct
                    ? 'Wersja poprawiona'
                    : 'Wersja prosta',
                style: textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(entry.result.text),
            if (expanded) ...[
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text('Oryginalny tekst', style: textTheme.titleMedium),
              ),
              const SizedBox(height: 4),
              SelectableText(entry.original.value),
            ],
            const SizedBox(height: 8),
            // Wraps under large text instead of overflowing.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    expanded
                        ? _expanded.remove(entry.id)
                        : _expanded.add(entry.id);
                  }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(expanded ? 'Ukryj oryginał' : 'Pokaż oryginał'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(entry),
                  icon: const Icon(Icons.delete_outline),
                  // TalkBack names the entry instead of repeating "Usuń".
                  label: Text(
                    'Usuń',
                    semanticsLabel: 'Usuń tekst zapisany: $created',
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    // The icon grows with the system text size.
                    iconSize: MediaQuery.textScalerOf(context).scale(18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dates shown in the phone's local time, e.g. "Dziś, 13:05" or "17.10, 9:30".
abstract final class HistoryDates {
  static String created(DateTime createdAt, DateTime now) {
    final local = createdAt.toLocal();
    final today = now.toLocal();
    // Calendar days in UTC avoid 23/25-hour days around time changes.
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
    final day = switch (days) {
      0 => 'Dziś',
      1 => 'Wczoraj',
      _ => _date(local),
    };
    return '$day, ${local.hour}:${_two(local.minute)}';
  }

  /// The day the entry disappears (seven days after it was saved).
  static String expires(DateTime createdAt) =>
      _date(createdAt.add(const Duration(days: 7)).toLocal());

  static String _date(DateTime local) =>
      '${_two(local.day)}.${_two(local.month)}';
  static String _two(int value) => value.toString().padLeft(2, '0');
}
