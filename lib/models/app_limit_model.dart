class AppLimitModel {
  final int limitId;
  final int deviceId;
  final String appName;
  final String packageName;
  final int allowedMinutesPerDay;
  final bool isBlocked;

  AppLimitModel({
    required this.limitId,
    required this.deviceId,
    required this.appName,
    required this.packageName,
    required this.allowedMinutesPerDay,
    required this.isBlocked,
  });

  factory AppLimitModel.fromJson(Map<String, dynamic> json) {
    return AppLimitModel(
      limitId: json['limitId'] ?? json['id'] ?? 0,
      deviceId: json['deviceId'] ?? 0,
      appName: json['appName'] ?? '',
      packageName: json['packageName'] ?? '',
      allowedMinutesPerDay: json['allowedMinutesPerDay'] ?? 60,
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limitId': limitId,
      'deviceId': deviceId,
      'appName': appName,
      'packageName': packageName,
      'allowedMinutesPerDay': allowedMinutesPerDay,
      'isBlocked': isBlocked,
    };
  }
}
