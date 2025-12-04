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

  test('createActivitiesBulk parses list responses', () async {
    await SessionManager.saveToken('bulk-token');
    ApiService.configure(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/activity/bulk');
        final activities = [
          {
            'id': 'a1',
            'title': 'Walk',
            'description': 'desc',
            'activity_type': 'cardio',
            'difficulty': 1.0,
          },
          {
            'id': 'a2',
            'title': 'Run',
            'description': 'desc',
            'activity_type': 'cardio',
            'difficulty': 2.0,
          },
        ];
        return http.Response(jsonEncode(activities), 201);
      }),
    );

    final created = await ApiService.createActivitiesBulk(
      ActivityBulkCreateRequest(
        activities: [
          ActivityCreateRequest(
            title: 'Walk',
            description: 'desc',
            activityType: 'cardio',
            difficulty: 1.0,
          ),
          ActivityCreateRequest(
            title: 'Run',
            description: 'desc',
            activityType: 'cardio',
            difficulty: 2.0,
          ),
        ],
      ),
    );

    expect(created.map((a) => a.id), containsAll(['a1', 'a2']));
  });

  test('createActivitiesBulk parses wrapped activities payload', () async {
    await SessionManager.saveToken('bulk-token');
    ApiService.configure(
      client: MockClient((request) async {
        final body = {
          'activities': [
            {
              'id': 'wrapped',
              'title': 'Swim',
              'description': 'desc',
              'activity_type': 'cardio',
              'difficulty': 3.5,
            }
          ]
        };
        return http.Response(jsonEncode(body), 200);
      }),
    );

    final created = await ApiService.createActivitiesBulk(
      ActivityBulkCreateRequest(
        activities: [
          ActivityCreateRequest(
            title: 'Swim',
            description: 'desc',
            activityType: 'cardio',
            difficulty: 3.5,
          ),
        ],
      ),
    );

    expect(created.single.id, 'wrapped');
    expect(created.single.activityType, 'cardio');
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

  test('getActivity surfaces mapped errors from server', () async {
    await SessionManager.saveToken('token');
    ApiService.configure(
      client: MockClient((request) async {
        return http.Response('{}', 404);
      }),
    );

    expect(
      ApiService.getActivity('missing'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 404)
            .having((e) => e.message, 'message', 'Recurs no trobat.'),
      ),
    );
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
