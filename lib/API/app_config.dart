AppConfig appConfig = AppConfig(version: 26, codeName: '7.2.4');

class AppConfig {
  AppConfig({required this.version, required this.codeName});
  int version;
  String codeName;
  Uri updateUri = Uri.parse(
      'https://api.github.com/repos/bhupendr1973/patro/releases/latest',);
}
