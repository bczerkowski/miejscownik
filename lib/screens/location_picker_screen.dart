import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme.dart';

/// Wynik wyboru lokalizacji.
class PickedLocation {
  PickedLocation(this.lat, this.lng, this.address);
  final double lat;
  final double lng;
  final String? address;
}

/// Ekran wyboru pinezki: wyszukiwarka adresu (Nominatim) + tap na mapie.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final PickedLocation? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  LatLng _center = const LatLng(52.069, 19.480); // środek Polski
  LatLng? _pin;
  String? _address;
  List<_Suggestion> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _pin = LatLng(widget.initial!.lat, widget.initial!.lng);
      _center = _pin!;
      _address = widget.initial!.address;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(v));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '6',
        'addressdetails': '1',
        'accept-language': 'pl',
      });
      final res = await http.get(uri,
          headers: {'User-Agent': 'Miejscownik/1.0 (personal app)'});
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((e) => _Suggestion(
                  displayName: e['display_name'] as String,
                  formatted: _formatAddress(
                      e['address'] as Map<String, dynamic>?,
                      e['display_name'] as String),
                  lat: double.parse(e['lat'] as String),
                  lng: double.parse(e['lon'] as String),
                ))
            .toList();
        if (mounted) setState(() => _suggestions = list);
      }
    } catch (_) {
      // brak sieci – użytkownik wciąż może tapnąć mapę
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectSuggestion(_Suggestion s) {
    setState(() {
      _pin = LatLng(s.lat, s.lng);
      _address = s.formatted;
      _suggestions = [];
      _searchCtrl.text = s.displayName;
    });
    _mapController.move(_pin!, 15);
    FocusScope.of(context).unfocus();
  }

  Future<void> _reverseGeocode(LatLng p) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '${p.latitude}',
        'lon': '${p.longitude}',
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'pl',
      });
      final res = await http.get(uri,
          headers: {'User-Agent': 'Miejscownik/1.0 (personal app)'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() => _address = _formatAddress(
              body['address'] as Map<String, dynamic>?,
              body['display_name'] as String?));
        }
      }
    } catch (_) {/* zignoruj */}
  }

  /// Buduje zwięzły adres w 2–3 liniach (rozdzielonych '\n'):
  /// ulica + numer / kod + miasto / województwo + kraj.
  String? _formatAddress(Map<String, dynamic>? a, String? displayName) {
    if (a == null) return displayName;
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = a[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final road = pick(['road', 'pedestrian', 'footway', 'path', 'cycleway']);
    final house = pick(['house_number']);
    final name = pick(
        ['amenity', 'tourism', 'shop', 'leisure', 'building', 'attraction']);
    final postcode = pick(['postcode']);
    final city = pick(
        ['city', 'town', 'village', 'municipality', 'hamlet', 'suburb']);
    final state = pick(['state', 'region']);
    final country = pick(['country']);

    final lines = <String>[];
    // L1: ulica (+ numer). Sam numer bez ulicy pomijamy — użyjemy nazwy POI.
    final l1 = road != null ? [road, ?house].join(' ') : (name ?? '');
    if (l1.isNotEmpty) lines.add(l1);
    // L2: kod pocztowy + miejscowość.
    final l2 = [?postcode, ?city].join(' ');
    if (l2.isNotEmpty) lines.add(l2);
    // L3: województwo + kraj.
    final l3 = [?state, ?country].join(', ');
    if (l3.isNotEmpty) lines.add(l3);

    // Usuń puste i powtórzenia (np. dublujący się kraj), zachowując kolejność.
    final seen = <String>{};
    final clean = lines.where((e) => e.isNotEmpty && seen.add(e)).toList();
    return clean.isEmpty ? displayName : clean.join('\n');
  }

  void _onTapMap(TapPosition _, LatLng p) {
    setState(() {
      _pin = p;
      _address = null;
    });
    _reverseGeocode(p);
  }

  void _confirm() {
    if (_pin == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
        context, PickedLocation(_pin!.latitude, _pin!.longitude, _address));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wybierz lokalizację'),
        actions: [
          if (_pin != null)
            TextButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Gotowe'),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _pin != null ? 15 : 5.4,
              onTap: _onTapMap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bczerkawski.miejscownik',
              ),
              if (_pin != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _pin!,
                    width: 50,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on,
                        color: AppColors.accent, size: 46),
                  ),
                ]),
            ],
          ),
          // Pasek wyszukiwania.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  shadowColor: Colors.black26,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Szukaj adresu lub miejsca…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          : null,
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: softShadow,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined,
                              color: AppColors.seed),
                          title: Text(s.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5)),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Podpowiedź / wybrany adres.
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: softShadow,
              ),
              child: Row(
                children: [
                  Icon(_pin == null ? Icons.touch_app_rounded : Icons.place,
                      color: AppColors.seed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pin == null
                          ? 'Dotknij mapę, aby postawić pinezkę.'
                          : (_address ??
                              '${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  if (_pin != null)
                    FilledButton(
                        onPressed: _confirm, child: const Text('Wybierz')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestion {
  _Suggestion({
    required this.displayName,
    required this.formatted,
    required this.lat,
    required this.lng,
  });
  final String displayName;
  final String? formatted;
  final double lat;
  final double lng;
}
