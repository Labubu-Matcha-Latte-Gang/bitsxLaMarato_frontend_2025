import '../../../models/patient_models.dart';
import '../../../services/api_service.dart';

class PatientRegistrationFormData {
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

  const PatientRegistrationFormData({
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
    this.doctors = const [],
  });

  PatientRegistrationRequest toRequest() {
    return PatientRegistrationRequest(
      name: name.trim(),
      surname: surname.trim(),
      email: email.trim(),
      password: password,
      ailments: ailments.trim(),
      gender: gender.trim(),
      age: age,
      treatments: treatments.trim(),
      heightCm: heightCm,
      weightKg: weightKg,
      doctors: doctors,
    );
  }
}

sealed class PatientRegistrationResult {
  const PatientRegistrationResult();
}

class PatientRegistrationSuccess extends PatientRegistrationResult {
  final PatientRegistrationResponse response;

  const PatientRegistrationSuccess(this.response);
}

class PatientRegistrationFailure extends PatientRegistrationResult {
  final String message;
  final int? statusCode;
  final Object? cause;

  const PatientRegistrationFailure(
    this.message, {
    this.statusCode,
    this.cause,
  });
}

class PatientRegistrationService {
  const PatientRegistrationService();

  Future<PatientRegistrationResult> register(
    PatientRegistrationFormData form,
  ) async {
    try {
      final response = await ApiService.instance.registerPatient(form.toRequest());

      return PatientRegistrationSuccess(response);
    } on ApiException catch (e) {
      final message = e.message.isNotEmpty
          ? e.message
          : 'No s\'ha pogut registrar el pacient. Torna-ho a provar.';
      return PatientRegistrationFailure(
        message,
        statusCode: e.statusCode,
        cause: e,
      );
    } catch (e) {
      return const PatientRegistrationFailure(
        'S\'ha produït un error inesperat en registrar el pacient. Torna-ho a provar més tard.',
      );
    }
  }
}
