/// DTOs mapping exactly to the Laravel Auth/Bootstrap/Device API contract.
/// These isolate remote JSON payloads from Drift schema and domain entities.

// ── Login ───────────────────────────────────────────────────

class LoginRequestDto {
  final String email;
  final String password;
  final String? deviceName;

  const LoginRequestDto({
    required this.email,
    required this.password,
    this.deviceName,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    if (deviceName != null) 'device_name': deviceName,
  };
}

class LoginResponseDto {
  final String message;
  final String token;
  final UserDto user;

  const LoginResponseDto({
    required this.message,
    required this.token,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      message: json['message'] as String? ?? '',
      token: json['token'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

// ── User ────────────────────────────────────────────────────

class UserDto {
  final String id;
  final String fullName;
  final String email;
  final String? username;
  final bool isActive;

  const UserDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.username,
    required this.isActive,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

// ── Session Bootstrap ───────────────────────────────────────

class BootstrapRequestDto {
  final String? businessId;
  final String? branchId;
  final String? deviceUuid;

  const BootstrapRequestDto({this.businessId, this.branchId, this.deviceUuid});

  Map<String, dynamic> toQueryParams() => {
    if (businessId != null) 'business_id': businessId,
    if (branchId != null) 'branch_id': branchId,
    if (deviceUuid != null) 'device_uuid': deviceUuid,
  };
}

class BootstrapResponseDto {
  final UserDto user;
  final BusinessDto activeBusiness;
  final List<BusinessDto> availableBusinesses;
  final BranchDto? activeBranch;
  final List<BranchDto> allowedBranches;
  final List<String> roles;
  final List<String> permissions;
  final SubscriptionDto? subscription;
  final DeviceDto? device;

  const BootstrapResponseDto({
    required this.user,
    required this.activeBusiness,
    required this.availableBusinesses,
    this.activeBranch,
    required this.allowedBranches,
    required this.roles,
    required this.permissions,
    this.subscription,
    this.device,
  });

  factory BootstrapResponseDto.fromJson(Map<String, dynamic> json) {
    return BootstrapResponseDto(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      activeBusiness: BusinessDto.fromJson(
        json['active_business'] as Map<String, dynamic>,
      ),
      availableBusinesses:
          (json['available_businesses'] as List<dynamic>? ?? [])
              .map((e) => BusinessDto.fromJson(e as Map<String, dynamic>))
              .toList(),
      activeBranch: json['active_branch'] != null
          ? BranchDto.fromJson(json['active_branch'] as Map<String, dynamic>)
          : null,
      allowedBranches: (json['allowed_branches'] as List<dynamic>? ?? [])
          .map((e) => BranchDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      subscription: json['subscription'] != null
          ? SubscriptionDto.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : null,
      device: json['device'] != null
          ? DeviceDto.fromJson(json['device'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Business ────────────────────────────────────────────────

class BusinessDto {
  final String id;
  final String businessName;
  final String? businessType;
  final String? status;

  const BusinessDto({
    required this.id,
    required this.businessName,
    this.businessType,
    this.status,
  });

  factory BusinessDto.fromJson(Map<String, dynamic> json) {
    return BusinessDto(
      id: json['id'].toString(),
      businessName: json['business_name'] as String? ?? '',
      businessType: json['business_type'] as String?,
      status: json['status'] as String?,
    );
  }
}

// ── Branch ──────────────────────────────────────────────────

class BranchDto {
  final String id;
  final String branchName;
  final String? branchCode;
  final bool isActive;

  const BranchDto({
    required this.id,
    required this.branchName,
    this.branchCode,
    required this.isActive,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    return BranchDto(
      id: json['id'].toString(),
      branchName: json['branch_name'] as String? ?? '',
      branchCode: json['branch_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

// ── Subscription ────────────────────────────────────────────

class SubscriptionDto {
  final String id;
  final String status;
  final String? plan;
  final String? endsAt;

  const SubscriptionDto({
    required this.id,
    required this.status,
    this.plan,
    this.endsAt,
  });

  factory SubscriptionDto.fromJson(Map<String, dynamic> json) {
    return SubscriptionDto(
      id: json['id'].toString(),
      status: json['status'] as String? ?? 'Unknown',
      plan: json['plan'] as String?,
      endsAt: json['ends_at'] as String?,
    );
  }
}

// ── Device ──────────────────────────────────────────────────

class DeviceDto {
  final String id;
  final String deviceUuid;
  final String? deviceName;
  final String? platform;
  final String status; // 'active' | 'revoked'

  const DeviceDto({
    required this.id,
    required this.deviceUuid,
    this.deviceName,
    this.platform,
    required this.status,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    return DeviceDto(
      id: json['id'].toString(),
      deviceUuid: json['device_uuid'] as String? ?? '',
      deviceName: json['device_name'] as String?,
      platform: json['platform'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  bool get isRevoked => status == 'revoked';
}

// ── Device Registration ─────────────────────────────────────

class RegisterDeviceRequestDto {
  final String businessId;
  final String deviceUuid;
  final String? deviceName;
  final String? platform;
  final String? appVersion;

  const RegisterDeviceRequestDto({
    required this.businessId,
    required this.deviceUuid,
    this.deviceName,
    this.platform,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'device_uuid': deviceUuid,
    if (deviceName != null) 'device_name': deviceName,
    if (platform != null) 'platform': platform,
    if (appVersion != null) 'app_version': appVersion,
  };
}

class RegisterDeviceResponseDto {
  final String message;
  final DeviceDto device;

  const RegisterDeviceResponseDto({
    required this.message,
    required this.device,
  });

  factory RegisterDeviceResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceResponseDto(
      message: json['message'] as String? ?? '',
      device: DeviceDto.fromJson(json['device'] as Map<String, dynamic>),
    );
  }
}

// -- Registration --------------------------------------------

class RegisterRequestDto {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final String password;
  final String? deviceName;

  const RegisterRequestDto({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    this.deviceName,
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'username': username,
    'email': email,
    'phone': phone,
    'password': password,
    if (deviceName != null) 'device_name': deviceName,
  };
}

class RegisterResponseDto {
  final String message;
  final String token;
  final UserDto user;

  const RegisterResponseDto({
    required this.message,
    required this.token,
    required this.user,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      message: json['message'] as String? ?? '',
      token: json['token'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
