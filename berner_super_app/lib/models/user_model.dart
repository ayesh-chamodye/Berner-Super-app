enum UserRole {
  employee,
  customer,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.employee:
        return 'Employee';
      case UserRole.customer:
        return 'Customer';
    }
  }

  String get value {
    switch (this) {
      case UserRole.employee:
        return 'employee';
      case UserRole.customer:
        return 'customer';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'employee':
        return UserRole.employee;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }
}

class UserModel {
  final String id;
  final String mobileNumber;
  final String? name;
  final String? nic;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profilePicturePath;
  final String? admCode; // Optional for customers
  final UserRole role;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.mobileNumber,
    this.name,
    this.nic,
    this.dateOfBirth,
    this.gender,
    this.profilePicturePath,
    this.admCode,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      mobileNumber: json['mobileNumber'],
      name: json['name'],
      nic: json['nic'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      profilePicturePath: json['profilePicturePath'],
      admCode: json['admCode'],
      role: UserRoleExtension.fromString(json['role'] ?? 'customer'),
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobileNumber': mobileNumber,
      'name': name,
      'nic': nic,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'profilePicturePath': profilePicturePath,
      'admCode': admCode,
      'role': role.value,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? mobileNumber,
    String? name,
    String? nic,
    DateTime? dateOfBirth,
    String? gender,
    String? profilePicturePath,
    String? admCode,
    UserRole? role,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      name: name ?? this.name,
      nic: nic ?? this.nic,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      admCode: admCode ?? this.admCode,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isProfileComplete {
    return name != null &&
           nic != null &&
           dateOfBirth != null &&
           gender != null;
  }
}