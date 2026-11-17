import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/features/auth/presentation/account_contributions_tab.dart';
import 'package:lehrpfad_app/features/auth/presentation/account_panel.dart';
import 'package:lehrpfad_app/features/community/data/community_providers.dart';
import 'package:lehrpfad_app/features/community/data/photos_seen.dart';
import 'package:lehrpfad_app/features/community/data/supabase_images_repository.dart';
import 'package:lehrpfad_app/features/community/domain/trail_comment.dart';
import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/features/community/presentation/my_contributions_support.dart';
import 'package:lehrpfad_app/features/report/data/report_providers.dart';
import 'package:lehrpfad_app/features/report/domain/report_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

TrailImage _image(
  String id,
  TrailImageStatus status, {
  DateTime? decidedAt,
  RejectReason? reason,
  int day = 1,
}) => TrailImage(
  id: id,
  trailId: 'trail-1',
  stationId: null,
  uploaderId: 'u1',
  source: TrailImageSource.user,
  status: status,
  credit: 'Ich',
  width: 400,
  height: 300,
  mimeType: 'image/webp',
  thumbBytes: 1,
  smallBytes: 1,
  mediumBytes: 1,
  createdAt: DateTime(2026, 11, day),
  isMine: true,
  thumbUrl: '',
  smallUrl: '',
  mediumUrl: '',
  decidedAt: decidedAt,
  rejectReason: reason,
);

