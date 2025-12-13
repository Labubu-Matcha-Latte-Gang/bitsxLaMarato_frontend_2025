import 'user_models.dart';

class PatientRegistrationRequest {
  final String name;
  final String surname;
  final String email;
  final String password;
  final String? ailments;
  final String gender;
  final int age;
  final String? treatments;
  final double heightCm;
  final double weightKg;
  final List<String> doctors;

  PatientRegistrationRequest({
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    this.ailments,
    required this.gender,
    required this.age,
    this.treatments,
    required this.heightCm,
    required this.weightKg,
    this.doctors = const [],
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'gender': gender,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
    };
    if (ailments != null && ailments!.isNotEmpty) {
      data['ailments'] = ailments;
    }
    if (treatments != null && treatments!.isNotEmpty) {
      data['treatments'] = treatments;
    }
    if (doctors.isNotEmpty) {
      data['doctors'] = doctors;
    }
    return data;
  }
}

class PatientRegistrationResponse {
  final String email;
  final String name;
  final String surname;
  final String accessToken;
  final UserRoleData role;

  PatientRegistrationResponse({
    required this.email,
    required this.name,
    required this.surname,
    required this.accessToken,
    required this.role,
  });

  factory PatientRegistrationResponse.fromJson(Map<String, dynamic> json) {
    final token = json['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception(
        'access_token is missing from patient registration response',
      );
    }

    return PatientRegistrationResponse(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      accessToken: token,
      role: UserRoleData.fromJson(json['role'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toUserData() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'user_type': 'patient',
      'role': role.raw,
    };
  }
}

class ApiError {
  final int code;
  final String status;
  final String message;
  final Map<String, dynamic>? errors;

  ApiError({
    required this.code,
    required this.status,
    required this.message,
    this.errors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'],
      status: json['status'],
      message: json['message'],
      errors: json['errors'],
    );
  }
}

// --- DOCTOR MODELS ---

class DoctorRegistrationRequest {
  final String name;
  final String surname;
  final String email;
  final String password;
  final String gender;
  final List<String> patients;

  DoctorRegistrationRequest({
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.gender,
    this.patients = const [],
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'gender': gender,
    };
    if (patients.isNotEmpty) {
      data['patients'] = patients;
    }
    return data;
  }
}

class DoctorRegistrationResponse {
  final String email;
  final String name;
  final String surname;
  final String accessToken;
  final UserRoleData role;

  DoctorRegistrationResponse({
    required this.email,
    required this.name,
    required this.surname,
    required this.accessToken,
    required this.role,
  });

  factory DoctorRegistrationResponse.fromJson(Map<String, dynamic> json) {
    final token = json['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('access_token is missing from doctor registration response');
    }

    return DoctorRegistrationResponse(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      accessToken: token,
      role: UserRoleData.fromJson(json['role'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toUserData() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'user_type': 'doctor',
      'role': role.raw,
    };
  }
}

// Models for Login
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final bool alreadyRespondedToday;

  LoginResponse({
    required this.accessToken,
    required this.alreadyRespondedToday,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final access = json['access_token']?.toString();
    if (access == null || access.isEmpty) {
      throw Exception('access_token is missing from login response');
    }

    return LoginResponse(
      accessToken: access,
      alreadyRespondedToday: json['already_responded_today'] == true,
    );
  }

  Map<String, dynamic> toUserData() {
    return {
      'user_type': 'unknown',
      'already_responded_today': alreadyRespondedToday,
    };
  }
}
