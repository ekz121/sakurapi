import 'package:material_ui/material_ui.dart';

import '../domain/formatters.dart';
import '../domain/models.dart';

const brand = Color(0xFFB42335);
const ink = Color(0xFF24252B);
const paper = Color(0xFFF7F7F9);
const muted = Color(0xFF62656F);
const coral = Color(0xFFB42335);
const incomeGreen = Color(0xFF14734A);
const brandTint = Color(0xFFFFEBED);

Color flowColor(EntryKind kind) =>
    kind == EntryKind.income ? incomeGreen : coral;

ButtonStyle flowSegmentStyle(EntryKind kind) => ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.selected)
        ? flowColor(kind).withValues(alpha: .10)
        : Colors.white,
  ),
  foregroundColor: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.selected) ? flowColor(kind) : muted,
  ),
);

IconData categoryIcon(String symbol) => switch (symbol) {
  'food' => Icons.restaurant_rounded,
  'transport' => Icons.directions_bus_rounded,
  'shopping' => Icons.shopping_bag_outlined,
  'study' => Icons.school_outlined,
  'wallet' => Icons.account_balance_wallet_outlined,
  'work' => Icons.work_outline_rounded,
  _ => Icons.grid_view_rounded,
};

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.color, this.padding = 20});
  final Widget child;
  final Color? color;
  final double padding;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE5E5EA)),
    ),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.action,
    this.icon = Icons.receipt_long_outlined,
  });
  final String title, description;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: paper,
              child: Icon(icon, color: ink, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.category,
    required this.onTap,
  });
  final MoneyEntry entry;
  final MoneyCategory category;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final stacked =
          box.maxWidth < 340 || MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final amount = Text(
        '${entry.kind == EntryKind.income ? '+' : '−'}${rupiah(entry.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: flowColor(entry.kind),
          fontSize: 15,
        ),
      );
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: flowColor(entry.kind).withValues(alpha: .09),
                child: Icon(
                  categoryIcon(category.symbol),
                  color: flowColor(entry.kind),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.merchant.isEmpty ? category.name : entry.merchant,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.name,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    if (stacked) ...[const SizedBox(height: 8), amount],
                  ],
                ),
              ),
              if (!stacked) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 142),
                  child: FittedBox(fit: BoxFit.scaleDown, child: amount),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class MonthPicker extends StatelessWidget {
  const MonthPicker({super.key, required this.month, required this.onChanged});
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Bulan sebelumnya',
        onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: TextButton(
          onPressed: () async {
            var year = month.year;
            var selectedMonth = month.month;
            final result = await showDialog<DateTime>(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                  title: const Text('Pilih bulan laporan'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: year,
                        decoration: const InputDecoration(labelText: 'Tahun'),
                        items: List.generate(
                          101,
                          (i) => DropdownMenuItem(
                            value: 2000 + i,
                            child: Text('${2000 + i}'),
                          ),
                        ),
                        onChanged: (v) => setDialogState(() => year = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(labelText: 'Bulan'),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              monthLabel(
                                DateTime(2000, i + 1),
                              ).split(' ').first,
                            ),
                          ),
                        ),
                        onChanged: (v) =>
                            setDialogState(() => selectedMonth = v!),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, DateTime(year, selectedMonth)),
                      child: const Text('Tampilkan'),
                    ),
                  ],
                ),
              ),
            );
            if (result != null) onChanged(result);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  monthLabel(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      ),
      IconButton(
        tooltip: 'Bulan berikutnya',
        onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String friendlyError(Object error) => error is ArgumentError
    ? '${error.message}'
    : 'Perubahan belum tersimpan. Silakan coba lagi.';

Future<bool> confirmDelete(
  BuildContext context,
  String title,
  String description,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ??
    false;
