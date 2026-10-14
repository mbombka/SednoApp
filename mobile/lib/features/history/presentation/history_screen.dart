import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simplifier_app/features/history/domain/history_repository.dart';
import 'package:simplifier_app/features/history/presentation/history_view_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.repository,
    required this.revision,
    super.key,
  });

  final HistoryRepository repository;
  final ValueListenable<int> revision;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryViewModel _model;
  TabController? _tabs;

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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _model,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historia', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Teksty są przechowywane tylko na tym urządzeniu przez 7 dni.',
          ),
          const SizedBox(height: 16),
          if (_model.isLoading)
            const CircularProgressIndicator()
          else if (_model.hasError)
            const Text('Nie udało się odczytać historii.')
          else if (_model.entries.isEmpty)
            const Text('Tutaj pojawi się historia uproszczonych tekstów.')
          else
            ..._model.entries.map(
              (entry) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(entry.result.text),
                      const SizedBox(height: 8),
                      Text('Oryginał: ${entry.original.value}'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _model.delete(entry.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            semanticLabel: 'Usuń',
                          ),
                          label: const Text('Usuń'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
