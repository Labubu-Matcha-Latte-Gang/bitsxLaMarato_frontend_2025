import '../../../models/patient_models.dart';
import '../../../services/api_service.dart';
import '../../../services/session_manager.dart';

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
  final LoginResponse login;

  const PatientRegistrationSuccess(this.response, this.login);
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
      final response = await ApiService.registerPatient(form.toRequest());

      try {
        final loginResponse = await ApiService.loginUser(
          LoginRequest(
            email: form.email.trim(),
            password: form.password,
          ),
        );

        final tokenSaved =
            await SessionManager.saveToken(loginResponse.accessToken);
        if (!tokenSaved) {
          return const PatientRegistrationFailure(
            'El registre s\'ha completat però no s\'ha pogut guardar la sessió localment.',
          );
        }

        if (loginResponse.user != null) {
          await SessionManager.saveUserData({
            'id': loginResponse.user!.id,
            'name': loginResponse.user!.name,
            'surname': loginResponse.user!.surname,
            'email': loginResponse.user!.email,
            'user_type': loginResponse.user!.userType,
          });
        }

        return PatientRegistrationSuccess(response, loginResponse);
      } on ApiException catch (e) {
        final message = e.message.isNotEmpty
            ? 'Registre complet, però error iniciant sessió: ${e.message}'
            : 'Registre complet, però no s\'ha pogut iniciar sessió automàticament.';
        return PatientRegistrationFailure(
          message,
          statusCode: e.statusCode,
          cause: e,
        );
      } catch (e) {
        return PatientRegistrationFailure(
          'Registre complet, però no s\'ha pogut iniciar sessió automàticament: ${e.toString()}',
          cause: e,
        );
      }
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