class _NoDrafts extends ReportDraftsNotifier {
  @override
  Future<List<ReportDraft>> build() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RejectReason', () {
    test('parse kennt alle DB-Werte, unbekannt und null sind null', () {
      for (final r in RejectReason.values) {
        expect(RejectReason.parse(r.dbValue), r);
      }
      expect(RejectReason.parse('quatsch'), isNull);
      expect(RejectReason.parse(null), isNull);
    });
  });

  group('Zeilenzuordnung', () {
    late SupabaseImagesRepository repo;
    setUp(() {
      repo = SupabaseImagesRepository(
        SupabaseClient('http://localhost:54321', 'anon-key'),
      );
    });

    Map<String, dynamic> row(Map<String, dynamic> extra) => {
      'id': 'img-1',
      'trail_id': 'trail-1',
      'station_id': null,
      'uploader_id': 'u1',
      'source': 'user',
      'status': 'rejected',
      'credit': 'Ich',
      'created_at': '2026-11-01T10:00:00Z',
      ...extra,
    };

    test('reject_reason und decided_at kommen an', () {
      final image = repo.rowToImage(
        row({'reject_reason': 'blurry', 'decided_at': '2026-11-02T08:00:00Z'}),
      );
      expect(image.isRejected, isTrue);
      expect(image.rejectReason, RejectReason.blurry);
      expect(image.decidedAt, DateTime.utc(2026, 11, 2, 8));
    });

    test('ohne Migrationsspalten bleiben die Felder null', () {
      final image = repo.rowToImage(row({'status': 'pending'}));
      expect(image.rejectReason, isNull);
      expect(image.decidedAt, isNull);
    });
  });

  group('Hilfen', () {
    test(
      'prioritized: abgelehnt, in Prüfung, freigegeben, je neueste zuerst',
      () {
        final list = [
          _image('a1', TrailImageStatus.approved),
          _image('p1', TrailImageStatus.pending),
          _image('r1', TrailImageStatus.rejected),
          _image('a2', TrailImageStatus.approved),
          _image('r2', TrailImageStatus.rejected),
        ];
        expect(prioritized(list).map((i) => i.id), [
          'r1',
          'r2',
          'p1',
          'a1',
          'a2',
        ]);
      },
    );

    test('statsLine lässt Nullen weg', () {
      expect(statsLine(ContributionStats.empty), 'Noch keine Beiträge');
      expect(
        statsLine(
          const ContributionStats(
            photos: 12,
            pending: 3,
            approved: 9,
            comments: 5,
          ),
        ),
        '12 Fotos · 3 in Prüfung · 5 Kommentare',
      );
      expect(
        statsLine(const ContributionStats(photos: 1, comments: 1)),
        '1 Foto · 1 Kommentar',
      );
    });
  });

  group('Ungesehen', () {
    ProviderContainer container(List<TrailImage> images) {
      final c = ProviderContainer(
        overrides: [myImagesProvider.overrideWith((ref) async => images)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('ohne Zeitstempel zählt jede Entscheidung', () async {
      final c = container([
        _image(
          'a',
          TrailImageStatus.approved,
          decidedAt: DateTime(2026, 11, 5),
        ),
        _image('p', TrailImageStatus.pending),
      ]);
      await c.read(photosSeenAtProvider.future);
      await c.read(myImagesProvider.future);
      expect(c.read(unseenDecisionImagesProvider).map((i) => i.id), ['a']);
    });

    test(
      'markSeen leert die Liste, spätere Entscheidung kommt wieder',
      () async {
        final later = DateTime.now().add(const Duration(days: 1));
        final c = container([
          _image(
            'a',
            TrailImageStatus.approved,
            decidedAt: DateTime(2026, 11, 5),
          ),
          _image('b', TrailImageStatus.rejected, decidedAt: later),
        ]);
        await c.read(photosSeenAtProvider.future);
        await c.read(myImagesProvider.future);
        expect(c.read(unseenDecisionImagesProvider), hasLength(2));

        await c.read(photosSeenAtProvider.notifier).markSeen();
        expect(c.read(unseenDecisionImagesProvider).map((i) => i.id), ['b']);
      },
    );
  });

  group('Beiträge-Tab', () {
    Future<void> pump(
      WidgetTester tester, {
      required Widget child,
      List<TrailImage> images = const [],
      List<TrailComment> comments = const [],
    }) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myImagesProvider.overrideWith((ref) async => images),
            myCommentsProvider.overrideWith((ref) async => comments),
            reportDraftsProvider.overrideWith(_NoDrafts.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Fotos zeigen Status, Neu-Punkt und „Alle“ ab 7', (
      tester,
    ) async {
      final images = [
        _image('p', TrailImageStatus.pending, day: 7),
        _image(
          'r',
          TrailImageStatus.rejected,
          day: 6,
          reason: RejectReason.blurry,
          decidedAt: DateTime(2026, 11, 8),
        ),
        for (var i = 0; i < 5; i++)
          _image('a$i', TrailImageStatus.approved, day: i + 1),
      ];
      await pump(
        tester,
        images: images,
        child: const PhotosBlock(fresh: {'r'}),
      );

      expect(find.text('Meine Fotos'), findsOneWidget);
      expect(find.text('Alle (7)'), findsOneWidget);
      expect(find.text('Abgelehnt'), findsOneWidget);
      expect(find.text('In Prüfung'), findsOneWidget);
      // 6 Vorschauen, der siebte Eintrag steckt hinter „Alle“.
      expect(find.text('Freigegeben'), findsNWidgets(4));
      expect(find.byKey(const ValueKey('photo-new')), findsOneWidget);
    });

    testWidgets('leer: Hinweis und Upload-Angebot', (tester) async {
      await pump(tester, child: const PhotosBlock(fresh: {}));
      expect(find.text('Erstes Foto hochladen'), findsOneWidget);
      expect(find.textContaining('Alle ('), findsNothing);
    });

    testWidgets('Kommentare: nur die letzten drei, Rest hinter „Alle“', (
      tester,
    ) async {
      final comments = [
        for (var i = 0; i < 5; i++)
          TrailComment(
            id: i,
            trailId: 'trail-1',
            authorName: 'Ich',
            text: 'Kommentar $i',
            createdAt: DateTime(2026, 11, 10 - i),
            isMine: true,
          ),
      ];
      await pump(tester, comments: comments, child: const CommentsBlock());
      expect(find.text('Kommentar 0'), findsOneWidget);
      expect(find.text('Kommentar 2'), findsOneWidget);
      expect(find.text('Kommentar 3'), findsNothing);
      expect(find.text('Alle (5)'), findsOneWidget);
    });

    testWidgets('ohne Serververbindung: Hinweis statt leerer Blöcke', (
      tester,
    ) async {
      await pump(
        tester,
        child: const SizedBox(height: 1200, child: AccountContributionsTab()),
      );
      expect(find.textContaining('mit Serververbindung'), findsOneWidget);
      expect(find.text('Meine Fotos'), findsNothing);
      expect(find.text('Meldungen'), findsWidgets);
    });
  });
}
