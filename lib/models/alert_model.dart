class AlertModel {
  final int alertId;
  final int deviceId;
  final String alertType;
  final double valueRecorded;
  final DateTime createdAt;

  AlertModel({
    required this.alertId,
    required this.deviceId,
    required this.alertType,
    required this.valueRecorded,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alertId'] ?? json['id'] ?? 0,
      deviceId: json['deviceId'] ?? 0,
      alertType: json['alertType'] ?? 'Thông báo',
      valueRecorded: (json['valueRecorded'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'deviceId': deviceId,
      'alertType': alertType,
      'valueRecorded': valueRecorded,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
