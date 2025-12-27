class SettingsModel {
  final int timeout; // in seconds
  final bool sslVerification;
  final bool followRedirects;
  final bool syntaxHighlighting;

  SettingsModel({
    this.timeout = 30,
    this.sslVerification = true,
    this.followRedirects = true,
    this.syntaxHighlighting = true,
  });

  SettingsModel copyWith({
    int? timeout,
    bool? sslVerification,
    bool? followRedirects,
    bool? syntaxHighlighting,
  }) {
    return SettingsModel(
      timeout: timeout ?? this.timeout,
      sslVerification: sslVerification ?? this.sslVerification,
      followRedirects: followRedirects ?? this.followRedirects,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
    );
  }

  Map<String, dynamic> toJson() => {
    'timeout': timeout,
    'sslVerification': sslVerification,
    'followRedirects': followRedirects,
    'syntaxHighlighting': syntaxHighlighting,
  };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
    timeout: json['timeout'] ?? 30,
    sslVerification: json['sslVerification'] ?? true,
    followRedirects: json['followRedirects'] ?? true,
    syntaxHighlighting: json['syntaxHighlighting'] ?? true,
  );
}
