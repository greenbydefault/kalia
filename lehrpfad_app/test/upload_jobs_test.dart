import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/community/data/community_providers.dart';
import 'package:lehrpfad_app/features/community/data/image_upload_service.dart';
import 'package:lehrpfad_app/features/community/data/upload_jobs.dart';

/// Fake-Uploader: jeder Aufruf haengt an einem eigenen Completer.
class FakeUploader implements ImageUploader {
  final calls = <Completer<void>>[];

  @override
  Future<void> upload({
    required String trailId,
    required int? stationId,
    required String credit,
    required Uint8List bytes,
    void Function(UploadPhase phase)? onPhase,
  }) {
    final c = Completer<void>();
    calls.add(c);
    onPhase?.call(UploadPhase.verarbeiten);
    return c.future.then((_) => onPhase?.call(UploadPhase.hochladen));
  }
}

/// Broadcast-Streams liefern asynchron; ein Event-Loop-Tick abwarten.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeUploader uploader;
  late ProviderContainer container;
  var imageBuilds = 0;

  setUp(() {
    uploader = FakeUploader();
    imageBuilds = 0;
    container = ProviderContainer(
      overrides: [
        imageUploadServiceProvider.overrideWithValue(uploader),
        trailImagesProvider('t1').overrideWith((ref) {
          imageBuilds++;
          return const [];
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> start({String trailId = 't1'}) => container
      .read(uploadJobsProvider.notifier)
      .start(
        trailId: trailId,
        stationId: null,
        credit: 'Ich',
        bytes: Uint8List(0),
      );

  test('zwei Fotos laufen parallel, jedes liefert ein Ergebnis', () async {
    final results = <UploadResult>[];
    container.read(uploadJobsProvider.notifier).results.listen(results.add);

    final a = start();
    final b = start();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(uploadJobsProvider), hasLength(2));
    expect(uploader.calls, hasLength(2));

    uploader.calls[1].complete();
    await b;
    await _flush();
    expect(container.read(uploadJobsProvider), hasLength(1));
    expect(results, hasLength(1));

    uploader.calls[0].complete();
    await a;
    await _flush();
    expect(container.read(uploadJobsProvider), isEmpty);
    expect(results.map((r) => r.success), [true, true]);
  });

  test('Ergebnis kommt auch ohne Sheet-Listener an und invalidiert', () async {
    container.listen(trailImagesProvider('t1'), (_, _) {});
    final before = imageBuilds;

    final results = <UploadResult>[];
    // Spaeter Listener = Shell-Snackbar; kein Sheet beteiligt.
    container.read(uploadJobsProvider.notifier).results.listen(results.add);

    final job = start();
    await Future<void>.delayed(Duration.zero);
    uploader.calls.single.complete();
    await job;
    await _flush();

    expect(results.single.success, isTrue);
    expect(results.single.message, contains('Danke'));
    expect(imageBuilds, greaterThan(before));
  });

  test('Fehler landet als Ergebnis, ohne Invalidierung', () async {
    container.listen(trailImagesProvider('t1'), (_, _) {});
    final before = imageBuilds;
    final results = <UploadResult>[];
    container.read(uploadJobsProvider.notifier).results.listen(results.add);

    final job = start();
    await Future<void>.delayed(Duration.zero);
    uploader.calls.single.completeError(ImageUploadException('kaputt'));
    await job;
    await _flush();

    expect(results.single.success, isFalse);
    expect(results.single.message, 'kaputt');
    expect(container.read(uploadJobsProvider), isEmpty);
    expect(imageBuilds, before);
  });

  test('Job startet in Phase verarbeiten und ist danach weg', () async {
    final job = start();
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(uploadJobsProvider).single.phase,
      UploadPhase.verarbeiten,
    );
    uploader.calls.single.complete();
    await job;
    expect(container.read(uploadJobsProvider), isEmpty);
  });
}
