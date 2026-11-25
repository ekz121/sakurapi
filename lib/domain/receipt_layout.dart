/// OCR blocks often put labels and prices in different columns. Rebuild rows
/// using geometry so TOTAL and its price remain adjacent before parsing.
class ReceiptTextLine {
  const ReceiptTextLine(
    this.text,
    this.left,
    this.top,
    this.width,
    this.height,
  );
  final String text;
  final double left, top, width, height;
  double get centerY => top + height / 2;
}

String receiptReadingOrder(Iterable<ReceiptTextLine> input) {
  final lines = input.where((e) => e.text.trim().isNotEmpty).toList()
    ..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<ReceiptTextLine>>[];
  for (final line in lines) {
    if (rows.isNotEmpty) {
      final anchor = rows.last.first;
      final tolerance =
          (anchor.height < line.height ? anchor.height : line.height) * .55;
      if ((line.centerY - anchor.centerY).abs() <=
          (tolerance < 3 ? 3 : tolerance)) {
        rows.last.add(line);
        continue;
      }
    }
    rows.add([line]);
  }
  return rows
      .map((row) {
        row.sort((a, b) => a.left.compareTo(b.left));
        return row.map((line) => line.text.trim()).join('  ');
      })
      .join('\n');
}
