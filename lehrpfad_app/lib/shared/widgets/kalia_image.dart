import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thumbhash/thumbhash.dart' as thumbhash;

import '../../app/theme/app_colors.dart';
import '../../features/community/domain/trail_image.dart';
import '../../features/offline/offline.dart';
import '../images/image_variants.dart';
import 'kalia_file_image.dart';

/// Ein Bild. Der Aufrufer nennt den Slot: Liste `thumb`, Hero `small`,
/// Zoom `medium`. Dekodiert wird in der gerenderten Breite, nicht in der
/// vollen Datei.
class KaliaImage extends ConsumerStatefulWidget {
  const KaliaImage({
    super.key,
    required this.slot,
    this.trailId,
    this.imageId,
    this.thumbhash = '',
    this.dominantColor = '',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final TrailImageVariant slot;
  final String? trailId;
  final String? imageId;
  final String thumbhash;
  final String dominantColor;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  ConsumerState<KaliaImage> createState() => _KaliaImageState();
}

class _KaliaImageState extends ConsumerState<KaliaImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  ui.Image? _hash;
  bool _sync = true;
  int _retries = 0;
  int _sourceIndex = -1;
  late TrailImageVariant _slot;
  List<ImageSource> _sources = const [];
  Stopwatch? _watch;
  String _sourceLabel = '';

  int _gen = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _slot = widget.slot;
    _decodeHash();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _schedule(widget.slot);
  }

  @override
  void didUpdateWidget(KaliaImage old) {
    super.didUpdateWidget(old);
    if (old.thumbhash != widget.thumbhash) _decodeHash();
    if (old.trailId != widget.trailId ||
        old.imageId != widget.imageId ||
        old.slot != widget.slot ||
        old.width != widget.width) {
      _retries = 0;
      _schedule(widget.slot);
    }
  }

  @override
  void dispose() {
    _stop();
    _image?.dispose();
    _hash?.dispose();
    super.dispose();
  }

  void _decodeHash() {
    final raw = widget.thumbhash.trim();
    if (raw.isEmpty) return;
    try {
      final decoded = thumbhash.thumbHashToRGBA(base64Decode(raw));
      ui.decodeImageFromPixels(
        decoded.rgba,
        decoded.width,
        decoded.height,
        ui.PixelFormat.rgba8888,
        (image) {
          if (!mounted) {
            image.dispose();
            return;
          }
          setState(() {
            _hash?.dispose();
            _hash = image;
          });
        },
      );
    } catch (_) {}
  }

  void _schedule(TrailImageVariant slot) {
    final gen = ++_gen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _gen) return;
      _arm(slot);
    });
  }

  void _arm(TrailImageVariant slot) {
    _stop();
    _slot = slot;
    _sources = _sourcesFor(slot);
    _sourceIndex = -1;
    _watch = Stopwatch()..start();
    _advance();
  }

  List<ImageSource> _sourcesFor(TrailImageVariant slot) {
    final trailId = widget.trailId;
    final imageId = widget.imageId;
    if (trailId == null || imageId == null) return const [];
    return ref
        .read(assetResolverProvider)
        .image(
          ImageRef(trailId: trailId, imageId: imageId),
          slot,
          online: ref.read(isOnlineProvider),
        );
  }

  void _advance() {
    _stop();
    final next = _sourceIndex + 1;
    if (next >= _sources.length) {
      _failSlot();
      return;
    }
    _sourceIndex = next;
    final source = _sources[next];
    _sourceLabel = _label(source);
    final stream = _provider(
      source,
    ).resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, sync) {
        if (!mounted) return;
        final clone = info.image.clone();
        final ms = _watch?.elapsedMilliseconds ?? 0;
        if (kDebugMode) {
          debugPrint(
            'KaliaImage ${widget.trailId ?? '-'} ${_slot.name} '
            '$_sourceLabel ${clone.width}px ${ms}ms',
          );
        }
        setState(() {
          _image?.dispose();
          _image = clone;
          _sync = sync;
        });
      },
      onError: (error, stack) {
        if (!mounted) return;
        _advance();
      },
    );
    _stream = stream;
    stream.addListener(_listener!);
  }

  void _failSlot() {
    if (_retries < 1 && _sources.isNotEmpty) {
      _retries++;
      _sourceIndex = -1;
      _advance();
      return;
    }
    final next = switch (_slot) {
      TrailImageVariant.medium => TrailImageVariant.small,
      TrailImageVariant.small => TrailImageVariant.thumb,
      TrailImageVariant.thumb => null,
    };
    if (next == null) return;
    _retries = 0;
    _arm(next);
  }

  ImageProvider _provider(ImageSource source) {
    final cacheWidth = _cacheWidth(_slot);
    return switch (source) {
      ImageSourceFile(:final path) => kaliaFileImage(path, cacheWidth),
      ImageSourceAsset(:final path) => ResizeImage(
        AssetImage(path),
        width: cacheWidth,
      ),
      ImageSourceNetwork(:final url) => CachedNetworkImageProvider(
        url,
        maxWidth: cacheWidth,
      ),
    };
  }

  int _cacheWidth(TrailImageVariant slot) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = widget.width;
    final logical = (width != null && width.isFinite && width > 0)
        ? width
        : MediaQuery.sizeOf(context).width;
    final px = (logical * dpr).round();
    final cap = kVariantMaxEdge[slot]!;
    if (px < 1) return cap;
    return px > cap ? cap : px;
  }

  String _label(ImageSource source) => switch (source) {
    ImageSourceFile() => 'offline',
    ImageSourceAsset(:final path) =>
      path.contains('/thumbs/') ? 'seed' : 'asset',
    ImageSourceNetwork() => 'netz',
  };

  void _stop() {
    final listener = _listener;
    final stream = _stream;
    if (listener != null && stream != null) {
      stream.removeListener(listener);
    }
    _listener = null;
    _stream = null;
  }

  Color get _color {
    final raw = widget.dominantColor.trim();
    if (raw.length == 7 && raw.startsWith('#')) {
      final value = int.tryParse(raw.substring(1), radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return AppColors.n100;
  }

  @override
  Widget build(BuildContext context) {
    final photo = _image;
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: _color),
        if (_hash != null)
          RawImage(
            image: _hash,
            fit: widget.fit,
            alignment: widget.alignment,
            width: double.infinity,
            height: double.infinity,
          ),
        if (widget.imageId == null)
          Image.asset(
            AssetResolver.placeholderAsset(widget.slot),
            fit: widget.fit,
            alignment: widget.alignment,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        if (widget.slot == TrailImageVariant.small && widget.imageId != null)
          KaliaImage(
            trailId: widget.trailId,
            imageId: widget.imageId,
            slot: TrailImageVariant.thumb,
            thumbhash: widget.thumbhash,
            dominantColor: widget.dominantColor,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            alignment: widget.alignment,
          ),
        if (photo != null)
          _Appear(
            key: ValueKey('$_slot:$_sourceIndex:$_retries'),
            animate: !_sync,
            child: RawImage(
              image: photo,
              fit: widget.fit,
              alignment: widget.alignment,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.low,
            ),
          ),
      ],
    );
    final w = widget.width;
    final h = widget.height;
    if ((w != null && w.isFinite) || (h != null && h.isFinite)) {
      return SizedBox(
        width: w != null && w.isFinite ? w : null,
        height: h != null && h.isFinite ? h : null,
        child: stack,
      );
    }
    return stack;
  }
}

class _Appear extends StatefulWidget {
  const _Appear({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> {
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    _opacity = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.animate
          ? const Duration(milliseconds: 150)
          : Duration.zero,
      child: widget.child,
    );
  }
}
