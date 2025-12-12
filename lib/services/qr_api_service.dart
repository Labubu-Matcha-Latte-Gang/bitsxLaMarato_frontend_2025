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
    String format = 'png', // enum: png | svg
    String fillColor = '#000000',
    String backColor = '#FFFFFF',
    int boxSize = 10,
    int border = 4,
    String? patientEmail,
  }) async {
    String normalizeHex(String color) {
      if (color.startsWith('#')) {
        return color.substring(1);
      }
      return color;
    }

    try {
      final payload = <String, dynamic>{
        'timezone': timezone,
        'format': format,
        'fill_color': normalizeHex(fillColor),
        'back_color': normalizeHex(backColor),
        'box_size': boxSize,
        'border': border,
      };
      if (patientEmail != null && patientEmail.isNotEmpty) {
        payload['patient_email'] = patientEmail;
      }

      final response = await ApiService.performAuthenticatedRequest(
        (token, client) => client.post(
          Uri.parse('$_baseUrl/qr'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json,image/png,image/svg+xml,*/*',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        ),
      );

      if (response.statusCode == 200) {
        final qrDataUri = _parseQrResponse(
          response,
          requestedFormat: format,
        );

        if (qrDataUri == null) {
          throw Exception('Resposta del servidor sense QR vàlid.');
        }

        return {
          'success': true,
          'qr_code': qrDataUri,
        };
      } else if (response.statusCode == 401) {
        throw Exception(
            'Token JWT invàlid o caducat. Torna a iniciar sessió.');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Només els pacients poden generar un codi QR d\'informe mèdic.');
      } else if (response.statusCode == 422) {
        throw Exception(
            'El cos de la sol·licitud no ha superat la validació.');
      } else if (response.statusCode == 500) {
        throw Exception(
            'Error inesperat del servidor en generar el codi QR.');
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

  static String? _parseQrResponse(
    http.Response response, {
    required String requestedFormat,
  }) {
    final contentTypeHeader =
        response.headers['content-type']?.toLowerCase() ?? '';

    if (contentTypeHeader.contains('application/json')) {
      try {
        final Map<String, dynamic> payload =
            json.decode(response.body) as Map<String, dynamic>;
        final rawValue = (payload['qr_code'] ??
                payload['qr'] ??
                payload['data'] ??
                payload['code'])
            ?.toString()
            .trim();

        if (rawValue == null || rawValue.isEmpty) {
          return null;
        }

        if (rawValue.startsWith('data:image/')) {
          return rawValue;
        }

        final mimeType = _inferMimeType(
          requestedFormat: requestedFormat,
          override: payload['mime_type']?.toString(),
        );
        return _dataUriFromRawValue(rawValue, mimeType);
      } catch (_) {
        return null;
      }
    }

    final inferredMimeType = _inferMimeType(
      requestedFormat: requestedFormat,
      override: contentTypeHeader.split(';').first,
    );
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) return null;
    final base64Image = base64Encode(bytes);
    return 'data:$inferredMimeType;base64,$base64Image';
  }

  static String _dataUriFromRawValue(String rawValue, String mimeType) {
    final trimmed = rawValue.trim();
    final sanitized = trimmed.replaceAll(RegExp(r'\s+'), '');
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');

    if (sanitized.isNotEmpty &&
        sanitized.length % 4 == 0 &&
        base64Pattern.hasMatch(sanitized)) {
      try {
        base64Decode(sanitized);
        return 'data:$mimeType;base64,$sanitized';
      } catch (_) {
        // Si no és base64 vàlid, continuar per codificar el text.
      }
    }

    final encoded = base64Encode(utf8.encode(trimmed));
    return 'data:$mimeType;base64,$encoded';
  }

  static String _inferMimeType({
    required String requestedFormat,
    String? override,
  }) {
    final normalizedOverride = override?.trim().toLowerCase();
    if (normalizedOverride != null &&
        normalizedOverride.isNotEmpty &&
        normalizedOverride.contains('/')) {
      return normalizedOverride;
    }

    final normalizedFormat = requestedFormat.toLowerCase();
    if (normalizedFormat.contains('svg')) {
      return 'image/svg+xml';
    }
    if (normalizedFormat.contains('png')) {
      return 'image/png';
    }
    return 'application/octet-stream';
  }
}
