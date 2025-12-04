import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_models.dart';
import '../models/activity_models.dart';
import '../models/question_models.dart';
import '../config.dart';
import 'session_manager.dart';

class ApiService {
  static String get baseUrl => '${Config.apiUrl}/api/v1';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Sessió no trobada o caducada. Torna a iniciar sessió.',
        401,
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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

  static Future<List<Activity>> listActivities({
    ActivityQueryParams? query,
  }) async {
    try {
      final headers = await _authHeaders();
      Uri uri = Uri.parse('$baseUrl/activity');
      final params = query?.toQueryParameters() ?? {};
      if (params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .map((activity) => Activity.fromJson(activity))
            .toList();
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'han pogut recuperar les activitats.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<Activity> getRecommendedActivity() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/activity/recommended'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Activity.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut recuperar l\'activitat recomanada.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<ActivityCompleteResponse> completeActivity(
    ActivityCompleteRequest request,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/activity/complete'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ActivityCompleteResponse.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut marcar l\'activitat com a completada.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<Question> getDailyQuestion() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/question/daily'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Question.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut recuperar la pregunta diària.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
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

  static ApiException _apiExceptionFromResponse(
    http.Response response,
    String fallbackMessage,
  ) {
    String message = fallbackMessage;

    switch (response.statusCode) {
      case 401:
        message = 'Falta o és invàlid el token de sessió.';
        break;
      case 403:
        message = 'No tens permisos per accedir a aquest recurs.';
        break;
      case 404:
        message = 'Recurs no trobat.';
        break;
      case 422:
        message = 'El cos de la sol·licitud no ha superat la validació.';
        break;
      case 500:
        message = 'Error inesperat del servidor.';
        break;
      default:
        message = fallbackMessage;
    }

    try {
      if (response.body.isNotEmpty) {
        final errorData = json.decode(response.body);
        if (errorData is Map<String, dynamic>) {
          if (response.statusCode == 422 &&
              errorData['errors'] is Map<String, dynamic>) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorDetails =
                errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
            message = 'Errors de validació:\n$errorDetails';
          } else if (errorData['message'] is String &&
              (errorData['message'] as String).isNotEmpty) {
            message = errorData['message'];
          }
        }
      }
    } catch (_) {}

    return ApiException(message, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
