import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/patient_models.dart';
import '../models/activity_models.dart';
import '../models/question_models.dart';
import '../models/user_models.dart';
import '../models/transcription_models.dart';
import '../config.dart';
import 'session_manager.dart';

typedef _AuthorizedRequest = Future<http.Response> Function(
  String token,
  http.Client client,
);

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late http.Client _client;
  String? _baseUrlOverride;

  ApiService._internal() {
    _client = http.Client();
  }

  factory ApiService() {
    return _instance;
  }

  static http.Client get _sharedClient => _instance._client;
  static String get _baseUrl =>
      '${_instance._baseUrlOverride ?? Config.apiUrl}/api/v1';

  static void configure({
    http.Client? client,
    String? baseUrl,
  }) {
    if (client != null) {
      _instance._client = client;
    }
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _instance._baseUrlOverride = baseUrl;
    }
  }

  static void reset({bool closeExistingClient = false}) {
    if (closeExistingClient) {
      try {
        _instance._client.close();
      } catch (_) {}
    }
    _instance._client = http.Client();
    _instance._baseUrlOverride = null;
  }

  static Future<bool> restoreSession() async {
    final storedToken = await SessionManager.getToken();
    if (storedToken == null || storedToken.isEmpty) {
      return false;
    }

    try {
      await _refreshAccessToken();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<PatientRegistrationResponse> registerPatient(
    PatientRegistrationRequest request,
  ) async {
    try {
      final requestBody = json.encode(request.toJson());
      print('DEBUG - API Request URL: $_baseUrl/user/patient');
      print('DEBUG - API Request Body: $requestBody');

      final response = await _sharedClient.post(
        Uri.parse('$_baseUrl/user/patient'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('DEBUG - API Response Status: ${response.statusCode}');
      print('DEBUG - API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final registration = PatientRegistrationResponse.fromJson(responseData);
        await _persistSession(
          accessToken: registration.accessToken,
          refreshToken: null,
          userData: registration.toUserData(),
        );
        await _persistUserProfile(
          UserProfile(
            email: registration.email,
            name: registration.name,
            surname: registration.surname,
            role: registration.role,
          ),
          alreadyRespondedToday: false,
        );
        return registration;
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

  static Future<PatientSearchResult> searchPatientsForDoctor(
    String query, {
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/doctor/patients/search').replace(
        queryParameters: {
          'q': query,
          'limit': limit.toString(),
        },
      );

      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          uri,
          headers: _jsonHeaders(token),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return PatientSearchResult.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'han pogut cercar els pacients.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<UserProfile> assignPatientsToDoctor(
    List<String> patients,
  ) {
    return _mutateDoctorPatients(
      endpoint: 'assign',
      patients: patients,
      failureMessage: 'No s\'han pogut afegir els pacients al teu llistat.',
    );
  }

  static Future<UserProfile> unassignPatientsFromDoctor(
    List<String> patients,
  ) {
    return _mutateDoctorPatients(
      endpoint: 'unassign',
      patients: patients,
      failureMessage: 'No s\'han pogut eliminar els pacients seleccionats.',
    );
  }

  static Future<UserProfile> _mutateDoctorPatients({
    required String endpoint,
    required List<String> patients,
    required String failureMessage,
  }) async {
    if (patients.isEmpty) {
      throw ApiException('Cal indicar almenys un pacient.', 400);
    }

    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.post(
          Uri.parse('$_baseUrl/user/doctor/patients/$endpoint'),
          headers: _jsonHeaders(token),
          body: json.encode({'patients': patients}),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final profile = UserProfile.fromJson(responseData);
        await _persistUserProfile(profile);
        return profile;
      }

      throw _apiExceptionFromResponse(response, failureMessage);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<Uint8List> downloadPatientReport(
    String email, {
    String timezone = 'Europe/Madrid',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/report/$email').replace(
        queryParameters: {'timezone': timezone},
      );

      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          uri,
          headers: _jsonHeaders(
            token,
            extra: {'Accept': 'application/pdf'},
          ),
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.bodyBytes);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut descarregar l\'informe del pacient.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
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
      Uri uri = Uri.parse('$_baseUrl/activity');
      final params = query?.toQueryParameters() ?? {};

      // Add a dummy parameter when no filters are applied to avoid ad-blocker issues
      if (params.isEmpty) {
        params['all'] = 'true';
      }

      uri = uri.replace(queryParameters: params);

      print('DEBUG: Fetching activities from URL: $uri');

      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          uri,
          headers: _jsonHeaders(token),
        ),
      );

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

  static Future<Activity> getActivity(String name) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/activity').replace(queryParameters: {'title': name});

      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          uri,
          headers: _jsonHeaders(token),
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map<String, dynamic>) {
            return Activity.fromJson(first);
          }
        }

        throw ApiException(
          'No s\'ha trobat l\'activitat sol·licitada.',
          404,
        );
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut recuperar l\'activitat sol·licitada.',
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
      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          Uri.parse('$_baseUrl/activity/recommended'),
          headers: _jsonHeaders(token),
        ),
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
      final response = await _sendAuthorizedRequest(
        (token, client) => client.post(
          Uri.parse('$_baseUrl/activity/complete'),
          headers: _jsonHeaders(token),
          body: json.encode(request.toJson()),
        ),
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
      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          Uri.parse('$_baseUrl/question/daily'),
          headers: _jsonHeaders(token),
        ),
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

  static Future<Question> getDiaryQuestion() async {
    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          Uri.parse('$_baseUrl/question/diary'),
          headers: _jsonHeaders(token),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Question.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut recuperar la pregunta del diari.',
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
      print('DEBUG - Doctor API Request URL: $_baseUrl/user/doctor');
      print('DEBUG - Doctor API Request Body: $requestBody');

      final response = await _sharedClient.post(
        Uri.parse('$_baseUrl/user/doctor'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('DEBUG - Doctor API Response Status: ${response.statusCode}');
      print('DEBUG - Doctor API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final registration = DoctorRegistrationResponse.fromJson(responseData);
        await _persistSession(
          accessToken: registration.accessToken,
          refreshToken: null,
          userData: registration.toUserData(),
        );
        await _persistUserProfile(
          UserProfile(
            email: registration.email,
            name: registration.name,
            surname: registration.surname,
            role: registration.role,
          ),
        );
        return registration;
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
      print('DEBUG - Login Request URL: $_baseUrl/user/login');
      print('DEBUG - Login Request Body: $requestBody');

      final response = await _sharedClient.post(
        Uri.parse('$_baseUrl/user/login'),
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
        if (response.body.isEmpty) {
          throw ApiException('La resposta de la API està buida', 200);
        }

        try {
          final responseData = json.decode(response.body);
          print('DEBUG - Parsed Response Data: $responseData');

          final loginResponse = LoginResponse.fromJson(responseData);
          await _persistSession(
            accessToken: loginResponse.accessToken,
            refreshToken: null,
            userData: loginResponse.toUserData(),
          );
          await getAndCacheCurrentUser(
            alreadyRespondedToday: loginResponse.alreadyRespondedToday,
          );
          return loginResponse;
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

  static Future<UserProfile> getCurrentUser() async {
    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          Uri.parse('$_baseUrl/user'),
          headers: _jsonHeaders(token),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return UserProfile.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut obtenir l\'usuari actual.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<UserProfile> getAndCacheCurrentUser({
    bool? alreadyRespondedToday,
  }) async {
    final profile = await getCurrentUser();
    await _persistUserProfile(
      profile,
      alreadyRespondedToday: alreadyRespondedToday,
    );
    return profile;
  }

  static Future<UserProfile> updateCurrentUser(
    UserUpdateRequest request,
  ) async {
    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.put(
          Uri.parse('$_baseUrl/user'),
          headers: _jsonHeaders(token),
          body: json.encode(request.toJson()),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return UserProfile.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut actualitzar l\'usuari.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<UserProfile> patchCurrentUser(
    UserPartialUpdateRequest request,
  ) async {
    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.patch(
          Uri.parse('$_baseUrl/user'),
          headers: _jsonHeaders(token),
          body: json.encode(request.toJson()),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return UserProfile.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut actualitzar parcialment l\'usuari.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<void> deleteCurrentUser() async {
    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.delete(
          Uri.parse('$_baseUrl/user'),
          headers: _jsonHeaders(token),
        ),
      );

      if (response.statusCode == 204) {
        return;
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut eliminar l\'usuari actual.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<PatientDataResponse> getPatientData(String email) async {
    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.get(
          Uri.parse('$_baseUrl/user/$email'),
          headers: _jsonHeaders(token),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return PatientDataResponse.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut recuperar les dades del pacient.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<TranscriptionResponse> uploadTranscriptionChunk(
    TranscriptionChunkRequest request,
  ) async {
    try {
      return await _uploadTranscriptionChunkMultipart(request);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<TranscriptionResponse> _uploadTranscriptionChunkMultipart(
    TranscriptionChunkRequest request,
  ) async {
    try {
      if (request.audioBytes.isEmpty) {
        throw ApiException('Chunk de audio vacío', 400);
      }

      final response = await _sendAuthorizedRequest(
        (token, client) async {
          final multipartRequest = http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/transcription/chunk'),
          );
          multipartRequest.headers['Authorization'] = 'Bearer $token';
          multipartRequest.fields['session_id'] = request.sessionId;
          multipartRequest.fields['chunk_index'] =
              request.chunkIndex.toString();
          multipartRequest.files.add(
            http.MultipartFile.fromBytes(
              'audio_blob',
              request.audioBytes,
              filename: request.filename,
              contentType: MediaType.parse(request.contentType),
            ),
          );

          print(
            'DEBUG - Uploading transcription chunk: session=${request.sessionId} index=${request.chunkIndex} size=${request.audioBytes.length} filename=${request.filename}',
          );

          final streamedResponse = await client.send(multipartRequest);
          return http.Response.fromStream(streamedResponse);
        },
      );

      print(
          'DEBUG - Chunk upload HTTP ${response.statusCode} for session=${request.sessionId} index=${request.chunkIndex}');
      print('DEBUG - Chunk upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            response.body.isNotEmpty ? json.decode(response.body) : {};
        return TranscriptionResponse.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut enviar el fragment d\'àudio.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<TranscriptionResponse> completeTranscriptionSession(
    TranscriptionCompleteRequest request,
  ) async {
    try {
      final response = await _sendAuthorizedRequest(
        (token, client) => client.post(
          Uri.parse('$_baseUrl/transcription/complete'),
          headers: _jsonHeaders(token),
          body: json.encode(request.toJson()),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return TranscriptionResponse.fromJson(responseData);
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut completar la transcripció.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de connexió amb el servidor: ${e.toString()}',
        0,
      );
    }
  }

  static Future<TranscriptionResponse> uploadRecordingFromBytes(
    List<int> bytes, {
    required String questionId,
    String filename = 'recording.wav',
    String contentType = 'audio/wav',
    int chunkSize = 512 * 1024,
  }) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final total = bytes.length;
      int chunkIndex = 0;

      while (chunkIndex * chunkSize < total) {
        final start = chunkIndex * chunkSize;
        final end = (start + chunkSize) > total ? total : (start + chunkSize);
        final chunkBytes = bytes.sublist(start, end);

        final chunkRequest = TranscriptionChunkRequest(
          sessionId: sessionId,
          chunkIndex: chunkIndex,
          audioBytes: chunkBytes,
          filename: filename,
          contentType: contentType,
        );

        await uploadTranscriptionChunk(chunkRequest);
        chunkIndex += 1;
      }

      final completeResponse = await completeTranscriptionSession(
        TranscriptionCompleteRequest(
          sessionId: sessionId,
          questionId: questionId,
        ),
      );
      return completeResponse;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error uploading recording: ${e.toString()}', 0);
    }
  }

  static Future<void> _persistSession({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    final saved = await SessionManager.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userData: userData,
    );

    if (!saved) {
      throw ApiException(
        'La sessió s\'ha creat però no s\'ha pogut persistir localment.',
        0,
      );
    }
  }

  static Future<void> _persistUserProfile(
    UserProfile profile, {
    bool? alreadyRespondedToday,
  }) async {
    final inferredType = profile.role.inferUserType();
    final data = {
      'name': profile.name,
      'surname': profile.surname,
      'email': profile.email,
      'role': profile.role.toJson(),
      'user_type': inferredType.name,
      if (alreadyRespondedToday != null)
        'already_responded_today': alreadyRespondedToday,
    };
    final saved = await SessionManager.saveUserData(data);
    if (!saved) {
      throw ApiException(
        'Sessió iniciada però no s\'ha pogut guardar el perfil localment.',
        0,
      );
    }
  }

  static Map<String, String> _jsonHeaders(
    String token, {
    Map<String, String>? extra,
  }) {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if (extra != null && extra.isNotEmpty) {
      headers.addAll(extra);
    }
    return headers;
  }

  static Future<http.Response> performAuthenticatedRequest(
    Future<http.Response> Function(String token, http.Client client)
        requestFn, {
    bool retryOnUnauthorized = true,
  }) {
    return _sendAuthorizedRequest(
      requestFn,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  static Future<http.Response> _sendAuthorizedRequest(
    _AuthorizedRequest requestFn, {
    bool retryOnUnauthorized = true,
  }) async {
    var token = await _requireValidAccessToken();
    var response = await requestFn(token, _sharedClient);
    if (response.statusCode != 401 || !retryOnUnauthorized) {
      return response;
    }

    token = await _refreshAccessToken();
    response = await requestFn(token, _sharedClient);
    if (response.statusCode == 401) {
      await SessionManager.handleExpiredSession();
      throw ApiException(
        'Sessió caducada. Torna a iniciar sessió.',
        401,
      );
    }
    return response;
  }

  static Future<String> _requireValidAccessToken() async {
    var token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      await SessionManager.handleExpiredSession();
      throw ApiException(
        'Sessió no trobada o caducada. Torna a iniciar sessió.',
        401,
      );
    }

    if (SessionManager.isTokenExpired(token)) {
      token = await _refreshAccessToken();
    }
    return token;
  }

  static Future<String> _refreshAccessToken({double? hoursValidity}) async {
    var refreshToken = await SessionManager.getRefreshToken();
    refreshToken ??= await SessionManager.getToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await SessionManager.handleExpiredSession();
      throw ApiException(
        'Sessió caducada. Torna a iniciar sessió.',
        401,
      );
    }

    try {
      Uri uri = Uri.parse('$_baseUrl/user/login');
      if (hoursValidity != null) {
        uri = uri.replace(
          queryParameters: {'hours_validity': hoursValidity.toString()},
        );
      }

      final response = await _sharedClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $refreshToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map<String, dynamic>) {
          throw ApiException('Resposta invàlida del servidor.', 500);
        }

        final loginResponse = LoginResponse.fromJson(data);
        await SessionManager.saveToken(loginResponse.accessToken);

        // Merge existing user data with the fresh daily flag
        final existingUserData =
            await SessionManager.getUserData() ?? <String, dynamic>{};
        final mergedUserData = Map<String, dynamic>.from(existingUserData)
          ..['already_responded_today'] = loginResponse.alreadyRespondedToday;
        await SessionManager.saveUserData(mergedUserData);

        return loginResponse.accessToken;
      }

      throw _apiExceptionFromResponse(
        response,
        'No s\'ha pogut refrescar la sessió.',
      );
    } catch (e) {
      await SessionManager.handleExpiredSession();
      if (e is ApiException) rethrow;
      throw ApiException(
        'No s\'ha pogut refrescar la sessió: ${e.toString()}',
        401,
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
      case 409:
        message = 'Conflicte de rol d\'usuari.';
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
