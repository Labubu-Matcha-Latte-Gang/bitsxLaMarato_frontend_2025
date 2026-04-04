import 'dart:convert';
import 'package:http/http.dart' as http;
import 'demo_mode.dart';

/// A mock [http.BaseClient] that returns hardcoded JSON responses
/// for every API endpoint, allowing the app to run without a backend.
class DemoHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    final method = request.method.toUpperCase();
    final path = uri.path;

    // Small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 300));

    // Route to handler
    final body = _route(method, path, uri.queryParameters);
    final bytes = utf8.encode(json.encode(body));

    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }

  dynamic _route(String method, String path, Map<String, String> query) {
    // --- AUTH ---
    if (path.endsWith('/user/login') && method == 'POST') {
      return _loginResponse();
    }
    if (path.endsWith('/user/login') && method == 'GET') {
      return _refreshTokenResponse();
    }

    // --- REGISTRATION ---
    if (path.endsWith('/user/patient') && method == 'POST') {
      return _patientRegistrationResponse();
    }
    if (path.endsWith('/user/doctor') && method == 'POST') {
      return _doctorRegistrationResponse();
    }

    // --- USER PROFILE ---
    if (_matchesExact(path, '/user') && method == 'GET') {
      return _currentUserProfile();
    }
    if (_matchesExact(path, '/user') && (method == 'PUT' || method == 'PATCH')) {
      return _currentUserProfile();
    }
    if (_matchesExact(path, '/user') && method == 'DELETE') {
      return {'status': 'deleted'};
    }

    // --- DOCTOR PATIENTS ---
    if (path.endsWith('/user/doctor/patients/mine')) {
      return _doctorPatientsList();
    }
    if (path.endsWith('/user/doctor/patients/search')) {
      return _patientSearchResults(query['query'] ?? '');
    }
    if (path.endsWith('/user/doctor/patients/assign')) {
      return _currentUserProfile();
    }
    if (path.endsWith('/user/doctor/patients/unassign')) {
      return _currentUserProfile();
    }

    // --- PATIENT DATA (GET /user/{email}) ---
    if (path.contains('/user/') && method == 'GET' && path.contains('@')) {
      return _patientDataResponse(path.split('/').last);
    }

    // --- REPORT ---
    if (path.contains('/report/')) {
      // Return minimal PDF-like bytes as base64 (will be decoded by the caller)
      return {'status': 'demo', 'message': 'Report download disabled in demo'};
    }

    // --- ACTIVITIES ---
    if (path.endsWith('/activity/recommended')) {
      return _recommendedActivity();
    }
    if (path.endsWith('/activity/complete') && method == 'POST') {
      return _activityCompleteResponse();
    }
    if (path.endsWith('/activity') || path.contains('/activity')) {
      if (query.containsKey('title')) {
        return _activitiesByTitle(query['title']!);
      }
      return _allActivities();
    }

    // --- QUESTIONS ---
    if (path.endsWith('/question/daily')) {
      return _dailyQuestion();
    }
    if (path.endsWith('/question/diary')) {
      return _diaryQuestion();
    }

    // --- TRANSCRIPTION ---
    if (path.endsWith('/transcription/chunk')) {
      return {'status': 'accepted', 'partial_text': ''};
    }
    if (path.endsWith('/transcription/complete')) {
      return _transcriptionComplete();
    }

    // --- QR ---
    if (path.endsWith('/qr') && method == 'POST') {
      return _qrResponse();
    }

    // --- LLM RECOMMENDATION ---
    if (path.endsWith('/llm-recommendation')) {
      return _flashcardResponse();
    }

    // Fallback
    return {'status': 'ok', 'demo': true};
  }

  bool _matchesExact(String path, String segment) {
    return path.endsWith(segment) &&
        !path.contains('doctor') &&
        !path.contains('@');
  }

  // ────────────────────── RESPONSE BUILDERS ──────────────────────

  Map<String, dynamic> _loginResponse() {
    return {
      'access_token': DemoMode.fakeToken,
      'already_responded_today': true,
    };
  }

  Map<String, dynamic> _refreshTokenResponse() {
    return {
      'access_token': DemoMode.fakeToken,
      'already_responded_today': true,
    };
  }

  Map<String, dynamic> _patientRegistrationResponse() {
    return {
      'email': 'pacient.demo@neurosight.app',
      'name': 'Demo',
      'surname': 'Pacient',
      'access_token': DemoMode.fakeToken,
      'role': {
        'ailments': 'Mild cognitive impairment',
        'gender': 'other',
        'age': 45,
        'treatments': 'Cognitive rehabilitation',
        'height_cm': 170.0,
        'weight_kg': 70.0,
        'doctors': ['dr.demo@neurosight.app'],
        'patients': [],
      },
    };
  }

  Map<String, dynamic> _doctorRegistrationResponse() {
    return {
      'email': 'dr.demo@neurosight.app',
      'name': 'Demo',
      'surname': 'Doctor',
      'access_token': DemoMode.fakeToken,
      'role': {
        'gender': 'other',
        'patients': [
          'pacient.demo@neurosight.app',
          'maria.garcia@neurosight.app',
          'joan.martinez@neurosight.app',
        ],
        'doctors': [],
      },
    };
  }

  Map<String, dynamic> _currentUserProfile() {
    if (DemoMode.role == 'doctor') {
      return {
        'email': 'dr.demo@neurosight.app',
        'name': 'Demo',
        'surname': 'Doctor',
        'role': {
          'gender': 'other',
          'patients': [
            'pacient.demo@neurosight.app',
            'maria.garcia@neurosight.app',
            'joan.martinez@neurosight.app',
          ],
          'doctors': [],
        },
      };
    }
    return {
      'email': 'pacient.demo@neurosight.app',
      'name': 'Demo',
      'surname': 'Pacient',
      'role': {
        'ailments': 'Mild cognitive impairment',
        'gender': 'other',
        'age': 45,
        'treatments': 'Cognitive rehabilitation',
        'height_cm': 170.0,
        'weight_kg': 70.0,
        'doctors': ['dr.demo@neurosight.app'],
        'patients': [],
      },
    };
  }

  List<Map<String, dynamic>> _doctorPatientsList() {
    return [
      {
        'email': 'pacient.demo@neurosight.app',
        'name': 'Demo',
        'surname': 'Pacient',
        'role': {
          'ailments': 'Mild cognitive impairment',
          'gender': 'Dona',
          'age': 45,
          'treatments': 'Cognitive rehabilitation',
          'height_cm': 165.0,
          'weight_kg': 62.0,
          'doctors': ['dr.demo@neurosight.app'],
          'patients': [],
        },
      },
      {
        'email': 'maria.garcia@neurosight.app',
        'name': 'Maria',
        'surname': 'Garcia',
        'role': {
          'ailments': 'Early-stage Alzheimer',
          'gender': 'Dona',
          'age': 68,
          'treatments': 'Donepezil + cognitive stimulation',
          'height_cm': 158.0,
          'weight_kg': 55.0,
          'doctors': ['dr.demo@neurosight.app'],
          'patients': [],
        },
      },
      {
        'email': 'joan.martinez@neurosight.app',
        'name': 'Joan',
        'surname': 'Martínez',
        'role': {
          'ailments': 'Post-stroke cognitive deficit',
          'gender': 'Home',
          'age': 72,
          'treatments': 'Speech therapy + occupational therapy',
          'height_cm': 175.0,
          'weight_kg': 80.0,
          'doctors': ['dr.demo@neurosight.app'],
          'patients': [],
        },
      },
    ];
  }

  Map<String, dynamic> _patientSearchResults(String query) {
    return {
      'query': query,
      'results': [
        {
          'email': 'anna.puig@neurosight.app',
          'name': 'Anna',
          'surname': 'Puig',
          'role': {
            'ailments': 'Attention deficit',
            'gender': 'Dona',
            'age': 34,
            'height_cm': 162.0,
            'weight_kg': 58.0,
            'doctors': [],
            'patients': [],
          },
        },
        {
          'email': 'pere.soler@neurosight.app',
          'name': 'Pere',
          'surname': 'Soler',
          'role': {
            'ailments': 'Mild cognitive impairment',
            'gender': 'Home',
            'age': 55,
            'height_cm': 180.0,
            'weight_kg': 85.0,
            'doctors': [],
            'patients': [],
          },
        },
      ],
    };
  }

  Map<String, dynamic> _patientDataResponse(String email) {
    return {
      'patient': {
        'email': email,
        'name': email.contains('maria') ? 'Maria' : (email.contains('joan') ? 'Joan' : 'Demo'),
        'surname': email.contains('maria') ? 'Garcia' : (email.contains('joan') ? 'Martínez' : 'Pacient'),
        'role': {
          'ailments': 'Mild cognitive impairment',
          'gender': 'Dona',
          'age': 45,
          'treatments': 'Cognitive rehabilitation',
          'height_cm': 165.0,
          'weight_kg': 62.0,
          'doctors': ['dr.demo@neurosight.app'],
          'patients': [],
        },
      },
      'scores': [
        {
          'activity_id': 'act-001',
          'activity_title': 'Memory Animals',
          'activity_type': 'memory',
          'completed_at': '2025-01-15T10:30:00Z',
          'score': 85.0,
          'seconds_to_finish': 120.0,
        },
        {
          'activity_id': 'act-003',
          'activity_title': 'Wordle Fàcil',
          'activity_type': 'word',
          'completed_at': '2025-01-14T14:20:00Z',
          'score': 92.0,
          'seconds_to_finish': 180.0,
        },
        {
          'activity_id': 'act-006',
          'activity_title': 'Stroop Test',
          'activity_type': 'cognition',
          'completed_at': '2025-01-13T09:15:00Z',
          'score': 78.0,
          'seconds_to_finish': 135.0,
        },
      ],
      'questions': [
        {
          'question': {
            'id': 'q-daily-001',
            'text': 'Com et sents avui?',
            'question_type': 'daily',
            'difficulty': 1.0,
          },
          'answered_at': '2025-01-15T08:00:00Z',
          'analysis': {
            'sentiment': 0.7,
            'coherence': 0.85,
            'vocabulary_richness': 0.6,
          },
          'transcription': 'Avui em sento bé, he dormit bastant bé i tinc ganes de fer activitats.',
        },
      ],
      'graph_files': [],
    };
  }

  List<Map<String, dynamic>> _allActivities() {
    return [
      {'id': 'act-001', 'title': 'Memory Animals', 'description': 'Troba les parelles d\'animals girant les cartes.', 'activity_type': 'memory', 'difficulty': 2.0},
      {'id': 'act-002', 'title': 'Memory Monuments', 'description': 'Troba les parelles de monuments històrics.', 'activity_type': 'memory', 'difficulty': 3.0},
      {'id': 'act-003', 'title': 'Wordle Fàcil', 'description': 'Endevina la paraula de 5 lletres en 6 intents. Nivell fàcil.', 'activity_type': 'word', 'difficulty': 1.0},
      {'id': 'act-004', 'title': 'Wordle (mitjà)', 'description': 'Endevina la paraula de 5 lletres en 6 intents. Nivell mitjà.', 'activity_type': 'word', 'difficulty': 3.0},
      {'id': 'act-005', 'title': 'Wordle (difícil)', 'description': 'Endevina la paraula de 5 lletres en 6 intents. Nivell difícil.', 'activity_type': 'word', 'difficulty': 5.0},
      {'id': 'act-006', 'title': 'Stroop Test', 'description': 'Test d\'interferència de colors per avaluar la concentració.', 'activity_type': 'cognition', 'difficulty': 3.0},
      {'id': 'act-007', 'title': 'Sorting', 'description': 'Ordena les cartes seguint patrons lògics.', 'activity_type': 'logic', 'difficulty': 2.0},
      {'id': 'act-008', 'title': 'Sudoku (fàcil)', 'description': 'Resol el trencaclosques numèric 9x9. Nivell fàcil.', 'activity_type': 'logic', 'difficulty': 1.0},
      {'id': 'act-009', 'title': 'Sudoku (mitjà)', 'description': 'Resol el trencaclosques numèric 9x9. Nivell mitjà.', 'activity_type': 'logic', 'difficulty': 3.0},
      {'id': 'act-010', 'title': 'Sudoku (difícil)', 'description': 'Resol el trencaclosques numèric 9x9. Nivell difícil.', 'activity_type': 'logic', 'difficulty': 5.0},
    ];
  }

  List<Map<String, dynamic>> _activitiesByTitle(String title) {
    return _allActivities()
        .where((a) => (a['title'] as String).toLowerCase().contains(title.toLowerCase()))
        .toList();
  }

  Map<String, dynamic> _recommendedActivity() {
    return {
      'id': 'act-001',
      'title': 'Memory Animals',
      'description': 'Troba les parelles d\'animals girant les cartes. Ideal per exercitar la memòria visual.',
      'activity_type': 'memory',
      'difficulty': 2.0,
    };
  }

  Map<String, dynamic> _activityCompleteResponse() {
    return {
      'patient': _currentUserProfile(),
      'activity': _recommendedActivity(),
      'completed_at': DateTime.now().toIso8601String(),
      'score': 85.0,
      'seconds_to_finish': 120.0,
    };
  }

  Map<String, dynamic> _dailyQuestion() {
    return {
      'id': 'q-daily-demo',
      'text': 'Com et sents avui? Explica\'ns com ha anat el teu dia.',
      'question_type': 'daily',
      'difficulty': 1.0,
    };
  }

  Map<String, dynamic> _diaryQuestion() {
    return {
      'id': 'q-diary-demo',
      'text': 'Quines activitats has fet avui que t\'han fet sentir bé?',
      'question_type': 'diary',
      'difficulty': 1.0,
    };
  }

  Map<String, dynamic> _transcriptionComplete() {
    return {
      'status': 'completed',
      'transcription': 'Avui em sento força bé. He dormit bé i tinc energia per fer les activitats cognitives.',
      'analysis': {
        'sentiment': 0.8,
        'coherence': 0.9,
        'vocabulary_richness': 0.7,
      },
    };
  }

  Map<String, dynamic> _qrResponse() {
    // A minimal valid 1x1 transparent PNG as data URI
    return {
      'qr_code': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    };
  }

  Map<String, dynamic> _flashcardResponse() {
    return {
      'cognitive_areas': [
        {'name': 'Memòria', 'percentage': 78.0},
        {'name': 'Concentració', 'percentage': 65.0},
        {'name': 'Velocitat', 'percentage': 82.0},
        {'name': 'Multitasca', 'percentage': 55.0},
      ],
      'description': 'Basant-nos en les teves activitats recents, el teu perfil cognitiu mostra fortaleses en velocitat de processament i memòria visual.',
      'recommendation': 'Et recomanem fer activitats de concentració i multitasca per equilibrar el teu perfil. Prova el Stroop Test o els jocs de Sorting.',
      'reason': 'Les activitats de concentració ajuden a millorar l\'atenció selectiva i la capacitat de filtrar distraccions, àrees on hi ha marge de millora.',
    };
  }
}
