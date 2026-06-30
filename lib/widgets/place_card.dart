import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme.dart';
import '../utils/image_utils.dart';

/// Duża, content-first karta miejsca dla widoku głównego.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cover = place.cover;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'place-image-${place.id}',
                child: cover != null
                    ? Image.memory(decodeDataUrl(cover), fit: BoxFit.cover,
                        gaplessPlayback: true)
                    : Container(
                        color: AppColors.seed.withValues(alpha: 0.12),
                        child: const Icon(Icons.image_outlined,
                            size: 56, color: AppColors.seed),
                      ),
              ),
              // Gradient dla czytelności tekstu.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54, Colors.black87],
                    stops: [0.45, 0.78, 1.0],
                  ),
                ),
              ),
              if (place.hasVideo)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _badge(Icons.play_arrow_rounded, 'Wideo'),
                ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (place.categoryPath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _chip(place.categoryPath.join('  ·  ')),
                      ),
                    Text(
                      place.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    if (place.address != null && place.address!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded,
                                size: 15, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
      );

  Widget _badge(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}
