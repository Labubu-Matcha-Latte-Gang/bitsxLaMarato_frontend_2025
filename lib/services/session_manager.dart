import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionManager {
  static const String _tokenKey = 'access_token';
  static const String _userDataKey = 'user_data';

  // Guardar token de acceso
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  // Obtener token de acceso
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Verificar si hay una sesión activa
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Guardar datos del usuario
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userDataKey, json.encode(userData));
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Obtener datos del usuario
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return json.decode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Cerrar sesión (eliminar token y datos de usuario)
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenRemoved = await prefs.remove(_tokenKey);
      final userDataRemoved = await prefs.remove(_userDataKey);
      return tokenRemoved && userDataRemoved;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  // Limpiar toda la sesión
  static Future<bool> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing session: $e');
      return false;
    }
  }
}
