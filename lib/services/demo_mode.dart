import 'api_service.dart';
import 'demo_http_client.dart';
import 'session_manager.dart';

/// Singleton that tracks whether the app is running in demo mode.
/// In demo mode, all API calls are intercepted by [DemoHttpClient]
/// and return hardcoded data — nothing is sent to the real backend.
class DemoMode {
  DemoMode._();
  static final DemoMode _instance = DemoMode._();
  factory DemoMode() => _instance;

  bool _active = false;
  String _role = 'patient'; // 'patient' or 'doctor'

  static bool get isActive => _instance._active;
  static String get role => _instance._role;

  // Fake JWT with exp in year 2030 so isTokenExpired() returns false.
  static const String fakeToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJzdWIiOiJkZW1vQG5ldXJvc2lnaHQuYXBwIiwiZXhwIjoxODkzNDU2MDAwfQ'
      '.demo_signature';

  /// Activates demo mode for the given [role] ('patient' or 'doctor').
  /// Installs [DemoHttpClient] into [ApiService] and populates
  /// [SessionManager] with fake session data.
  static Future<void> activate({required String role}) async {
    _instance._role = role;
    _instance._active = true;

    // Install mock HTTP client
    ApiService.configure(client: DemoHttpClient());

    // Persist fake session so screens that read user data work
    final userData = _buildFakeUserData(role);
    await SessionManager.saveSession(
      accessToken: fakeToken,
      refreshToken: fakeToken,
      userData: userData,
    );
  }

  /// Deactivates demo mode, resets [ApiService] and clears session.
  static Future<void> deactivate() async {
    _instance._active = false;
    _instance._role = 'patient';
    ApiService.reset();
    await SessionManager.logout();
  }

  static Map<String, dynamic> _buildFakeUserData(String role) {
    if (role == 'doctor') {
      return {
        'user_type': 'doctor',
        'already_responded_today': true,
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
      'user_type': 'patient',
      'already_responded_today': true,
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
}
