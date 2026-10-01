import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lehrpfad_app/features/community/data/community_providers.dart';
import 'package:lehrpfad_app/features/community/data/image_upload_service.dart';
import 'package:lehrpfad_app/features/community/domain/photo_geo_check.dart';
import 'package:lehrpfad_app/features/community/presentation/image_upload_sheet.dart';
import 'package:lehrpfad_app/features/trail/data/providers.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

class _FakePicker extends ImagePicker {
  _FakePicker(this.result);
  final XFile? result;
  int calls = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    calls++;
    return result;
  }
}

class _HangingUploader implements ImageUploader {
  final done = Completer<void>();
  int calls = 0;

  @override
  Future<void> upload({
    required String trailId,
    required int? stationId,
    required String credit,
    required Uint8List bytes,
    required PhotoGeoCheck geoCheck,
    void Function(UploadPhase phase)? onPhase,
  }) {
    calls++;
    return done.future;
  }
}

Trail _trail() => const Trail(
  id: 'heide-erlebnisweg',
  name: 'Heide-Erlebnisweg',
  typ: 'lehrpfad',
  kurzbeschreibung: 'kurz',
  beschreibung: 'lang',
  laengeKm: 1,
  dauerMin: 60,
  rundkurs: true,
  markierung: 'm',
  betreiber: 'b',
  region: 'r',
  anreise: 'a',
  startName: 's',
  arten: [],
  stationen: [],
  amenities: [],
);

Future<void> _openSheet(
  WidgetTester tester, {
  required _FakePicker picker,
  required _HangingUploader uploader,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        imageUploadServiceProvider.overrideWithValue(uploader),
        currentProfileProvider.overrideWith((ref) async => null),
        trailsProvider.overrideWith((ref) async => [_trail()]),
        trailImagesProvider('heide-erlebnisweg').overrideWith((ref) => []),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: SingleChildScrollView(
                        child: ImageUploadSheet(
                          trail: _trail(),
                          picker: picker,
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Oli');
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
}

void main() {
  final photo = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'a.jpg');

  testWidgets('Picker-Abbruch: Sheet bleibt, kein Job, keine Meldung', (
    tester,
  ) async {
    final picker = _FakePicker(null);
    final uploader = _HangingUploader();
    await _openSheet(tester, picker: picker, uploader: uploader);

    await tester.tap(find.text('Galerie'));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(uploader.calls, 0);
    expect(find.byType(ImageUploadSheet), findsOneWidget);
    expect(find.textContaining('Danke'), findsNothing);
    expect(find.textContaining('Foto wird'), findsNothing);
  });

  testWidgets('Erfolg: Sheet bleibt offen, Credit bleibt, Buttons frei', (
    tester,
  ) async {
    final picker = _FakePicker(photo);
    final uploader = _HangingUploader();
    await _openSheet(tester, picker: picker, uploader: uploader);

    await tester.tap(find.text('Galerie'));
    await tester.pump();
    await tester.pump();

    // Job laeuft, Sheet zeigt Phase statt Picker-Spinner
    expect(uploader.calls, 1);
    expect(find.text('Foto wird verarbeitet …'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
      reason: 'zweites Foto waehrend des Uploads erlaubt',
    );

    uploader.done.complete();
    await tester.pumpAndSettle();

    expect(find.byType(ImageUploadSheet), findsOneWidget);
    expect(find.textContaining('Danke'), findsOneWidget);
    expect(find.text('Oli'), findsOneWidget);
    expect(find.text('Foto wird verarbeitet …'), findsNothing);
  });

  testWidgets('Schliessen waehrend des Uploads bricht den Job nicht ab', (
    tester,
  ) async {
    final picker = _FakePicker(photo);
    final uploader = _HangingUploader();
    await _openSheet(tester, picker: picker, uploader: uploader);

    await tester.tap(find.text('Galerie'));
    await tester.pump();
    await tester.pump();
    expect(uploader.calls, 1);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ImageUploadSheet), findsNothing);

    // Kein Fehler beim Abschluss ohne Sheet (Listener ist weg)
    uploader.done.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
