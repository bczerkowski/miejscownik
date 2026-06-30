import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../services/backup_web.dart';
import '../services/sync_service.dart';
import '../theme.dart';

/// Synchronizacja w chmurze (logowanie/rejestracja, status) + kopia JSON.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<bool> _askConflict(int localPlaces) async {
    if (!mounted) return true;
    final keep = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Znaleziono dwa katalogi'),
        content: Text(
            'To urządzenie ma $localPlaces ${_miejsc(localPlaces)}, a Twoje '
            'konto ma już zapisany katalog w chmurze.\n\nKtóry zostawić? '
            'Drugi zostanie zastąpiony.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Wyślij TO urządzenie'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Użyj chmury'),
          ),
        ],
      ),
    );
    return keep ?? true;
  }

  String _miejsc(int n) {
    if (n == 1) return 'miejsce';
    final mod10 = n % 10, mod100 = n % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'miejsca';
    }
    return 'miejsc';
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    sync.conflictResolver = _askConflict;
    try {
      await action();
    } catch (e) {
      _error = e is String
          ? e
          : 'Nie udało się zalogować. Sprawdź e-mail/hasło i spróbuj ponownie.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => sync.signIn(_email.text, _password.text);

  Future<void> _signUp() async {
    if (_password.text.length < 6) {
      throw 'Hasło musi mieć co najmniej 6 znaków.';
    }
    await sync.signUp(_email.text, _password.text);
  }

  Future<void> _exportBackup() async {
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    downloadText('miejscownik-backup-$stamp.json', repo.exportData());
    _toast('Pobrano kopię zapasową');
  }

  Future<void> _importBackup() async {
    final text = await pickTextFile();
    if (text == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wczytać kopię?'),
        content: const Text(
            'Spowoduje to zastąpienie bieżącej zawartości katalogu danymi '
            'z pliku. Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Wczytaj')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.importData(text);
      _toast('Wczytano kopię zapasową');
    } catch (_) {
      _toast('Niepoprawny plik kopii');
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(
        animation: sync,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    sync.signedIn ? _signedIn() : _signedOut(),
                    const SizedBox(height: 28),
                    _backupSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _signedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synchronizuj katalog między urządzeniami',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text(
          'Zaloguj się (lub załóż konto), aby mieć ten sam katalog na '
          'komputerze i telefonie. Zmiany synchronizują się automatycznie.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Hasło'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBEAE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFB3261E), size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFB3261E), fontSize: 13.5))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : () => _run(_signIn),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Zaloguj się'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _busy ? null : () => _run(_signUp),
          child: const Text('Załóż nowe konto'),
        ),
        const SizedBox(height: 14),
        const Text(
          'Użyj dowolnego e-maila i wybranego hasła. Katalog jest prywatny dla '
          'Twojego konta. Możesz użyć tego samego konta co w innych aplikacjach.',
          style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _signedIn() {
    final (icon, label, color) = _statusBits();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_done_outlined, color: AppColors.seed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(sync.email ?? 'Zalogowano',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
                    if (sync.lastSyncedAt != null)
                      Text('Ostatnio: ${_ago(sync.lastSyncedAt!)}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12.5)),
                    if (sync.message != null && sync.state == SyncState.error)
                      Text(sync.message!,
                          style: const TextStyle(
                              color: Color(0xFFB3261E), fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Katalog synchronizuje się automatycznie przy każdej zmianie. Edycje '
          'z jednego urządzenia pojawiają się na drugim w ~15 sekund (online).',
          style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => sync.pullNow(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Synchronizuj teraz'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => sync.signOut(),
          icon: const Icon(Icons.logout, size: 18),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E)),
          label: const Text('Wyloguj się'),
        ),
      ],
    );
  }

  Widget _backupSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download_outlined, color: AppColors.muted),
              const SizedBox(width: 10),
              Text('Kopia zapasowa (JSON)',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Niezależnie od chmury możesz pobrać cały katalog do pliku i wczytać '
            'go z powrotem (ręczny backup / przeniesienie).',
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportBackup,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Eksportuj'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importBackup,
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Importuj'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _statusBits() {
    switch (sync.state) {
      case SyncState.syncing:
        return (Icons.sync, 'Synchronizuję…', AppColors.accent);
      case SyncState.synced:
        return (Icons.check_circle_outline, 'Zsynchronizowano',
            const Color(0xFF2E7D32));
      case SyncState.error:
        return (Icons.error_outline, 'Problem z synchronizacją',
            const Color(0xFFB3261E));
      case SyncState.offline:
        return (Icons.cloud_off_outlined, 'Offline', AppColors.muted);
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'przed chwilą';
    if (d.inMinutes < 60) return '${d.inMinutes} min temu';
    if (d.inHours < 24) return '${d.inHours} godz. temu';
    return '${d.inDays} dni temu';
  }
}
