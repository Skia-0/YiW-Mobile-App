class User {
  /// How long a user must wait between name changes.
  static const Duration nameChangeCooldown = Duration(days: 30);

  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String zone;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  /// Firebase Storage URL of the profile picture, if one has been set.
  final String? photoUrl;

  /// When [fullName] was last changed. Null means it has never been changed,
  /// so the first change is always allowed.
  final DateTime? nameLastChangedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.zone,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.photoUrl,
    this.nameLastChangedAt,
  });

  /// True when the display name may be changed right now.
  bool get canChangeName => nameChangeAvailableOn == null;

  /// The date the next name change becomes possible, or null if allowed now.
  DateTime? get nameChangeAvailableOn {
    if (nameLastChangedAt == null) return null;
    final next = nameLastChangedAt!.add(nameChangeCooldown);
    return next.isAfter(DateTime.now()) ? next : null;
  }

  /// Whole days remaining before the name can be changed again.
  int get daysUntilNameChange {
    final next = nameChangeAvailableOn;
    if (next == null) return 0;
    return next.difference(DateTime.now()).inDays + 1;
  }

  User copyWith({
    String? fullName,
    String? phoneNumber,
    String? zone,
    String? photoUrl,
    DateTime? nameLastChangedAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      zone: zone ?? this.zone,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      nameLastChangedAt: nameLastChangedAt ?? this.nameLastChangedAt,
    );
  }

  /// Firestore returns Timestamp objects, not ISO strings. The original code
  /// called DateTime.parse() on whatever came back, which threw whenever a
  /// field had been written with FieldValue.serverTimestamp().
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      // Firestore Timestamp - avoid importing cloud_firestore in the model.
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      zone: json['zone'] ?? '',
      role: json['role'] ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      photoUrl: json['photoUrl'],
      nameLastChangedAt: _parseDate(json['nameLastChangedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'zone': zone,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'photoUrl': photoUrl,
      'nameLastChangedAt': nameLastChangedAt?.toIso8601String(),
    };
  }
}
