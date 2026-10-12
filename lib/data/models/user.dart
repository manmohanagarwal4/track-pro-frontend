import 'enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    this.phone = '',
    this.organization = 'TrackPro Logistics Pvt. Ltd.',
  });

  final String id;
  final String name;
  final String email;
  final AccountType accountType;
  final String phone;
  final String organization;

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({String? name, String? email, AccountType? accountType, String? phone}) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        accountType: accountType ?? this.accountType,
        phone: phone ?? this.phone,
        organization: organization,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'accountType': accountType.name,
        'phone': phone,
        'organization': organization,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        accountType: enumByName(AccountType.values, j['accountType'], AccountType.business),
        phone: j['phone'] as String? ?? '',
        organization: j['organization'] as String? ?? 'TrackPro Logistics Pvt. Ltd.',
      );
}

class ShareLink {
  const ShareLink({
    required this.id,
    required this.deviceId,
    required this.url,
    required this.permission,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String deviceId;
  final String url;
  final SharePermission permission;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isActive(DateTime now) => expiresAt.isAfter(now);

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'url': url,
        'permission': permission.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory ShareLink.fromJson(Map<String, dynamic> j) => ShareLink(
        id: j['id'] as String,
        deviceId: j['deviceId'] as String,
        url: j['url'] as String,
        permission: enumByName(SharePermission.values, j['permission'], SharePermission.viewOnly),
        createdAt: DateTime.parse(j['createdAt'] as String),
        expiresAt: DateTime.parse(j['expiresAt'] as String),
      );
}
