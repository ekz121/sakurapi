import 'package:material_ui/material_ui.dart';

import '../app_store.dart';
import '../domain/formatters.dart';
import '../domain/models.dart';
import 'components.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.onEdit,
    required this.onScan,
    required this.onTab,
  });
  final AppStore store;
  final void Function([MoneyEntry?]) onEdit;
  final VoidCallback onScan;
  final ValueChanged<int> onTab;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _visible = true;

  Future<void> _openingBalance() async {
    var input = '${widget.store.openingBalance}';
    final form = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saldo awal'),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: input,
            onChanged: (v) => input = v,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              labelText: 'Rupiah',
              helperText: 'Saldo sebelum transaksi pertama.',
            ),
            validator: (v) => parseBalanceInput(v ?? '') == null
                ? 'Masukkan bilangan rupiah yang valid'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, parseBalanceInput(input)!);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      await widget.store.repository.setOpeningBalance(result);
      await widget.store.refresh();
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final month = store.inMonth(DateTime.now());
    final recent = store.entries.take(6).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
          decoration: const BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthLabel(DateTime.now()),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Saldo saat ini',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: _visible ? 'Sembunyikan saldo' : 'Tampilkan saldo',
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ubah saldo awal',
                    onPressed: _openingBalance,
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  ),
                ],
              ),
              Semantics(
                liveRegion: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _visible ? rupiah(store.balance) : '••••••',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _visible
                    ? 'Saldo awal ${rupiah(store.openingBalance)}'
                    : 'Saldo disembunyikan',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, box) {
                  final vertical =
                      box.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  final income = _FlowSummary(
                    label: 'Pemasukan',
                    amount: store.total(month, EntryKind.income),
                    kind: EntryKind.income,
                    visible: _visible,
                  );
                  final expense = _FlowSummary(
                    label: 'Pengeluaran',
                    amount: store.total(month, EntryKind.expense),
                    kind: EntryKind.expense,
                    visible: _visible,
                  );
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: vertical
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              income,
                              const Divider(height: 25),
                              expense,
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(child: income),
                                const VerticalDivider(width: 28),
                                Expanded(child: expense),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Panel(
            padding: 8,
            child: Row(
              children: [
                _Shortcut(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan struk',
                  onTap: widget.onScan,
                ),
                _Shortcut(
                  icon: Icons.bar_chart_rounded,
                  label: 'Laporan',
                  onTap: () => widget.onTab(2),
                ),
                _Shortcut(
                  icon: Icons.category_outlined,
                  label: 'Kategori',
                  onTap: () => widget.onTab(3),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            'Transaksi terakhir',
            action: TextButton(
              onPressed: () => widget.onTab(1),
              child: const Text('Semua'),
            ),
          ),
        ),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: EmptyState(
              title: 'Belum ada transaksi',
              description: 'Catat pemasukan atau pengeluaran pertama Anda.',
              action: FilledButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.add),
                label: const Text('Tambah transaksi'),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Panel(
              padding: 14,
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i == 0 ||
                        dayLabel(recent[i].date) !=
                            dayLabel(recent[i - 1].date))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            dayLabel(recent[i].date),
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    EntryTile(
                      entry: recent[i],
                      category: store.category(recent[i].categoryId),
                      onTap: () => widget.onEdit(recent[i]),
                    ),
                    if (i < recent.length - 1) const Divider(height: 12),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FlowSummary extends StatelessWidget {
  const _FlowSummary({
    required this.label,
    required this.amount,
    required this.kind,
    required this.visible,
  });
  final String label;
  final int amount;
  final EntryKind kind;
  final bool visible;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            kind == EntryKind.income ? Icons.south_west : Icons.north_east,
            color: flowColor(kind),
            size: 17,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          visible ? rupiah(amount) : '••••',
          style: TextStyle(
            color: flowColor(kind),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        foregroundColor: ink,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: brandTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: brand, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
