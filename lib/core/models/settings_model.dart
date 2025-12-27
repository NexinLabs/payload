class SettingsModel {
  final int timeout; // in seconds
  final bool sslVerification;
  final bool followRedirects;

  SettingsModel({
    this.timeout = 30,
    this.sslVerification = true,
    this.followRedirects = true,
  });

  SettingsModel copyWith({
    int? timeout,
    bool? sslVerification,
    bool? followRedirects,
  }) {
    return SettingsModel(
      timeout: timeout ?? this.timeout,
      sslVerification: sslVerification ?? this.sslVerification,
      followRedirects: followRedirects ?? this.followRedirects,
    );
  }

  Map<String, dynamic> toJson() => {
    'timeout': timeout,
    'sslVerification': sslVerification,
    'followRedirects': followRedirects,
  };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
    timeout: json['timeout'] ?? 30,
    sslVerification: json['sslVerification'] ?? true,
    followRedirects: json['followRedirects'] ?? true,
  );
}
