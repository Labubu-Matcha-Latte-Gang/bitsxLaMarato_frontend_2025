import 'package:bitsxlamarato_frontend_2025/services/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/test_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager.configure(secureStore: InMemorySecureStore());
  });

  test('saveToken stores and retrieves token', () async {
    final saved = await SessionManager.saveToken('abc123');
    final token = await SessionManager.getToken();

    expect(saved, isTrue);
    expect(token, 'abc123');
    expect(await SessionManager.isLoggedIn(), isTrue);
  });

  test('saveUserData persists map and can be cleared', () async {
    final data = {'name': 'Pat', 'role': 'patient'};
    final saved = await SessionManager.saveUserData(data);
    final stored = await SessionManager.getUserData();

    expect(saved, isTrue);
    expect(stored, data);

    final cleared = await SessionManager.clearSession();
    expect(cleared, isTrue);
    expect(await SessionManager.getUserData(), isNull);
    expect(await SessionManager.getToken(), isNull);
  });

  test('logout removes token and user data keys only', () async {
    await SessionManager.saveToken('token');
    await SessionManager.saveUserData({'name': 'Pat'});

    final loggedOut = await SessionManager.logout();

    expect(loggedOut, isTrue);
    expect(await SessionManager.getToken(), isNull);
    expect(await SessionManager.getUserData(), isNull);
  });
}
