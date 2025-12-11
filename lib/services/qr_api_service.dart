import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_service.dart';

class QRApiService {
  // Usa la misma URL base que el resto de servicios (configurable por API_URL)
  static final String _baseUrl = '${Config.apiUrl}/api/v1';

  /// Genera el código QR para informe médico según la especificación QRGenerate
  /// del backend.
  static Future<Map<String, dynamic>> generateQRCode({
    String timezone = 'Europe/Madrid',
    String format = 'svg', // enum: png | svg
    String fillColor = '#000000',
    String backColor = '#FFFFFF',
    int boxSize = 10,
    int border = 4,
  }) async {
    try {
      final payload = <String, dynamic>{
        'timezone': timezone,
        'format': format,
        'fill_color': fillColor,
        'back_color': backColor,
        'box_size': boxSize,
        'border': border,
      };

      final response = await ApiService.performAuthenticatedRequest(
        (token, client) => client.post(
          Uri.parse('$_baseUrl/qr'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        ),
      );

      if (response.statusCode == 200) {
        // El backend devuelve PNG o SVG como binary/string
        String qrDataUri;

        if (format == 'png' || format.contains('png')) {
          // PNG: response body es bytes, convertir a base64
          final base64Png = base64Encode(response.bodyBytes);
          qrDataUri = 'data:image/png;base64,$base64Png';
        } else {
          // SVG: response body es XML string
          final bytes = utf8.encode(response.body);
          final base64Svg = base64Encode(bytes);
          qrDataUri = 'data:image/svg+xml;base64,$base64Svg';
        }

        return {
          'success': true,
          'qr_code': qrDataUri,
        };
      } else if (response.statusCode == 401) {
        throw Exception(
            'Token JWT inválido o expirado. Inicia sesión de nuevo.');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Només els pacients poden generar un codi QR d\'informe mèdic.');
      } else if (response.statusCode == 422) {
        throw Exception(
            'El cos de la sol·licitud no ha superat la validació.');
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
