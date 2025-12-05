import 'dart:convert';

import 'package:bitsxlamarato_frontend_2025/models/activity_models.dart';
import 'package:bitsxlamarato_frontend_2025/services/activities_api_service.dart';
import 'package:bitsxlamarato_frontend_2025/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'token-mock'});
  });

  tearDown(ApiService.reset);

  group('ActivitiesApiService - recommended', () {
    test('fetchRecommendedActivities retorna una activitat amb token i capçaleres', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/v1/activity/recommended'));
        expect(request.headers['Authorization'], equals('Bearer token-mock'));
        return http.Response(
          jsonEncode({
            'id': 'abc',
            'title': 'Prova',
            'description': 'Descripció',
            'activity_type': 'speed',
            'difficulty': 2.5,
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      ApiService.configure(
        client: mockClient,
        baseUrl: 'http://example.com',
      );

      final service = const ActivitiesApiService();
      final result = await service.fetchRecommendedActivities();

      expect(result, hasLength(1));
      expect(result.first.title, 'Prova');
      expect(result.first.activityType, 'speed');
      expect(result.first.difficulty, 2.5);
    });
  });

  group('ActivitiesApiService - searchActivities', () {
    test('construeix query amb search, type i rang de dificultat sense ID', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/v1/activity'));
        final params = request.url.queryParameters;
        expect(params['search'], 'memoria');
        expect(params['activity_type'], 'concentration');
        expect(params['difficulty_min'], '1.0');
        expect(params['difficulty_max'], '3.0');
        expect(params.containsKey('difficulty'), isFalse);
        expect(params.containsKey('id'), isFalse);
        return http.Response(
          jsonEncode([
            {
              'id': 'x1',
              'title': 'Memòria curta',
              'description': 'Descripció',
              'activity_type': 'concentration',
              'difficulty': 2.0,
            }
          ]),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      ApiService.configure(
        client: mockClient,
        baseUrl: 'http://example.com',
      );

      final service = const ActivitiesApiService();
      final results = await service.searchActivities(
        query: 'memoria',
        type: 'concentration',
        difficultyMin: 1.0,
        difficultyMax: 3.0,
        title: null,
      );

      expect(results, hasLength(1));
      expect(results.first.title, 'Memòria curta');
    });

    test('usa difficulty exacte quan s’indica i omet rang', () async {
      final mockClient = MockClient((request) async {
        final params = request.url.queryParameters;
        expect(params['difficulty'], '4.0');
        expect(params.containsKey('difficulty_min'), isFalse);
        expect(params.containsKey('difficulty_max'), isFalse);
        return http.Response(
          jsonEncode([
            {
              'id': 'x2',
              'title': 'Velocitat',
              'description': 'Descripció',
              'activity_type': 'speed',
              'difficulty': 4.0,
            }
          ]),
          200,
        );
      });

      ApiService.configure(
        client: mockClient,
        baseUrl: 'http://example.com',
      );

      final service = const ActivitiesApiService();
      final results = await service.searchActivities(
        difficulty: 4.0,
      );

      expect(results.single.activityType, 'speed');
      expect(results.single.difficulty, 4.0);
    });
  });
}
