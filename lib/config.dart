class Config {
  static const String appName = 'Payload';
  static const String appVersion = '1.1.12';
  static const String devGithubUrl = "https://github.com/hunter87ff";
  static const String orgGithubUrl = "https://github.com/nexinlabs";
  static const String orgWebsiteUrl = "https://nexinlabs.tech";
  static String get client => "${appName.toLowerCase()}-api-client/$appVersion";
}
