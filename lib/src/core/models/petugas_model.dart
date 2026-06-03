// ─── User Role Enum ───────────────────────────────────────────────────────────

enum UserRole {
  officer,
  superadmin;

  String get label {
    switch (this) {
      case UserRole.officer:
        return 'Petugas';
      case UserRole.superadmin:
        return 'Superadmin';
    }
  }

  static UserRole fromString(String? value) {
    switch (value) {
      case 'superadmin':
        return UserRole.superadmin;
      default:
        return UserRole.officer;
    }
  }
}

// ─── Petugas Model ────────────────────────────────────────────────────────────

/// Mirrors the backend `UserRead` schema, extended with a computed
/// [customerCount] field populated from the customers endpoint.
class PetugasModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? address;
  final UserRole role;
  final int customerCount;

  const PetugasModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.address,
    this.role = UserRole.officer,
    this.customerCount = 0,
  });

  factory PetugasModel.fromJson(Map<String, dynamic> json) => PetugasModel(
        id: json['id'] as int,
        name: json['name'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        role: UserRole.fromString(json['role'] as String?),
      );

  PetugasModel copyWith({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? address,
    UserRole? role,
    int? customerCount,
  }) {
    return PetugasModel(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      customerCount: customerCount ?? this.customerCount,
    );
  }
}

// ─── Petugas Create Request ───────────────────────────────────────────────────

/// Maps to the backend `UserCreate` schema.
class PetugasCreateRequest {
  final String name;
  final String username;
  final String email;
  final String password;
  final String? phone;
  final String? address;
  final UserRole role;

  const PetugasCreateRequest({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    this.phone,
    this.address,
    this.role = UserRole.officer,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'role': role.name,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
      };
}

// ─── Petugas Update Request ───────────────────────────────────────────────────

/// Maps to the backend `UserUpdate` schema. All fields are optional.
class PetugasUpdateRequest {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final UserRole? role;

  const PetugasUpdateRequest({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.role,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (role != null) 'role': role!.name,
      };
}
