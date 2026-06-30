import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../data/repository.dart';
import '../models/place.dart';
import '../services/paste_web.dart';
import '../theme.dart';
import '../utils/image_utils.dart';
import '../widgets/category_picker.dart';
import 'location_picker_screen.dart';

class PlaceEditScreen extends StatefulWidget {
  const PlaceEditScreen({super.key, this.existing});

  final Place? existing;

  @override
  State<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends State<PlaceEditScreen> {
  final _picker = ImagePicker();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();

  List<String> _images = [];
  List<List<String>> _categories = [];
  double? _lat, _lng;
  String? _address;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _videoCtrl.text = e.videoUrl ?? '';
      _images = [...e.images];
      _categories = e.categories.map((c) => [...c]).toList();
      _lat = e.lat;
      _lng = e.lng;
      _address = e.address;
    }
    // Wklejanie zdjęć ze schowka (Ctrl+V).
    enableImagePaste((dataUrl) {
      if (!mounted) return;
      setState(() => _images.add(dataUrl));
      _toast('Wklejono zdjęcie');
    });
  }

  @override
  void dispose() {
    disableImagePaste();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(imageQuality: 82);
        for (final f in files) {
          final bytes = await f.readAsBytes();
          _images.add(encodeDataUrl(bytes, mime: _mimeOf(f.name)));
        }
      } else {
        final f =
            await _picker.pickImage(source: source, imageQuality: 82);
        if (f != null) {
          final bytes = await f.readAsBytes();
          _images.add(encodeDataUrl(bytes, mime: _mimeOf(f.name)));
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      _toast('Nie udało się dodać zdjęcia');
    }
  }

  String _mimeOf(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _addCategory() async {
    final picked = await pickCategory(context, title: 'Dodaj kategorię');
    if (picked == null || picked.isEmpty) return;
    final exists = _categories.any((c) => _pathEquals(c, picked));
    if (!exists) setState(() => _categories.add(picked));
  }

  bool _pathEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _pickLocation() async {
    final initial = (_lat != null && _lng != null)
        ? PickedLocation(_lat!, _lng!, _address)
        : null;
    final res = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
          builder: (_) => LocationPickerScreen(initial: initial)),
    );
    if (res != null) {
      setState(() {
        _lat = res.lat;
        _lng = res.lng;
        _address = res.address;
      });
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast('Podaj nazwę miejsca');
      return;
    }
    final place = Place(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      description: _descCtrl.text.trim(),
      images: _images,
      videoUrl: _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
      lat: _lat,
      lng: _lng,
      address: _address,
      categories: _categories,
      createdAt:
          widget.existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    repo.upsert(place);
    Navigator.pop(context, place);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edytuj miejsce' : 'Nowe miejsce'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _photoStrip(),
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.content_paste_rounded,
                    size: 14, color: AppColors.muted),
                SizedBox(width: 6),
                Text('Możesz też wkleić zdjęcie ze schowka (Ctrl+V)',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _label('Nazwa'),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'np. Tajska knajpka na Jeziorańskiego'),
          ),
          const SizedBox(height: 20),
          _label('Kategorie'),
          _categoryPills(),
          const SizedBox(height: 20),
          _label('Lokalizacja'),
          _locationField(),
          const SizedBox(height: 20),
          _label('Opis i notatki'),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'Co warto zapamiętać o tym miejscu?'),
          ),
          const SizedBox(height: 20),
          _label('Wideo / rolka (link)'),
          TextField(
            controller: _videoCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'Wklej link z IG / TikToka / YouTube',
              prefixIcon: Icon(Icons.play_circle_outline_rounded),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(_isEdit ? 'Zapisz zmiany' : 'Dodaj do katalogu'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.ink)),
      );

  Widget _photoStrip() {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _addPhotoButton(),
          for (var i = 0; i < _images.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      decodeDataUrl(_images[i]),
                      width: 110,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.seed,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Okładka',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _addPhotoButton() {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Wybierz z galerii'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Zrób zdjęcie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      child: Container(
        width: 110,
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.seed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.seed.withValues(alpha: 0.3),
              style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.seed, size: 28),
            SizedBox(height: 8),
            Text('Dodaj zdjęcie',
                style: TextStyle(
                    color: AppColors.seed,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _categoryPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < _categories.length; i++)
          _selectedPill(_categories[i].join(' › '),
              onRemove: () => setState(() => _categories.removeAt(i))),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18, color: AppColors.seed),
          label: const Text('Dodaj kategorię'),
          onPressed: _addCategory,
          side: const BorderSide(color: AppColors.seed),
          labelStyle: const TextStyle(
              color: AppColors.seed, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _selectedPill(String text, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6, top: 7, bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.seed,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationField() {
    final has = _lat != null && _lng != null;
    return InkWell(
      onTap: _pickLocation,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(has ? Icons.place : Icons.add_location_alt_outlined,
                color: has ? AppColors.seed : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                has
                    ? (_address ??
                        '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}')
                    : 'Dodaj pinezkę na mapie',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: has ? AppColors.ink : AppColors.muted,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
