class ChildDeviceModel {
  final int deviceId;
  final int parentId;
  final String childName;
  final bool isLocked;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  ChildDeviceModel({
    required this.deviceId,
    required this.parentId,
    required this.childName,
    this.isLocked = false,
    this.latitude,
    this.longitude,
    this.lastUpdated,
  });

  factory ChildDeviceModel.fromJson(Map<String, dynamic> json) {
    return ChildDeviceModel(
      deviceId: json['deviceId'] ?? json['id'] ?? 0,
      parentId: json['parentId'] ?? 0,
      childName: json['childName'] ?? 'Bé',
      isLocked: json['isLocked'] ?? json['isScreenLocked'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'parentId': parentId,
      'childName': childName,
      'isLocked': isLocked,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}
