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
                    if (images.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 22 : 7,
                              height: 7,
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
          if (p.categoryPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < p.categoryPath.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.seed.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(p.categoryPath[i],
                          style: const TextStyle(
                              color: AppColors.seed,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5)),
                    ),
                ],
              ),
            ),
          Text(p.title, style: Theme.of(context).textTheme.displaySmall),
          if (p.address != null && p.address!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_rounded,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(p.address!,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.35)),
                  ),
                ],
              ),
            ),
          if (p.hasVideo) ...[
            const SizedBox(height: 20),
            _videoTile(p),
          ],
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Notatki',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(p.description,
                style: const TextStyle(
                    fontSize: 15.5, height: 1.55, color: AppColors.ink)),
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
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Nawiguj'),
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

  Widget _videoTile(Place p) {
    return GestureDetector(
      onTap: () => _openVideo(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2A33), Color(0xFF14141A)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              child:
                  const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Obejrzyj wideo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  SizedBox(height: 2),
                  Text('Rolka / film o tym miejscu',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
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
