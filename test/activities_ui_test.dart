import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bitsxlamarato_frontend_2025/features/screens/activities/activities_page.dart';
import 'package:bitsxlamarato_frontend_2025/features/screens/activities/widgets/activity_card.dart';
import 'package:bitsxlamarato_frontend_2025/models/activity_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  final ByteData _imageBytes = ByteData.sublistView(
    Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y5Gx3sAAAAASUVORK5CYII=',
      ),
    ),
  );

  Map<String, List<String>> get _manifestJson => const {
        'assets/logos/logo-text-blau.png': ['assets/logos/logo-text-blau.png'],
        'assets/logos/logo-text-blanc.png': ['assets/logos/logo-text-blanc.png'],
        'assets/logos/logo-blau.png': ['assets/logos/logo-blau.png'],
        'assets/logos/logo-blanc.png': ['assets/logos/logo-blanc.png'],
      };

  Map<String, List<Map<String, String>>> get _manifestBin => const {
        'assets/logos/logo-text-blau.png': [
          {'asset': 'assets/logos/logo-text-blau.png'}
        ],
        'assets/logos/logo-text-blanc.png': [
          {'asset': 'assets/logos/logo-text-blanc.png'}
        ],
        'assets/logos/logo-blau.png': [
          {'asset': 'assets/logos/logo-blau.png'}
        ],
        'assets/logos/logo-blanc.png': [
          {'asset': 'assets/logos/logo-blanc.png'}
        ],
      };

  @override
  Future<ByteData> load(String key) async {
    if (_manifestJson.containsKey(key)) {
      return _imageBytes;
    }
    return ByteData(0);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'AssetManifest.json') {
      return jsonEncode(_manifestJson);
    }
    return '';
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async {
    if (key == 'AssetManifest.bin') {
      final ByteData? encoded =
          const StandardMessageCodec().encodeMessage(_manifestBin);
      final manifestData = encoded ?? ByteData(0);
      return parser(manifestData);
    }
    return parser(ByteData(0));
  }
}

Widget _wrapWithApp(Widget child) {
  return DefaultAssetBundle(
    bundle: _FakeAssetBundle(),
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ActivityCard mostra tipus i dificultat i amaga ID', (tester) async {
    final activity = Activity(
      id: 'secret-id',
      title: 'Prova',
      description: 'Descripció de prova',
      activityType: 'speed',
      difficulty: 1.5,
    );

    await tester.pumpWidget(
      _wrapWithApp(
        Scaffold(
          body: ActivityCard(
            activity: activity,
            isDarkMode: false,
          ),
        ),
      ),
    );

    expect(find.textContaining('ID'), findsNothing);
    expect(find.text('Tipus: speed'), findsOneWidget);
    expect(find.text('Dificultat: 1.5'), findsOneWidget);
  });

  testWidgets('ActivitiesPage mostra els botons centrats', (tester) async {
    await tester.pumpWidget(
      _wrapWithApp(const ActivitiesPage()),
    );

    final recomanadesFinder = find.text('Activitats recomanades');
    final totesFinder = find.text('Totes les activitats');

    expect(recomanadesFinder, findsOneWidget);
    expect(totesFinder, findsOneWidget);

    final centerAncestor = find.ancestor(
      of: recomanadesFinder,
      matching: find.byType(Center),
    );
    expect(centerAncestor, findsWidgets);
  });
}
