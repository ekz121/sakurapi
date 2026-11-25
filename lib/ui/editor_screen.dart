import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../app_store.dart';
import '../domain/formatters.dart';
import '../domain/models.dart';
import 'components.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.store, this.entry, this.draft});
  final AppStore store;
  final MoneyEntry? entry;
  final ReceiptDraft? draft;
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _amount, _merchant, _note;
  late EntryKind _kind;
  late DateTime _date;
  int? _categoryId;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    final draft = widget.draft;
    _amount = TextEditingController(
      text: (entry?.amount ?? draft?.total)?.toString() ?? '',
    );
    _merchant = TextEditingController(
      text: entry?.merchant ?? draft?.merchant ?? '',
    );
    _note = TextEditingController(text: entry?.note ?? '');
    _kind = entry?.kind ?? EntryKind.expense;
    _date = entry?.date ?? draft?.date ?? DateTime.now();
    _categoryId = entry?.categoryId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    String? copiedPath;
    try {
      String? receiptPath = widget.entry?.receiptPath;
      final source = widget.draft?.imagePath;
      if (source != null) {
        final directory = Directory(
          p.join((await getApplicationDocumentsDirectory()).path, 'receipts'),
        );
        await directory.create(recursive: true);
        final extension = p.extension(source).isEmpty
            ? '.jpg'
            : p.extension(source);
        copiedPath = p.join(
          directory.path,
          '${DateTime.now().microsecondsSinceEpoch}$extension',
        );
        await File(source).copy(copiedPath);
        receiptPath = copiedPath;
      }
      await widget.store.repository.saveEntry(
        MoneyEntry(
          id: widget.entry?.id,
          kind: _kind,
          amount: parseRupiahInput(_amount.text)!,
          categoryId: _categoryId!,
          date: _date,
          merchant: _merchant.text,
          note: _note.text,
          receiptPath: receiptPath,
        ),
      );
    } catch (error) {
      // Only remove a newly created private copy if the database write failed.
      if (copiedPath != null) {
        try {
          await File(copiedPath).delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, friendlyError(error));
      }
      return;
    }
    await widget.store.refresh();
    if (mounted) {
      showMessage(
        context,
        widget.entry == null ? 'Transaksi tersimpan' : 'Transaksi diperbarui',
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    if (!await confirmDelete(
      context,
      'Hapus transaksi?',
      'Catatan ini akan dihapus dari perangkat dan saldo dihitung ulang.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.store.repository.deleteEntry(widget.entry!.id!);
      final receipt = widget.entry!.receiptPath;
      if (receipt != null) {
        try {
          await File(receipt).delete();
        } catch (_) {}
      }
      await widget.store.refresh();
      if (mounted) {
        showMessage(context, 'Transaksi dihapus');
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
        .where((c) => c.kind == _kind)
        .toList();
    final draft = widget.draft;
    final imagePath = draft?.imagePath ?? widget.entry?.receiptPath;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            draft != null
                ? 'Periksa hasil scan'
                : widget.entry == null
                ? 'Catat transaksi'
                : 'Detail transaksi',
          ),
          actions: [
            if (widget.entry != null)
              IconButton(
                tooltip: 'Hapus transaksi',
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline, color: coral),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (draft != null) ...[
                      const Panel(
                        color: brandTint,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.fact_check_outlined),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Periksa total, tanggal, dan toko. Hasil scan bisa keliru; data baru dicatat saat Anda menekan Simpan.',
                                style: TextStyle(height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (draft.total == null ||
                          draft.date == null ||
                          draft.merchant == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Sebagian informasi belum terbaca. Lengkapi atau koreksi kolom di bawah ini.',
                            style: TextStyle(color: coral),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                    SegmentedButton<EntryKind>(
                      style: flowSegmentStyle(_kind),
                      segments: const [
                        ButtonSegment(
                          value: EntryKind.expense,
                          label: Text('Pengeluaran'),
                          icon: Icon(Icons.north_east),
                        ),
                        ButtonSegment(
                          value: EntryKind.income,
                          label: Text('Pemasukan'),
                          icon: Icon(Icons.south_west),
                        ),
                      ],
                      selected: {_kind},
                      onSelectionChanged: _busy
                          ? null
                          : (value) => setState(() {
                              _kind = value.first;
                              _categoryId = null;
                            }),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _amount,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: flowColor(_kind),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      validator: (value) =>
                          parseRupiahInput(value ?? '') == null
                          ? 'Isi nominal positif, maksimal 999.999.999.999'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      key: ValueKey(_kind),
                      initialValue: _categoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Kategori'),
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
                          : (value) => setState(() => _categoryId = value),
                      validator: (value) => value == null
                          ? 'Pilih kategori terlebih dahulu'
                          : null,
                    ),
                    if (categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Buat kategori di tab Kategori terlebih dahulu.',
                        ),
                      ),
                    const SizedBox(height: 16),
                    Panel(
                      padding: 8,
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Tanggal transaksi'),
                        subtitle: Text(dayLabel(_date)),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _busy
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
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
                    TextFormField(
                      controller: _merchant,
                      enabled: !_busy,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Toko / sumber dana',
                        hintText: 'Contoh: Kantin kampus',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _note,
                      enabled: !_busy,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Ada yang ingin diingat?',
                      ),
                    ),
                    if (imagePath != null) ...[
                      const SectionTitle('Foto struk'),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(imagePath),
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text(
                            'Foto struk tidak tersedia. Catatan transaksi tetap tersimpan.',
                          ),
                        ),
                      ),
                    ],
                    if (draft != null)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Lihat teks yang terbaca'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SelectableText(
                              draft.rawText.isEmpty
                                  ? 'Tidak ada teks yang terbaca.'
                                  : draft.rawText,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _busy
                            ? 'Menyimpan…'
                            : draft != null
                            ? 'Simpan transaksi dari struk'
                            : 'Simpan transaksi',
                      ),
                    ),
                    const SizedBox(height: 24),
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
