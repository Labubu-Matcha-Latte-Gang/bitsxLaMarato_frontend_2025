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
  final String accessToken;
  final String? refreshToken;
  final User? user;
  final PatientRole role;

  PatientRegistrationResponse({
    required this.email,
    required this.name,
    required this.surname,
    required this.accessToken,
    this.refreshToken,
    this.user,
    required this.role,
  });

  factory PatientRegistrationResponse.fromJson(Map<String, dynamic> json) {
    final token = json['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception(
        'access_token is missing from patient registration response',
      );
    }

    User? user;
    if (json['user'] is Map<String, dynamic>) {
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    }

    return PatientRegistrationResponse(
      email: json['email'],
      name: json['name'],
      surname: json['surname'],
      accessToken: token,
      refreshToken: json['refresh_token']?.toString(),
      user: user,
      role: PatientRole.fromJson(json['role']),
    );
  }

  Map<String, dynamic> toUserData() {
    final userType = user?.userType ?? '';
    return {
      'id': user?.id ?? '',
      'name': user?.name ?? name,
      'surname': user?.surname ?? surname,
      'email': user?.email ?? email,
      'user_type': userType.isNotEmpty ? userType : 'patient',
    };
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

// --- DOCTOR MODELS ---

class DoctorRegistrationRequest {
  final String name;
  final String surname;
  final String email;
  final String password;
  final List<String> patients;

  DoctorRegistrationRequest({
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.patients,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'patients': patients,
    };
  }
}

class DoctorRegistrationResponse {
  final String email;
  final String name;
  final String surname;
  final String accessToken;
  final String? refreshToken;
  final User? user;
  final DoctorRole role;

  DoctorRegistrationResponse({
    required this.email,
    required this.name,
    required this.surname,
    required this.accessToken,
    this.refreshToken,
    this.user,
    required this.role,
  });

  factory DoctorRegistrationResponse.fromJson(Map<String, dynamic> json) {
    final token = json['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('access_token is missing from doctor registration response');
    }

    User? user;
    if (json['user'] is Map<String, dynamic>) {
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    }

    return DoctorRegistrationResponse(
      email: json['email'],
      name: json['name'],
      surname: json['surname'],
      accessToken: token,
      refreshToken: json['refresh_token']?.toString(),
      user: user,
      role: DoctorRole.fromJson(json['role']),
    );
  }

  Map<String, dynamic> toUserData() {
    final userType = user?.userType ?? '';
    return {
      'id': user?.id ?? '',
      'name': user?.name ?? name,
      'surname': user?.surname ?? surname,
      'email': user?.email ?? email,
      'user_type': userType.isNotEmpty ? userType : 'doctor',
    };
  }
}

class DoctorRole {
  final List<String> patients;

  DoctorRole({
    required this.patients,
  });

  factory DoctorRole.fromJson(Map<String, dynamic> json) {
    return DoctorRole(
      patients: List<String>.from(json['patients']),
    );
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
  final String? refreshToken;
  final User? user;

  LoginResponse({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('DEBUG - LoginResponse.fromJson received: $json');

    if (json['access_token'] == null) {
      throw Exception('access_token is missing from login response');
    }

    // Si no hay user en la respuesta, creamos uno básico
    User? user;
    if (json['user'] != null) {
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    } else {
      // Crear usuario básico si no viene en la respuesta
      user = User(
        id: '',
        name: 'Usuario',
        surname: '',
        email: '',
        userType: 'unknown',
      );
    }

    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token']?.toString(),
      user: user,
    );
  }

  Map<String, dynamic> toUserData() {
    return {
      'id': user?.id ?? '',
      'name': user?.name ?? 'Usuari',
      'surname': user?.surname ?? '',
      'email': user?.email ?? '',
      'user_type': user?.userType ?? 'unknown',
    };
  }
}

class User {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String userType;

  User({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('DEBUG - User.fromJson received: $json');

    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? '',
    );
  }
}
