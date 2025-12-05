import 'dart:convert';
import 'package:bitsxlamarato_frontend_2025/models/activity_models.dart';
import 'package:bitsxlamarato_frontend_2025/models/patient_models.dart';
import 'package:bitsxlamarato_frontend_2025/models/transcription_models.dart';
import 'package:bitsxlamarato_frontend_2025/services/api_service.dart';
import 'package:bitsxlamarato_frontend_2025/services/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.reset(closeExistingClient: true);
  });

  tearDown(() {
    ApiService.reset(closeExistingClient: true);
  });

  test('listActivities builds auth headers and query parameters', () async {
    await SessionManager.saveToken('token-123');
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer token-123');
        expect(request.url.path, '/api/v1/activity');
        expect(
          request.url.queryParameters,
          {
            'title': 'Puzzle',
            'difficulty_min': '0.5',
          },
        );

        final body = [
          {
            'id': '1',
            'title': 'Puzzle',
            'description': 'desc',
            'activity_type': 'logic',
            'difficulty': 0.5,
          },
        ];
        return http.Response(jsonEncode(body), 200);
      }),
    );

    final activities = await ApiService.listActivities(
      query: ActivityQueryParams(title: 'Puzzle', difficultyMin: 0.5),
    );

    expect(activities, hasLength(1));
    expect(activities.first.title, 'Puzzle');
    expect(activities.first.difficulty, 0.5);
  });

  test('listActivities throws when auth token is missing', () async {
    ApiService.configure(
      client: MockClient((request) async {
        return http.Response('[]', 200);
      }),
    );

    expect(
      ApiService.listActivities(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'status', 401),
      ),
    );
  });

  test('getActivity filters by id via query param', () async {
    await SessionManager.saveToken('token');
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/activity');
        expect(request.url.queryParameters, {'id': '42'});

        final body = [
          {
            'id': '42',
            'title': 'Yoga',
            'description': 'desc',
            'activity_type': 'stretch',
            'difficulty': 0.2,
          },
        ];
        return http.Response(jsonEncode(body), 200);
      }),
    );

    final activity = await ApiService.getActivity('42');

    expect(activity.id, '42');
    expect(activity.activityType, 'stretch');
    expect(activity.difficulty, 0.2);
  });

  test('completeActivity returns parsed response', () async {
    await SessionManager.saveToken('complete-token');
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/activity/complete');
        final body = {
          'patient': {'email': 'pat@example.com'},
          'activity': {
            'id': '42',
            'title': 'Yoga',
            'description': 'desc',
            'activity_type': 'stretch',
            'difficulty': 0.2,
          },
          'completed_at': '2024-03-01T10:00:00Z',
          'score': 90.0,
          'seconds_to_finish': 120.0
        };
        return http.Response(jsonEncode(body), 200);
      }),
    );

    final response = await ApiService.completeActivity(
      ActivityCompleteRequest(id: '42', score: 90.0, secondsToFinish: 120.0),
    );

    expect(response.activity.id, '42');
    expect(response.patient['email'], 'pat@example.com');
    expect(response.score, 90.0);
    expect(response.secondsToFinish, 120.0);
  });

  test('loginUser parses token and user payload', () async {
    ApiService.configure(
      client: MockClient((request) async {
        final body = {
          'access_token': 'jwt-token',
          'user': {
            '_id': 'u1',
            'name': 'Doc',
            'surname': 'Who',
            'email': 'doc@example.com',
            'user_type': 'doctor',
          },
        };
        return http.Response(jsonEncode(body), 200);
      }),
    );

    final response = await ApiService.loginUser(
      LoginRequest(email: 'doc@example.com', password: 'secret'),
    );

    expect(response.accessToken, 'jwt-token');
    expect(response.user?.name, 'Doc');
    expect(response.user?.userType, 'doctor');
  });

  test('loginUser maps validation errors from server', () async {
    ApiService.configure(
      client: MockClient((request) async {
        final errors = {
          'email': ['Invalid email'],
          'password': ['Too short']
        };
        return http.Response(jsonEncode({'errors': errors}), 422);
      }),
    );

    expect(
      ApiService.loginUser(
        LoginRequest(email: 'bad', password: 'x'),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 422)
            .having(
              (e) => e.message,
              'message',
              contains('Errors de validació'),
            ),
      ),
    );
  });

  test('registerPatient parses access token and role data', () async {
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/user/patient');
        final body = {
          'email': 'pat@example.com',
          'name': 'Pat',
          'surname': 'Smith',
          'access_token': 'reg-token',
          'role': {
            'ailments': 'none',
            'gender': 'male',
            'age': 30,
            'treatments': 'none',
            'height_cm': 170.0,
            'weight_kg': 70.0,
            'doctors': [],
          },
        };
        return http.Response(jsonEncode(body), 201);
      }),
    );

    final req = PatientRegistrationRequest(
      name: 'Pat',
      surname: 'Smith',
      email: 'pat@example.com',
      password: 'secret',
      ailments: 'none',
      gender: 'male',
      age: 30,
      treatments: 'none',
      heightCm: 170.0,
      weightKg: 70.0,
      doctors: const [],
    );

    final response = await ApiService.registerPatient(req);

    expect(response.accessToken, 'reg-token');
    expect(response.role.age, 30);
    expect(response.role.heightCm, 170.0);
    expect(await SessionManager.getToken(), 'reg-token');
  });

  test('registerPatient surfaces validation errors from server payload', () async {
    ApiService.configure(
      client: MockClient((request) async {
        final errors = {'email': 'already used', 'password': 'weak'};
        return http.Response(jsonEncode({'errors': errors}), 422);
      }),
    );

    final req = PatientRegistrationRequest(
      name: 'Pat',
      surname: 'Smith',
      email: 'pat@example.com',
      password: 'secret',
      ailments: 'none',
      gender: 'm',
      age: 30,
      treatments: 'none',
      heightCm: 170.0,
      weightKg: 70.0,
      doctors: const [],
    );

    expect(
      ApiService.registerPatient(req),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 422)
            .having(
              (e) => e.message,
              'message',
              contains('Errors de validació'),
            ),
      ),
    );
  });

  test('registerDoctor parses access token and role data', () async {
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/user/doctor');
        final body = {
          'email': 'doc@example.com',
          'name': 'Doc',
          'surname': 'Who',
          'access_token': 'doctor-token',
          'role': {
            'patients': ['p1', 'p2'],
          },
        };
        return http.Response(jsonEncode(body), 201);
      }),
    );

    final req = DoctorRegistrationRequest(
      name: 'Doc',
      surname: 'Who',
      email: 'doc@example.com',
      password: 'secret',
      patients: const [],
    );

    final response = await ApiService.registerDoctor(req);

    expect(response.accessToken, 'doctor-token');
    expect(response.role.patients, ['p1', 'p2']);
    expect(await SessionManager.getToken(), 'doctor-token');
  });

  test('getPatientData maps nested payloads', () async {
    await SessionManager.saveToken('token');
    ApiService.configure(
      client: MockClient((request) async {
        final body = {
          'patient': {
            'email': 'pat@example.com',
            'name': 'Pat',
            'surname': 'Smith',
            'role': {
              'ailments': 'none',
              'gender': 'm',
              'age': 30,
              'treatments': 'none',
              'height_cm': 170.0,
              'weight_kg': 70.0,
              'doctors': ['d1'],
            },
          },
          'scores': [
            {
              'activity_id': '1',
              'activity_title': 'Walk',
              'activity_type': 'cardio',
              'completed_at': '2024-02-02',
              'score': 80.0,
              'seconds_to_finish': 50.0,
            }
          ],
          'questions': [
            {
              'question': {
                'id': 'q1',
                'text': 'How are you?',
                'question_type': 'text',
                'difficulty': 1.0,
              },
              'answered_at': '2024-02-02',
              'analysis': {'mood': 0.9}
            }
          ],
          'graph_files': [
            {
              'filename': 'graph.png',
              'content_type': 'image/png',
              'content': 'base64data'
            }
          ],
        };
        return http.Response(jsonEncode(body), 200);
      }),
    );

    final response = await ApiService.getPatientData('pat@example.com');

    expect(response.patient.email, 'pat@example.com');
    expect(response.scores.single.activityTitle, 'Walk');
    expect(response.questions.single.analysis['mood'], 0.9);
    expect(response.graphFiles.single.filename, 'graph.png');
  });

  test('uploadTranscriptionChunk sends multipart data and parses response',
      () async {
    await SessionManager.saveToken('token');
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/transcription/chunk');
        expect(request.headers['authorization'], 'Bearer token');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );

        return http.Response(
          jsonEncode(
            {'status': 'ok', 'partial_text': 'hola', 'analysis': {'tone': 1.0}},
          ),
          200,
        );
      }),
    );

    final response = await ApiService.uploadTranscriptionChunk(
      TranscriptionChunkRequest(
        sessionId: 's1',
        chunkIndex: 1,
        audioBytes: [1, 2, 3],
      ),
    );

    expect(response.status, 'ok');
    expect(response.partialText, 'hola');
    expect(response.analysis['tone'], 1.0);
  });

  test('completeTranscriptionSession parses response', () async {
    await SessionManager.saveToken('token');
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/transcription/complete');
        return http.Response(
          jsonEncode({'status': 'done', 'transcription': 'hello world'}),
          200,
        );
      }),
    );

    final response = await ApiService.completeTranscriptionSession(
      TranscriptionCompleteRequest(sessionId: 's1'),
    );

    expect(response.status, 'done');
    expect(response.transcription, 'hello world');
  });
}
