import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/bootstrap_error_app.dart';
import 'shared/config/app_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID');
    await AppEnvironment.load();
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      anonKey: AppEnvironment.supabaseAnonKey,
    );
    runApp(const ProviderScope(child: WarungKopiApp()));
  } catch (error) {
    runApp(
      ProviderScope(
        child: BootstrapErrorApp(message: error.toString()),
      ),
    );
  }
}
