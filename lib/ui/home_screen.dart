import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../app_store.dart';
import '../domain/models.dart';
import 'components.dart';
import 'dashboard_screen.dart';
import 'editor_screen.dart';
import 'scan_screen.dart';
import 'categories_screen.dart';
import 'reports_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;
  static const _labels = ['Ringkasan', 'Transaksi', 'Laporan', 'Kategori'];
  static const _icons = [Icons.home_outlined, Icons.receipt_long_outlined, Icons.bar_chart_rounded, Icons.category_outlined];
  @override
  void initState() { super.initState(); widget.store.refresh(); }
  void _edit([MoneyEntry? entry]) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => EditorScreen(store: widget.store, entry: entry)));
  void _scan() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ScanScreen(store: widget.store)));
  void _select(int tab) => setState(() => _tab = tab);
  void _about() => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: const Text('SakuRapi'),
    content: const Text('Versi 1.1.1\n\nCatat transaksi dan scan struk. Periksa hasil scan sebelum menyimpan.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
  ));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: widget.store, builder: (context, _) {
    final store = widget.store;
    final home = _tab == 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: home ? brand : Colors.white,
        foregroundColor: home ? Colors.white : ink,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: home ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleSpacing: 24,
        title: Text(home ? 'SakuRapi' : _labels[_tab], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.5)),
        actions: [IconButton(tooltip: 'Tentang aplikasi', onPressed: _about, icon: const Icon(Icons.info_outline)), const SizedBox(width: 8)],
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator(semanticsLabel: 'Membuka catatan'))
          : store.error != null
          ? Center(child: EmptyState(title: 'Catatan belum terbuka', description: store.error!, action: FilledButton(onPressed: store.refresh, child: const Text('Coba lagi'))))
          : SafeArea(top: false, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: IndexedStack(index: _tab, children: [
            DashboardScreen(store: store, onEdit: _edit, onScan: _scan, onTab: _select),
            TransactionsScreen(store: store, onEdit: _edit),
            ReportsScreen(store: store),
            CategoriesScreen(store: store),
          ])))),
      floatingActionButton: store.loading || store.error != null ? null : FloatingActionButton(
        tooltip: 'Catat', backgroundColor: brand, foregroundColor: Colors.white, onPressed: _edit,
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 4)), elevation: 0,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: MediaQuery.textScalerOf(context).scale(11) > 15 ? 120 : 88,
        color: Colors.white, elevation: 0, shape: const CircularNotchedRectangle(), notchMargin: 6,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(children: [_nav(0), _nav(1), const SizedBox(width: 64), _nav(2), _nav(3)]),
      ),
    );
  });

  Widget _nav(int index) => Expanded(child: Semantics(selected: _tab == index, button: true, child: InkWell(
    onTap: () => _select(index), borderRadius: BorderRadius.circular(12),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
      Icon(_icons[index], color: _tab == index ? brand : muted, size: 25),
      const SizedBox(height: 7),
      Text(_labels[index], maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: _tab == index ? brand : muted, fontWeight: _tab == index ? FontWeight.w800 : FontWeight.w500)),
    ])),
  )));
}
