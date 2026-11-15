import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/storage/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(SizeSoulApp(database: await LocalDatabase.open()));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SelectableText('No se pudo iniciar SizeSoul: $error'),
          ),
        ),
      ),
    );
  }
}
