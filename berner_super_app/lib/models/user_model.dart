enum UserRole {
  employee,
  owner,
  admin,
  customer,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.employee:
        return 'Employee';
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.customer:
        return 'Customer';
    }
  }

  String get value {
    switch (this) {
      case UserRole.employee:
        return 'employee';
      case UserRole.owner:
        return 'owner';
      case UserRole.admin:
        return 'admin';
      case UserRole.customer:
        return 'customer';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'employee':
        return UserRole.employee;
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }
}

class UserModel {
  // From users table
  final String id;
  final String mobileNumber;
  final String? admCode; // Auto-generated for employees
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // From user_profiles table
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? email;
  final String? nic;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profilePictureUrl;

  // Additional profile fields
  final String? department;
  final String? position;
  final String? businessName;

  UserModel({
    required this.id,
    required this.mobileNumber,
    this.admCode,
    required this.role,
    this.isVerified = false,
    this.isActive = true,
    this.isBlocked = false,
    required this.createdAt,
    this.lastLoginAt,
    this.firstName,
    this.lastName,
    this.fullName,
    this.email,
    this.nic,
    this.dateOfBirth,
    this.gender,
    this.profilePictureUrl,
    this.department,
    this.position,
    this.businessName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      mobileNumber: json['mobile_number'] ?? json['mobileNumber'] ?? '',
      admCode: json['adm_code'] ?? json['admCode'],
      role: UserRoleExtension.fromString(json['role'] ?? 'customer'),
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isBlocked: json['is_blocked'] ?? json['isBlocked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : (json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null),
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      fullName: json['full_name'] ?? json['fullName'] ?? json['name'],
      email: json['email'],
      nic: json['nic'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : (json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null),
      gender: json['gender'],
      profilePictureUrl: json['profile_picture_url'] ?? json['profilePictureUrl'] ?? json['profilePicturePath'],
      department: json['department'],
      position: json['position'],
      businessName: json['business_name'] ?? json['businessName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile_number': mobileNumber,
      'adm_code': admCode,
      'role': role.value,
      'is_verified': isVerified,
      'is_active': isActive,
      'is_blocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'nic': nic,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'profile_picture_url': profilePictureUrl,
      'department': department,
      'position': position,
      'business_name': businessName,
    };
  }

  // Legacy compatibility
  String? get name => fullName ?? (firstName != null && lastName != null ? '$firstName $lastName' : firstName);
  String? get profilePicturePath => profilePictureUrl;

  UserModel copyWith({
    String? id,
    String? mobileNumber,
    String? admCode,
    UserRole? role,
    bool? isVerified,
    bool? isActive,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? nic,
    DateTime? dateOfBirth,
    String? gender,
    String? profilePictureUrl,
    String? department,
    String? position,
    String? businessName,
  }) {
    return UserModel(
      id: id ?? this.id,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      admCode: admCode ?? this.admCode,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      nic: nic ?? this.nic,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      department: department ?? this.department,
      position: position ?? this.position,
      businessName: businessName ?? this.businessName,
    );
  }

  bool get isProfileComplete {
    return fullName != null &&
           nic != null &&
           dateOfBirth != null &&
           gender != null;
  }
}