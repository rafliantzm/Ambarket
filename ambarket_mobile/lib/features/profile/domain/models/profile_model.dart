class ProfileModel {
  final String id;
  final String? name;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final String? username;
  final String? phone;
  final String? location;
  final String? address;
  final String? bio;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    this.name,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.username,
    this.phone,
    this.location,
    this.address,
    this.bio,
    this.isSuspended = false,
    this.suspensionReason,
    this.suspendedAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: _stringValue(json['id'], fallback: 'unknown-user'),
      name: _nullableString(json['name']),
      avatarUrl: _nullableString(json['avatar_url']),
      role: _stringValue(json['role'], fallback: 'user'),
      createdAt: _dateValue(json['created_at']),
      username: _nullableString(json['username']),
      phone: _nullableString(json['phone']),
      location: _nullableString(json['location']),
      address: _nullableString(json['address']),
      bio: _nullableString(json['bio']),
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspensionReason: _nullableString(json['suspension_reason']),
      suspendedAt: _nullableDate(json['suspended_at']),
      updatedAt: _nullableDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'username': username,
      'phone': phone,
      'location': location,
      'address': address,
      'bio': bio,
      'is_suspended': isSuspended,
      if (suspensionReason != null) 'suspension_reason': suspensionReason,
      if (suspendedAt != null) 'suspended_at': suspendedAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? role,
    DateTime? createdAt,
    String? username,
    String? phone,
    String? location,
    String? address,
    String? bio,
    bool? isSuspended,
    String? suspensionReason,
    DateTime? suspendedAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

DateTime _dateValue(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
