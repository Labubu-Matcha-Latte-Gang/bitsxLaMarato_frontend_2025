class PatientRegistrationRequest {
  final String name;
  final String surname;
  final String email;
  final String password;
  final String ailments;
  final String gender;
  final int age;
  final String treatments;
  final double heightCm;
  final double weightKg;
  final List<String> doctors;

  PatientRegistrationRequest({
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.ailments,
    required this.gender,
    required this.age,
    required this.treatments,
    required this.heightCm,
    required this.weightKg,
    required this.doctors,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'ailments': ailments,
      'gender': gender,
      'age': age,
      'treatments': treatments,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'doctors': doctors,
    };
  }
}

class PatientRegistrationResponse {
  final String email;
  final String name;
  final String surname;
  final PatientRole role;

  PatientRegistrationResponse({
    required this.email,
    required this.name,
    required this.surname,
    required this.role,
  });

  factory PatientRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return PatientRegistrationResponse(
      email: json['email'],
      name: json['name'],
      surname: json['surname'],
      role: PatientRole.fromJson(json['role']),
    );
  }
}

class PatientRole {
  final String ailments;
  final String gender;
  final int age;
  final String treatments;
  final double heightCm;
  final double weightKg;
  final List<String> doctors;

  PatientRole({
    required this.ailments,
    required this.gender,
    required this.age,
    required this.treatments,
    required this.heightCm,
    required this.weightKg,
    required this.doctors,
  });

  factory PatientRole.fromJson(Map<String, dynamic> json) {
    return PatientRole(
      ailments: json['ailments'],
      gender: json['gender'],
      age: json['age'],
      treatments: json['treatments'],
      heightCm: json['height_cm'].toDouble(),
      weightKg: json['weight_kg'].toDouble(),
      doctors: List<String>.from(json['doctors']),
    );
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
