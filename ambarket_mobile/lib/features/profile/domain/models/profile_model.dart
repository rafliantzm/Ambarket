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
      id: json['id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      bio: json['bio'] as String?,
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspensionReason: json['suspension_reason'] as String?,
      suspendedAt: json['suspended_at'] != null
          ? DateTime.parse(json['suspended_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
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
