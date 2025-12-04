import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_models.dart';
import '../models/activity_models.dart';
import '../config.dart';
import 'session_manager.dart';

class ApiService {
  static String get baseUrl => '${Config.apiUrl}/api/v1';

  static Future<PatientRegistrationResponse> registerPatient(
    PatientRegistrationRequest request,
  ) async {
    try {
      final requestBody = json.encode(request.toJson());
      print('DEBUG - API Request URL: $baseUrl/user/patient');
      print('DEBUG - API Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/user/patient'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('DEBUG - API Response Status: ${response.statusCode}');
      print('DEBUG - API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return PatientRegistrationResponse.fromJson(responseData);
      } else {
        // Manejo de errores específicos
        String errorMessage;

        switch (response.statusCode) {
          case 400:
            errorMessage =
                'Falta un camp obligatori o el correu ja està registrat.';
            break;
          case 404:
            errorMessage = 'No s\'ha trobat cap correu de metge indicat.';
            break;
          case 422:
            errorMessage =
                'Error de validació: El cos de la sol·licitud no ha superat la validació.';
            break;
          case 500:
            errorMessage = 'Error inesperat del servidor en crear el pacient.';
            break;
          default:
            errorMessage = 'Error desconegut en registrar el pacient.';
        }

        // Intentar parsear el error del servidor
        try {
          final errorData = json.decode(response.body);
          print('DEBUG - Error Data: $errorData');

          // Para 422, intentar mostrar los errores específicos de validación
          if (response.statusCode == 422 && errorData.containsKey('errors')) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorDetails =
                errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
            errorMessage = 'Errors de validació:\n$errorDetails';
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }

          throw ApiException(errorMessage, response.statusCode);
        } catch (e) {
          print('DEBUG - Error parsing server response: $e');
          if (e is ApiException) rethrow;
          throw ApiException(
              '$errorMessage\nDetalls: ${response.body}', response.statusCode);
        }
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<DoctorRegistrationResponse> registerDoctor(
    DoctorRegistrationRequest request,
  ) async {
    try {
      final requestBody = json.encode(request.toJson());
      print('DEBUG - Doctor API Request URL: $baseUrl/user/doctor');
      print('DEBUG - Doctor API Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/user/doctor'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('DEBUG - Doctor API Response Status: ${response.statusCode}');
      print('DEBUG - Doctor API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return DoctorRegistrationResponse.fromJson(responseData);
      } else {
        // Manejo de errores específicos
        String errorMessage;

        switch (response.statusCode) {
          case 400:
            errorMessage =
                'Falta un camp obligatori o el correu ja està registrat.';
            break;
          case 404:
            errorMessage = 'No s\'ha trobat cap correu de pacient indicat.';
            break;
          case 422:
            errorMessage =
                'Error de validació: El cos de la sol·licitud no ha superat la validació.';
            break;
          case 500:
            errorMessage = 'Error inesperat del servidor en crear el metge.';
            break;
          default:
            errorMessage = 'Error desconegut en registrar el metge.';
        }

        // Intentar parsear el error del servidor
        try {
          final errorData = json.decode(response.body);
          print('DEBUG - Doctor Error Data: $errorData');

          // Para 422, intentar mostrar los errores específicos de validación
          if (response.statusCode == 422 && errorData.containsKey('errors')) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorDetails =
                errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
            errorMessage = 'Errors de validació:\n$errorDetails';
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }

          throw ApiException(errorMessage, response.statusCode);
        } catch (e) {
          print('DEBUG - Error parsing doctor server response: $e');
          if (e is ApiException) rethrow;
          throw ApiException(
              '$errorMessage\nDetalls: ${response.body}', response.statusCode);
        }
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<LoginResponse> loginUser(LoginRequest request) async {
    try {
      final requestBody = json.encode(request.toJson());
      print('DEBUG - Login Request URL: $baseUrl/user/login');
      print('DEBUG - Login Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('DEBUG - Login Response Status: ${response.statusCode}');
      print('DEBUG - Login Response Body: ${response.body}');
      print('DEBUG - Login Response Body Length: ${response.body.length}');
      print('DEBUG - Login Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Verificar si el body no está vacío
        if (response.body.isEmpty) {
          throw ApiException('La resposta de la API està buida', 200);
        }

        try {
          final responseData = json.decode(response.body);
          print('DEBUG - Parsed Response Data: $responseData');

          // Verificar que responseData no sea null
          if (responseData == null) {
            throw ApiException('La resposta de la API és null', 200);
          }

          return LoginResponse.fromJson(responseData);
        } catch (e) {
          print('DEBUG - Error parsing JSON: $e');
          throw ApiException(
              'Error processant la resposta: ${e.toString()}', 200);
        }
      } else {
        // Manejo de errores específicos
        String errorMessage;

        switch (response.statusCode) {
          case 400:
            errorMessage = 'Falten credencials o són incorrectes.';
            break;
          case 401:
            errorMessage = 'Credencials incorrectes.';
            break;
          case 404:
            errorMessage = 'Usuari no trobat.';
            break;
          case 422:
            try {
              final errorData = json.decode(response.body);
              if (errorData['errors'] != null) {
                List<String> validationErrors = [];
                errorData['errors'].forEach((field, messages) {
                  if (messages is List) {
                    validationErrors.addAll(messages.cast<String>());
                  }
                });
                errorMessage =
                    'Errors de validació:\n${validationErrors.join('\n')}';
              } else {
                errorMessage =
                    'Error de validació: El cos de la sol·licitud no ha superat la validació.';
              }
            } catch (e) {
              errorMessage =
                  'Error de validació: El cos de la sol·licitud no ha superat la validació.';
            }
            break;
          case 500:
            errorMessage = 'Error inesperat del servidor en iniciar sessió.';
            break;
          default:
            errorMessage =
                'Error desconegut (${response.statusCode}): ${response.body}';
        }

        print('DEBUG - Login API Error: $errorMessage');
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      print('DEBUG - Login Exception: $e');
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
