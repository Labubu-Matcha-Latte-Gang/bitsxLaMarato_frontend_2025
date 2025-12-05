import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:universal_html/html.dart' as html;

class VoiceChunkUploadRequest {
  final String sessionId;
  final int chunkIndex;
  final Uint8List? audioBytes; // raw bytes (can be used for both web & native)
  final File? audioFile; // native File (mobile/desktop)
  final html.Blob? webBlob; // web Blob (from mic.dart)
  final String? filename;
  final String? mimeType;

  VoiceChunkUploadRequest({
    required this.sessionId,
    required this.chunkIndex,
    this.audioBytes,
    this.audioFile,
    this.webBlob,
    this.filename,
    this.mimeType,
  }) : assert(
          audioBytes != null || audioFile != null || webBlob != null,
          'Provide either audioBytes, audioFile or webBlob',
        );

  Map<String, String> toFormFields() {
    return {
      'session_id': sessionId,
      'chunk_index': chunkIndex.toString(),
    };
  }

  Future<http.MultipartFile> toMultipartFile() async {
    final fieldName = 'audio_blob';
    final name = filename ?? 'chunk_$chunkIndex';
    final contentType = mimeType != null ? MediaType.parse(mimeType!) : null;

    // Native File path (mobile/desktop)
    if (audioFile != null) {
      return await http.MultipartFile.fromPath(
        fieldName,
        audioFile!.path,
        filename: name,
        contentType: contentType,
      );
    }

    // Web Blob (from mic.dart) -> read as ArrayBuffer via FileReader
    if (webBlob != null) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(webBlob!);
      await reader.onLoad.first;

      final result = reader.result;
      Uint8List bytes;
      if (result is ByteBuffer) {
        bytes = Uint8List.view(result);
      } else if (result is List<int>) {
        bytes = Uint8List.fromList(result);
      } else {
        throw Exception('Unsupported Blob read result type: ${result.runtimeType}');
      }

      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: name,
        contentType: contentType,
      );
    }

    // Raw bytes
    return http.MultipartFile.fromBytes(
      fieldName,
      audioBytes!,
      filename: name,
      contentType: contentType,
    );
  }

  /// Convenience: attach fields and file to a `http.MultipartRequest`
  Future<void> attachToMultipartRequest(http.MultipartRequest req) async {
    req.fields.addAll(toFormFields());
    req.files.add(await toMultipartFile());
  }
}
