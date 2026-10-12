class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNo,
    required this.joinedAt,
    this.assetId,
    this.rating = 4.6,
    this.tripsCount = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String licenseNo;
  final DateTime joinedAt;

  /// The vehicle asset this driver is currently assigned to.
  final String? assetId;
  final double rating;
  final int tripsCount;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Driver copyWith({String? name, String? phone, String? licenseNo, String? assetId, bool clearAsset = false}) =>
      Driver(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        licenseNo: licenseNo ?? this.licenseNo,
        joinedAt: joinedAt,
        assetId: clearAsset ? null : (assetId ?? this.assetId),
        rating: rating,
        tripsCount: tripsCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'license': licenseNo,
        'joinedAt': joinedAt.toIso8601String(),
        'assetId': assetId,
        'rating': rating,
        'trips': tripsCount,
      };

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String,
        licenseNo: j['license'] as String,
        joinedAt: DateTime.parse(j['joinedAt'] as String),
        assetId: j['assetId'] as String?,
        rating: (j['rating'] as num).toDouble(),
        tripsCount: (j['trips'] as num).toInt(),
      );
}
