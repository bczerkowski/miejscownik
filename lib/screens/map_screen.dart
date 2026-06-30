import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/repository.dart';
import '../models/place.dart';
import '../theme.dart';
import '../utils/image_utils.dart';
import '../utils/transitions.dart';
import 'place_detail_screen.dart';

/// Zakładka „Mapa" – wszystkie miejsca z lokalizacją jako pinezki.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      ),
      body: AnimatedBuilder(
        animation: repo,
        builder: (context, _) {
          final located = repo.items.where((p) => p.hasLocation).toList();
          if (located.isEmpty) return _empty(context);

          // Dopasuj widok tak, by objąć wszystkie pinezki.
          final pts = located.map((p) => LatLng(p.lat!, p.lng!)).toList();
          final bounds = LatLngBounds.fromPoints(pts);

          return FlutterMap(
            options: MapOptions(
              initialCameraFit: pts.length == 1
                  ? null
                  : CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(60),
                    ),
              initialCenter: pts.first,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bczerkawski.miejscownik',
              ),
              MarkerLayer(
                markers: [
                  for (final p in located)
                    Marker(
                      point: LatLng(p.lat!, p.lng!),
                      width: 54,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: _Pin(
                        place: p,
                        onTap: () => Navigator.of(context).push(
                            smoothRoute(PlaceDetailScreen(placeId: p.id))),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.seed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map_outlined,
                  size: 46, color: AppColors.seed),
            ),
            const SizedBox(height: 20),
            Text('Brak miejsc na mapie',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Dodaj miejsce z pinezką, a pojawi się tutaj na wspólnej mapie.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cover = place.cover;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 3),
              boxShadow: softShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: cover != null
                ? Image.memory(decodeDataUrl(cover),
                    fit: BoxFit.cover, gaplessPlayback: true)
                : const Icon(Icons.place, color: AppColors.accent, size: 22),
          ),
          // Mały „dziób" pinezki.
          Transform.translate(
            offset: const Offset(0, -3),
            child: Container(
              width: 3,
              height: 12,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
