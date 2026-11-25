import 'package:material_ui/material_ui.dart';
import '../app_store.dart';
import '../domain/formatters.dart';
import '../domain/models.dart';
import 'components.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.store,
    required this.onEdit,
  });
  final AppStore store;
  final void Function([MoneyEntry?]) onEdit;
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _search = '';
  EntryKind? _kind;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _allMonths = true;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final list = store.entries
        .where(
          (e) =>
              (_kind == null || e.kind == _kind) &&
              (_allMonths ||
                  e.date.year == _month.year && e.date.month == _month.month) &&
              '${e.merchant} ${e.note} ${store.category(e.categoryId).name}'
                  .toLowerCase()
                  .contains(_search.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: const InputDecoration(
            labelText: 'Cari transaksi',
            hintText: 'Toko, kategori, atau catatan',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Semua'),
              selected: _kind == null,
              onSelected: (_) => setState(() => _kind = null),
            ),
            ChoiceChip(
              label: const Text('Pengeluaran'),
              selected: _kind == EntryKind.expense,
              selectedColor: brandTint,
              labelStyle: TextStyle(
                color: _kind == EntryKind.expense ? coral : ink,
              ),
              onSelected: (_) => setState(() => _kind = EntryKind.expense),
            ),
            ChoiceChip(
              label: const Text('Pemasukan'),
              selected: _kind == EntryKind.income,
              selectedColor: const Color(0xFFE8F5EE),
              labelStyle: TextStyle(
                color: _kind == EntryKind.income ? incomeGreen : ink,
              ),
              onSelected: (_) => setState(() => _kind = EntryKind.income),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Semua bulan'),
          value: _allMonths,
          onChanged: (v) => setState(() => _allMonths = v),
        ),
        if (!_allMonths)
          MonthPicker(
            month: _month,
            onChanged: (m) => setState(() => _month = m),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '${list.length} transaksi',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
        ),
        if (list.isEmpty)
          const EmptyState(
            title: 'Tidak ada transaksi',
            description: 'Tambahkan transaksi atau ubah filter pencarian.',
          )
        else
          Panel(
            padding: 12,
            child: Column(
              children: [
                for (var i = 0; i < list.length; i++) ...[
                  if (i == 0 ||
                      dayLabel(list[i].date) != dayLabel(list[i - 1].date))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          dayLabel(list[i].date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  EntryTile(
                    entry: list[i],
                    category: store.category(list[i].categoryId),
                    onTap: () => widget.onEdit(list[i]),
                  ),
                  if (i < list.length - 1) const Divider(height: 10),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
