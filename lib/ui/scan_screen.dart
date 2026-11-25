import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../app_store.dart';
import '../services/receipt_scanner.dart';
import 'components.dart';
import 'receipt_review_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _busy = false;
  String? _error;
  final _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recover());
  }

  Future<void> _recover() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.files?.isNotEmpty ?? false) {
        await _recognize(lost.files!.first.path);
      } else if (lost.exception != null && mounted) {
        setState(
          () => _error =
              'Foto sebelumnya belum dapat dipulihkan. Pilih ulang foto struk.',
        );
      }
    } catch (_) {
      /* Picking a new photo remains available. */
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (image != null && mounted) await _recognize(image.path);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Foto belum dapat dibuka. Periksa izin kamera atau pilih foto dari galeri.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recognize(String path) async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = await ReceiptScanner().scan(path);
      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReceiptReviewScreen(store: widget.store, draft: draft),
        ),
      );
      if (saved == true && mounted) Navigator.pop(context);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'Pembacaan struk gagal (${error.code}). Pilih ulang foto JPG/PNG atau ambil foto baru.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Struk belum berhasil dibaca. Coba foto JPG/PNG yang lebih terang, tajam, dan tegak.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan struk')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const Panel(
                color: brandTint,
                padding: 32,
                child: Column(
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 60,
                      color: brand,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Scan struk belanja',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ambil total, tanggal, dan nama toko dari foto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (kIsWeb) ...[
                const Panel(
                  child: Text(
                    'Scan struk tersedia di aplikasi Android. Di pratinjau browser, Anda bisa mencoba pencatatan manual, kategori, saldo, dan laporan.',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _busy || kIsWeb
                    ? null
                    : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Ambil foto struk'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy || kIsWeb
                    ? null
                    : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Pilih dari galeri'),
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Membaca struk…'),
                    ],
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(_error!, style: const TextStyle(color: coral)),
                ),
              const SizedBox(height: 24),
              const Text(
                'Gunakan foto terang dan tajam. Pastikan total serta tanggal terlihat.',
                style: TextStyle(color: muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
