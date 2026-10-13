class HomeViewModel {
  const HomeViewModel({required this.appName});

  final String appName;

  String get welcomeMessage => 'Welcome to $appName';
}
