import 'package:flutter_test/flutter_test.dart';
import 'package:simplifier_app/features/home/presentation/home_view_model.dart';

void main() {
  group('HomeViewModel', () {
    test('builds a welcome message for the configured app name', () {
      const viewModel = HomeViewModel(appName: 'SimplifierApp');

      expect(viewModel.welcomeMessage, 'Witaj w SimplifierApp');
    });

    test('uses a different app name when one is supplied', () {
      const viewModel = HomeViewModel(appName: 'Another App');

      expect(viewModel.welcomeMessage, 'Witaj w Another App');
    });
  });
}
