import 'enums.dart';

/// The thing being tracked (a truck, a pet, a set of keys...).
/// Separate from the physical [TrackerDevice] so trackers can be reassigned.
class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.registration,
    this.description,
    this.categoryOverride,
  });

  final String id;
  final String name;
  final AssetType type;
  final DateTime createdAt;
  final String? registration;
  final String? description;
  final AssetCategory? categoryOverride;

  /// Workspace the asset belongs to. Defaults from the type, but e.g. a car
  /// can be a business fleet vehicle.
  AssetCategory get category => categoryOverride ?? type.category;

  Asset copyWith({
    String? name,
    AssetType? type,
    String? registration,
    String? description,
  }) =>
      Asset(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        createdAt: createdAt,
        registration: registration ?? this.registration,
        description: description ?? this.description,
        categoryOverride: categoryOverride,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'registration': registration,
        'description': description,
        'category': categoryOverride?.name,
      };

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
        id: j['id'] as String,
        name: j['name'] as String,
        type: enumByName(AssetType.values, j['type'], AssetType.generic),
        createdAt: DateTime.parse(j['createdAt'] as String),
        registration: j['registration'] as String?,
        description: j['description'] as String?,
        categoryOverride: j['category'] == null
            ? null
            : enumByName(AssetCategory.values, j['category'], AssetCategory.personal),
      );
}
