import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app_store.dart';
import 'data/finance_repository.dart';
import 'main.dart' as app;

/// Browser-only entry point. The Android entry point stays in main.dart.
Future<void> main() async {
  if (!kIsWeb) return app.main();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final store = AppStore(
    FinanceRepository(
      factory: databaseFactoryFfiWeb,
      databasePath: 'sakurapi_preview.db',
    ),
  );
  runApp(
    ColoredBox(
      color: const Color(0xFFE3E8E2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: app.SakuRapiApp(store: store),
        ),
      ),
    ),
  );
}
