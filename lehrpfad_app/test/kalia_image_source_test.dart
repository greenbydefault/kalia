import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/features/offline/models/asset_ref.dart';
import 'package:lehrpfad_app/features/offline/resolver/asset_resolver.dart';
import 'package:lehrpfad_app/features/offline/storage/file_store.dart';

void main() {
  final resolver = _Harness.resolver;

  test('small online endet nicht auf dem Seed-Thumb', () {
    final sources = resolver.image(
      const ImageRef(trailId: 'trail', imageId: 'img'),
      TrailImageVariant.small,
      online: true,
    );
    expect(sources.whereType<ImageSourceAsset>(), isEmpty);
    final urls = [
      for (final source in sources)
        if (source is ImageSourceNetwork) source.url,
    ];
    expect(urls, hasLength(2));
    expect(urls.first, endsWith('/trail/img/small.webp'));
    expect(urls.last, endsWith('/trail/img/small.avif'));
  });

  test('thumb online holt das Netz vor dem Seed-Thumb', () {
    final sources = resolver.image(
      const ImageRef(trailId: 'trail', imageId: 'img'),
      TrailImageVariant.thumb,
      online: true,
    );
    final net = sources.indexWhere((s) => s is ImageSourceNetwork);
    final seed = sources.indexWhere(
      (s) => s is ImageSourceAsset && s.path.contains('/thumbs/'),
    );
    expect(net, greaterThanOrEqualTo(0));
    expect(seed, greaterThan(net));
    expect((sources[net] as ImageSourceNetwork).url, endsWith('/thumb.webp'));
  });

  test('thumb offline bleibt beim Seed-Thumb', () {
    final sources = resolver.image(
      const ImageRef(trailId: 'trail', imageId: 'img'),
      TrailImageVariant.thumb,
      online: false,
    );
    expect(sources.whereType<ImageSourceNetwork>(), isEmpty);
    expect(sources, hasLength(1));
    expect((sources.single as ImageSourceAsset).path, endsWith('/trail.webp'));
  });
}

abstract final class _Harness {
  static final resolver = AssetResolver(
    files: const NullFileStore(),
    storageBaseUrl: 'https://example.supabase.co',
    seedThumbImages: const {'trail': 'img'},
  );
}
