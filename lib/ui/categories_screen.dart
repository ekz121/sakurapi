import 'package:material_ui/material_ui.dart';
import '../app_store.dart';
import '../domain/models.dart';
import 'components.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, required this.store});
  final AppStore store;
  Future<void> _edit(BuildContext context, [MoneyCategory? category]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryEditor(store: store, category: category),
      ),
    );
    if (changed == true) await store.refresh();
  }

  Future<void> _delete(BuildContext context, MoneyCategory category) async {
    if (!await confirmDelete(
      context,
      'Hapus kategori?',
      'Hapus kategori ${category.name}? Kategori yang masih dipakai transaksi tidak dapat dihapus.',
    )) {
      return;
    }
    try {
      await store.repository.deleteCategory(category.id);
      await store.refresh();
    } catch (error) {
      if (context.mounted) showMessage(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
    children: [
      const Text(
        'Kategori',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Kategori baru'),
        ),
      ),
      for (final kind in EntryKind.values) ...[
        SectionTitle(kind == EntryKind.expense ? 'Pengeluaran' : 'Pemasukan'),
        if (!store.categories.any((c) => c.kind == kind))
          const Text('Belum ada kategori. Tambahkan kategori baru.'),
        ...store.categories
            .where((c) => c.kind == kind)
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  padding: 6,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        category.color,
                      ).withValues(alpha: .09),
                      child: Icon(
                        categoryIcon(category.symbol),
                        color: Color.lerp(Color(category.color), ink, .35),
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _edit(context, category),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Opsi kategori',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _edit(context, category);
                        } else {
                          _delete(context, category);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Ubah')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    ],
  );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.store, this.category});
  final AppStore store;
  final MoneyCategory? category;
  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late EntryKind _kind;
  late int _color;
  late String _symbol;
  var _busy = false;
  static const colors = [
    0xFFB42335,
    0xFF74202D,
    0xFF96502C,
    0xFF14734A,
    0xFF565964,
    0xFF245345,
    0xFF614C87,
  ];
  static const symbols = [
    'food',
    'transport',
    'shopping',
    'study',
    'wallet',
    'work',
    'other',
  ];
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _kind = widget.category?.kind ?? EntryKind.expense;
    _color = widget.category?.color ?? colors.first;
    _symbol = widget.category?.symbol ?? 'other';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.store.repository.saveCategory(
        id: widget.category?.id,
        name: _name.text,
        kind: _kind,
        color: _color,
        symbol: _symbol,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, friendlyError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.category == null ? 'Kategori baru' : 'Ubah kategori'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 40,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'Nama kategori'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<EntryKind>(
                  style: flowSegmentStyle(_kind),
                  segments: const [
                    ButtonSegment(
                      value: EntryKind.expense,
                      label: Text('Pengeluaran'),
                    ),
                    ButtonSegment(
                      value: EntryKind.income,
                      label: Text('Pemasukan'),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _busy
                      ? null
                      : (v) => setState(() => _kind = v.first),
                ),
                const SectionTitle('Warna'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors
                      .map(
                        (color) => IconButton.filledTonal(
                          tooltip:
                              'Warna kategori ${colors.indexOf(color) + 1}',
                          onPressed: _busy
                              ? null
                              : () => setState(() => _color = color),
                          style: IconButton.styleFrom(
                            backgroundColor: Color(color),
                          ),
                          icon: Icon(
                            _color == color ? Icons.check : Icons.circle,
                            color: Colors.white,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SectionTitle('Ikon'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: symbols
                      .map(
                        (symbol) => IconButton.filledTonal(
                          tooltip: symbol,
                          isSelected: _symbol == symbol,
                          onPressed: _busy
                              ? null
                              : () => setState(() => _symbol = symbol),
                          icon: Icon(categoryIcon(symbol)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? 'Menyimpan…' : 'Simpan kategori'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
