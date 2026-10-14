class HomeViewModel {
  const HomeViewModel({required this.appName});

  final String appName;

  String get welcomeMessage => 'Witaj w $appName';
}
