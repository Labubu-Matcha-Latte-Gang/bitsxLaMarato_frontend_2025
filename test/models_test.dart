import 'package:bitsxlamarato_frontend_2025/models/activity_models.dart';
import 'package:bitsxlamarato_frontend_2025/models/patient_models.dart';
import 'package:bitsxlamarato_frontend_2025/models/question_models.dart';
import 'package:bitsxlamarato_frontend_2025/models/transcription_models.dart';
import 'package:bitsxlamarato_frontend_2025/models/user_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ActivityQueryParams only includes non-null values', () {
    final params = ActivityQueryParams(
      title: 'Run',
      difficultyMax: 3.2,
    ).toQueryParameters();

    expect(params['title'], 'Run');
    expect(params['difficulty_max'], '3.2');
    expect(params.containsKey('difficulty_min'), isFalse);
    expect(params.containsKey('id'), isFalse);
  });

  test('LoginResponse exposes daily flag', () {
    final response = LoginResponse.fromJson({
      'access_token': 'tok',
      'already_responded_today': false,
    });

    expect(response.accessToken, 'tok');
    expect(response.alreadyRespondedToday, isFalse);
  });

  test('LoginResponse respects provided daily flag', () {
    final response = LoginResponse.fromJson({
      'access_token': 'tok2',
      'already_responded_today': true,
    });

    expect(response.alreadyRespondedToday, isTrue);
  });

  test('UserRoleData parses doctors and patients lists safely', () {
    final role = UserRoleData.fromJson({
      'doctors': [1, 'd2'],
      'patients': ['p1'],
      'age': 40,
      'weight_kg': 70.5,
    });

    expect(role.doctors, ['1', 'd2']);
    expect(role.patients, ['p1']);
    expect(role.age, 40);
    expect(role.weightKg, 70.5);
  });

  test('QuestionAnswerWithAnalysis converts numeric analysis to double', () {
    final parsed = QuestionAnswerWithAnalysis.fromJson({
      'question': {
        'id': 'q1',
        'text': 'How are you?',
        'question_type': 'text',
        'difficulty': 1,
      },
      'answered_at': 'today',
      'analysis': {'mood': 1, 'energy': 0.75}
    });

    expect(parsed.question.id, 'q1');
    expect(parsed.analysis['mood'], 1.0);
    expect(parsed.analysis['energy'], 0.75);
  });

  test('TranscriptionResponse handles optional fields', () {
    final response = TranscriptionResponse.fromJson({'status': 'ok'});

    expect(response.status, 'ok');
    expect(response.transcription, isNull);
    expect(response.partialText, isNull);
    expect(response.analysis, isEmpty);
  });
}
