import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app_store.dart';
import '../domain/models.dart';
import '../domain/formatters.dart';
import '../services/entry_persistence.dart';
import 'components.dart';

class ReceiptReviewScreen extends StatefulWidget {
  const ReceiptReviewScreen({
    super.key,
    required this.store,
    required this.draft,
  });
  final AppStore store;
  final ReceiptDraft draft;
  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _merchant, _amount;
  DateTime? _date;
  int? _category;
  var _busy = false;
  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(text: widget.draft.merchant ?? '');
    _amount = TextEditingController(text: widget.draft.total?.toString() ?? '');
    _date = widget.draft.date;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_date == null) {
      showMessage(context, 'Pilih tanggal transaksi terlebih dahulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      await persistEntry(
        widget.store.repository,
        MoneyEntry(
          kind: EntryKind.expense,
          amount: parseRupiahInput(_amount.text)!,
          categoryId: _category!,
          date: _date!,
          merchant: _merchant.text,
        ),
        newReceiptPath: widget.draft.imagePath,
      );
      await widget.store.refresh();
      if (mounted) {
        showMessage(context, 'Transaksi tersimpan pada ${dayLabel(_date!)}');
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, friendlyError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.store.categories
        .where((c) => c.kind == EntryKind.expense)
        .toList();
    final draft = widget.draft;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Review struk')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_busy ? 'Menyimpan...' : 'Simpan transaksi'),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: incomeGreen, size: 18),
                        SizedBox(width: 8),
                        Text('Foto', style: TextStyle(color: muted)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.chevron_right, color: muted),
                        ),
                        Text(
                          'Review',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Periksa hasil scan',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Koreksi data bila perlu, lalu pilih kategori.',
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    if (draft.total == null ||
                        draft.date == null ||
                        draft.merchant == null) ...[
                      const Panel(
                        color: Color(0xFFFFF1DD),
                        child: Text(
                          'Sebagian data belum terbaca. Lengkapi kolom yang kosong; transaksi belum disimpan.',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Panel(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _merchant,
                            enabled: !_busy,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Nama toko',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Isi nama toko'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _amount,
                            enabled: !_busy,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: coral,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Total pengeluaran',
                              prefixText: 'Rp ',
                            ),
                            validator: (v) => parseRupiahInput(v ?? '') == null
                                ? 'Isi total pengeluaran yang valid'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Panel(
                      padding: 6,
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_today_outlined,
                          color: ink,
                        ),
                        title: const Text('Tanggal transaksi'),
                        subtitle: Text(
                          _date == null
                              ? 'Belum terbaca - pilih tanggal'
                              : dayLabel(_date!),
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 20),
                        onTap: _busy
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _date ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100, 12, 31),
                                );
                                if (date != null && mounted) {
                                  setState(() => _date = date);
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kategori pengeluaran',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _category = value),
                      validator: (v) =>
                          v == null ? 'Pilih kategori pengeluaran' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Foto atau hasil belum sesuai?',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.pop(context, false),
                          child: const Text('Pilih ulang'),
                        ),
                      ],
                    ),
                    if (draft.imagePath != null)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Lihat foto struk'),
                        children: [
                          Image.file(
                            File(draft.imagePath!),
                            height: 260,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Text('Foto tidak dapat ditampilkan.'),
                          ),
                        ],
                      ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Teks hasil pembacaan'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SelectableText(
                            draft.rawText.isEmpty
                                ? 'Tidak ada teks terbaca. Lengkapi data secara manual.'
                                : draft.rawText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
