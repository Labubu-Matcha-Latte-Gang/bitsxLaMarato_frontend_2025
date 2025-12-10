import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'session_manager.dart';

class QRApiService {
  // Usa la misma URL base que el resto de servicios (configurable por API_URL)
  static final String _baseUrl = '${Config.apiUrl}/api/v1';

  /// Obtiene el código QR del informe médico del paciente
  ///
  /// Parámetros:
  /// - [timestamp]: (Opcional) Timestamp específico
  /// - [license]: (Opcional) Licencia del profesional
  /// - [format]: (Opcional) Formato del QR (por defecto 'svg')
  /// - [back_color]: (Opcional) Color de fondo en formato hexadecimal
  ///
  /// Retorna:
  /// - Mapa con:
  ///   - 'qr_code': URL de la imagen QR
  ///   - 'timestamp': Timestamp del QR
  ///   - 'additionalProp1': (Opcional) Propiedades adicionales
  static Future<Map<String, dynamic>> generateQRCode({
    String? timestamp,
    String? license,
    String format = 'svg',
    String? backColor,
  }) async {
    try {
      // Obtener el token JWT
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Token no disponible. Por favor inicia sesión.');
      }

      // Construir la URL con parámetros de query
      String url = '$_baseUrl/qr/obtenir-un-codi-qr-per-a-linformemedic';

      final queryParams = <String, String>{
        'format': format,
      };

      if (timestamp != null) queryParams['timestamp'] = timestamp;
      if (license != null) queryParams['license'] = license;
      if (backColor != null) queryParams['back_color'] = backColor;

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      // Realizar la solicitud POST
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'qr_code': jsonResponse['qr_code'],
          'timestamp': jsonResponse['timestamp'],
          'additionalProp1': jsonResponse['additionalProp1'] ?? '',
        };
      } else if (response.statusCode == 401) {
        throw Exception('Token JWT inválido o expirado.');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para acceder a este recurso.');
      } else if (response.statusCode == 422) {
        throw Exception(
            'El código de la solicitud no ha superado la validación.');
      } else if (response.statusCode == 500) {
        throw Exception(
            'Error inesperado del servidor al generar el código QR.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}\n${response.body}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
