import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repository.dart';
import '../models/place.dart';
import '../theme.dart';
import '../utils/image_utils.dart';
import '../utils/transitions.dart';
import 'place_edit_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final String placeId;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Place? get _place {
    final i = repo.items.indexWhere((p) => p.id == widget.placeId);
    return i >= 0 ? repo.items[i] : null;
  }

  void _goToPage(int i, int count) {
    final t = i.clamp(0, count - 1);
    _pageCtrl.animateToPage(t,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Widget _navArrow(IconData icon, bool enabled, VoidCallback onTap) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNavigation(Place p) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMap(Place p) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openVideo(Place p) async {
    final raw = p.videoUrl!.trim();
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(Place p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usunąć miejsce?'),
        content: Text('„${p.title}" zniknie z katalogu. Tej operacji nie '
            'można cofnąć.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.delete(p.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final p = _place;
        if (p == null) return const SizedBox.shrink();
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _imageHeader(p),
              SliverToBoxAdapter(child: _body(p)),
            ],
          ),
        );
      },
    );
  }

  Widget _imageHeader(Place p) {
    final images = p.images;
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.of(context)
              .push(smoothRoute(PlaceEditScreen(existing: p))),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _confirmDelete(p),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'place-image-${p.id}',
          child: images.isEmpty
              ? Container(
                  color: AppColors.seed.withValues(alpha: 0.15),
                  child: const Icon(Icons.image_outlined,
                      size: 72, color: AppColors.seed),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => Image.memory(
                        decodeDataUrl(images[i]),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black38, Colors.transparent],
                          stops: [0, 0.3],
                        ),
                      ),
                    ),
                    if (images.length > 1) ...[
                      // Licznik „1 / N".
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.photo_library_rounded,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text('${_page + 1} / ${images.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                      // Strzałki (działają też myszą na desktopie).
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 40,
                        child: Center(
                          child: _navArrow(
                              Icons.chevron_left_rounded,
                              _page > 0,
                              () => _goToPage(_page - 1, images.length)),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 40,
                        child: Center(
                          child: _navArrow(
                              Icons.chevron_right_rounded,
                              _page < images.length - 1,
                              () => _goToPage(_page + 1, images.length)),
                        ),
                      ),
                      // Klikalne kropki.
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (i) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _goToPage(i, images.length),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 6),
                                width: i == _page ? 22 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _page
                                      ? Colors.white
                                      : Colors.white60,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _body(Place p) {
    return Container(
      transform: Matrix4.translationValues(0, -24, 0),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.hasCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in p.leafLabels)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.seed.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              color: AppColors.seed,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5)),
                    ),
                ],
              ),
            ),
          Text(p.title, style: Theme.of(context).textTheme.displaySmall),
          if (p.address != null && p.address!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _addressBlock(p.address!),
            ),
          if (p.hasVideo) ...[
            const SizedBox(height: 22),
            _videoCard(p),
          ],
          if (p.description.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Praktyczne info',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _notesPanel(p.description),
          ],
          if (p.hasLocation) ...[
            const SizedBox(height: 24),
            Text('Lokalizacja',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _mapPreview(p),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openNavigation(p),
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Pokaż trasę (Google Maps)'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: () => _openMap(p),
                  icon: const Icon(Icons.open_in_new_rounded),
                  tooltip: 'Otwórz w Mapach Google',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Adres pogrupowany w 2–3 logiczne linie, większymi i ciemnymi literami.
  Widget _addressBlock(String address) {
    final lines = _addressLines(address);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.place_rounded, size: 20, color: AppColors.seed),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(lines[i],
                      style: TextStyle(
                        color: i == 0
                            ? AppColors.ink
                            : const Color(0xFF333B37),
                        fontWeight:
                            i == 0 ? FontWeight.w700 : FontWeight.w500,
                        fontSize: i == 0 ? 17 : 14.5,
                        height: 1.35,
                      )),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Zwraca 2–3 linie adresu. Nowy format jest rozdzielony '\n'; stary, długi
  /// ciąg z geokodera grupujemy heurystycznie.
  List<String> _addressLines(String address) {
    if (address.contains('\n')) {
      return address
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length <= 3) return parts;
    // L1 = ulica/nazwa; L2 = kod + miasto; L3 = kraj/województwo.
    final pc = RegExp(r'\d{2}-\d{3}');
    final pcIdx = parts.indexWhere((e) => pc.hasMatch(e));
    final l1 = parts.first;
    final l2 = pcIdx >= 0
        ? [
            parts[pcIdx],
            if (pcIdx + 1 < parts.length) parts[pcIdx + 1],
          ].join(' ')
        : parts[1];
    final l3 = parts.last;
    return [l1, l2, l3];
  }

  /// Notatki: każda linia jako punkt w eleganckim panelu.
  Widget _notesPanel(String text) {
    final items = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(items[i],
                        style: const TextStyle(
                            fontSize: 15, height: 1.5, color: AppColors.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoCard(Place p) {
    final (label, icon, color) = _videoSource(p.videoUrl!);
    final yt = _youTubeId(p.videoUrl!);
    return GestureDetector(
      onTap: () => _openVideo(p),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: const Color(0xFF14141A),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: yt != null
                        ? Image.network(
                            'https://img.youtube.com/vi/$yt/hqdefault.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: color.withValues(alpha: 0.25)),
                          )
                        : Container(color: color.withValues(alpha: 0.22)),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: softShadow,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.ink, size: 34),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Obejrzyj rolkę',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                    const Icon(Icons.open_in_new_rounded,
                        color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// (etykieta, ikona, kolor) na podstawie domeny linku.
  (String, IconData, Color) _videoSource(String url) {
    final u = url.toLowerCase();
    if (u.contains('tiktok')) {
      return ('TikTok', Icons.music_note_rounded, const Color(0xFF010101));
    }
    if (u.contains('instagram') || u.contains('instagr.am')) {
      return ('Instagram', Icons.camera_alt_rounded, const Color(0xFFC13584));
    }
    if (u.contains('youtube') || u.contains('youtu.be')) {
      return ('YouTube', Icons.smart_display_rounded, const Color(0xFFCC0000));
    }
    if (u.contains('facebook') || u.contains('fb.watch')) {
      return ('Facebook', Icons.facebook_rounded, const Color(0xFF1877F2));
    }
    return ('Wideo', Icons.play_circle_outline_rounded, AppColors.accent);
  }

  String? _youTubeId(String url) {
    final m = RegExp(
            r'(?:youtube\.com\/(?:watch\?v=|shorts\/|embed\/)|youtu\.be\/)([A-Za-z0-9_-]{11})')
        .firstMatch(url);
    return m?.group(1);
  }

  Widget _mapPreview(Place p) {
    final point = LatLng(p.lat!, p.lng!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bczerkawski.miejscownik',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: point,
                    width: 46,
                    height: 46,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on,
                        color: AppColors.accent, size: 44),
                  ),
                ]),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openMap(p),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Większa mapa',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: AppColors.seed)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
