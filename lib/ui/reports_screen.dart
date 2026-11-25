import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../app_store.dart';
import '../domain/financial_report.dart';
import '../domain/formatters.dart';
import '../domain/models.dart';
import 'components.dart';
import 'editor_screen.dart';

const _incomeColor = incomeGreen;
const _chartColors = [
  Color(0xFFB42335),
  Color(0xFF74202D),
  Color(0xFFCC5932),
  Color(0xFF8D455E),
  Color(0xFF565964),
  Color(0xFF9C632B),
];

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _expenseOnly = false;
  int _selectedBar = 5;
  EntryKind _categoryKind = EntryKind.expense;

  void _categoryDetails(MoneyCategory category, FinancialReport report) {
    final entries = report.entries
        .where((e) => e.categoryId == category.id && e.kind == _categoryKind)
        .toList();
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(monthLabel(_month), style: const TextStyle(color: muted)),
              const SizedBox(height: 16),
              ...entries.map(
                (entry) => EntryTile(
                  entry: entry,
                  category: category,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      pageContext,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EditorScreen(store: widget.store, entry: entry),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = FinancialReport(widget.store.entries, _month);
    final ranked = report.categories(_categoryKind).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoryTotal = _categoryKind == EntryKind.expense
        ? report.expense
        : report.income;
    final values = ranked.map((e) => e.value).toList();
    final colors = List.generate(
      ranked.length,
      (i) => _categoryKind == EntryKind.income
          ? const [incomeGreen, Color(0xFF245345), Color(0xFF4B6C24)][i % 3]
          : _chartColors[i % _chartColors.length],
    );
    return Column(
      children: [
        Material(
          color: paper,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MonthPicker(
              month: _month,
              onChanged: (value) => setState(() {
                _month = value;
                _selectedBar = 5;
              }),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
            children: [
              const Text(
                'Laporan keuangan',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${report.entries.length} transaksi pada ${monthLabel(_month)}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              Panel(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selisih bulan ini',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        rupiah(report.net),
                        style: TextStyle(
                          fontSize: 34,
                          color: report.net < 0
                              ? coral
                              : report.net > 0
                              ? incomeGreen
                              : ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pemasukan dikurangi pengeluaran',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Panel(
                child: Column(
                  children: [
                    _AmountRow(
                      'Pemasukan',
                      report.income,
                      _incomeColor,
                      Icons.south_west,
                    ),
                    const Divider(height: 30),
                    _AmountRow(
                      'Pengeluaran',
                      report.expense,
                      coral,
                      Icons.north_east,
                    ),
                  ],
                ),
              ),
              const SectionTitle('Arus kas 6 bulan'),
              Panel(
                padding: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Arus kas')),
                        ButtonSegment(value: true, label: Text('Pengeluaran')),
                      ],
                      selected: {_expenseOnly},
                      onSelectionChanged: (value) =>
                          setState(() => _expenseOnly = value.first),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        onTapDown: (details) {
                          final index =
                              ((details.localPosition.dx - 50) /
                                      ((constraints.maxWidth - 60) / 6))
                                  .floor()
                                  .clamp(0, 5);
                          setState(() => _selectedBar = index);
                        },
                        child: Semantics(
                          label:
                              'Grafik pemasukan dan pengeluaran enam bulan. Rincian angka ada di bawah grafik.',
                          child: SizedBox(
                            height: 235,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _CashChart(
                                report: report,
                                expenseOnly: _expenseOnly,
                                selected: _selectedBar,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (!_expenseOnly)
                          const _Legend('Pemasukan', _incomeColor),
                        const _Legend('Pengeluaran', coral),
                      ],
                    ),
                    const Divider(height: 26),
                    Text(
                      monthLabel(report.months[_selectedBar]),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Masuk ${rupiah(report.monthlyIncome[_selectedBar])}',
                          style: const TextStyle(
                            color: _incomeColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Keluar ${rupiah(report.monthlyExpense[_selectedBar])}',
                          style: const TextStyle(color: coral, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rata-rata pengeluaran: ${rupiah(report.averageExpense)}/bulan',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Ketuk kolom bulan untuk melihat angkanya.',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Rincian per kategori'),
              SegmentedButton<EntryKind>(
                style: flowSegmentStyle(_categoryKind),
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
                selected: {_categoryKind},
                onSelectionChanged: (v) =>
                    setState(() => _categoryKind = v.first),
              ),
              const SizedBox(height: 16),
              if (ranked.isEmpty)
                EmptyState(
                  title: _categoryKind == EntryKind.expense
                      ? 'Belum ada pengeluaran'
                      : 'Belum ada pemasukan',
                  description: 'Pilih bulan lain atau tambahkan transaksi.',
                  icon: Icons.pie_chart_outline,
                )
              else ...[
                Panel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _categoryKind == EntryKind.expense
                                  ? 'Total pengeluaran'
                                  : 'Total pemasukan',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                rupiah(categoryTotal),
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${ranked.length} kategori',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 122,
                        height: 122,
                        child: Semantics(
                          label: 'Proporsi ${ranked.length} kategori',
                          child: CustomPaint(painter: _Donut(values, colors)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(ranked.length, (i) {
                  final item = ranked[i];
                  final category = widget.store.category(item.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Panel(
                      padding: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors[i].withValues(alpha: .1),
                          child: Icon(
                            categoryIcon(category.symbol),
                            color: flowColor(_categoryKind),
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${(100 * item.value / categoryTotal).toStringAsFixed(1)}%  •  ${rupiah(item.value)}',
                          style: TextStyle(
                            color: flowColor(_categoryKind),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _categoryDetails(category, report),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, this.color, this.icon);
  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(label)),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            rupiah(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
      ),
    ],
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: muted)),
    ],
  );
}

class _CashChart extends CustomPainter {
  _CashChart({
    required this.report,
    required this.expenseOnly,
    required this.selected,
  });
  final FinancialReport report;
  final bool expenseOnly;
  final int selected;
  @override
  void paint(Canvas canvas, Size size) {
    const left = 50.0, top = 18.0, bottom = 34.0;
    final width = size.width - left - 10;
    final height = size.height - top - bottom;
    final maxValue = [
      ...report.monthlyExpense,
      if (!expenseOnly) ...report.monthlyIncome,
    ].fold<int>(0, math.max);
    final magnitude = maxValue == 0
        ? 10000.0
        : math.pow(10, (math.log(maxValue) / math.ln10).floor()).toDouble();
    final normalized = maxValue / magnitude;
    final maxY = maxValue == 0
        ? magnitude
        : magnitude *
              (normalized <= 1
                  ? 1
                  : normalized <= 2
                  ? 2
                  : normalized <= 5
                  ? 5
                  : 10);
    void label(
      String text,
      double x,
      double y, {
      bool centered = false,
      Color color = muted,
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 10, fontFamily: 'Roboto'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(centered ? x - tp.width / 2 : x, y));
    }

    for (var tick = 0; tick <= 4; tick++) {
      final y = top + height * (1 - tick / 4);
      final value = maxY * tick / 4;
      final text = value >= 1000000
          ? '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}jt'
          : value >= 1000
          ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}rb'
          : value.round().toString();
      label(text, 0, y - 6);
      for (double x = left; x < size.width - 10; x += 8) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 4, size.width - 10), y),
          Paint()
            ..color = const Color(0xFFDADAE1)
            ..strokeWidth = 1,
        );
      }
    }
    final slot = width / 6;
    for (var i = 0; i < 6; i++) {
      final center = left + slot * (i + .5);
      final barWidth = math.min(13.0, slot * .28);
      void bar(int value, double x, Color color) {
        if (value == 0) return;
        final h = math.max(2.0, height * value / maxY);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, top + height - h, barWidth, h),
            const Radius.circular(4),
          ),
          Paint()..color = color,
        );
      }

      if (expenseOnly) {
        bar(report.monthlyExpense[i], center - barWidth / 2, coral);
      } else {
        bar(report.monthlyIncome[i], center - barWidth - 1, _incomeColor);
        bar(report.monthlyExpense[i], center + 1, coral);
      }
      label(
        DateFormat('MMM', 'id_ID').format(report.months[i]),
        center,
        size.height - 26,
        centered: true,
        color: i == selected ? ink : muted,
      );
      label(
        DateFormat('yy').format(report.months[i]),
        center,
        size.height - 13,
        centered: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CashChart old) => true;
}

class _Donut extends CustomPainter {
  _Donut(this.values, this.colors);
  final List<int> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final angle = values[i] / total * 2 * math.pi;
      canvas.drawArc(
        rect,
        start + .012,
        math.max(0, angle - .024),
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 21,
      );
      start += angle;
    }
  }

  @override
  bool shouldRepaint(covariant _Donut old) => true;
}
