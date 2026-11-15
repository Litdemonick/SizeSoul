import 'package:flutter/material.dart';

import '../core/storage/local_database.dart';
import '../features/dashboard/dashboard_page.dart';

class SizeSoulApp extends StatefulWidget {
  final LocalDatabase database;
  const SizeSoulApp({super.key, required this.database});
  @override
  State<SizeSoulApp> createState() => _SizeSoulAppState();
}

class _SizeSoulAppState extends State<SizeSoulApp> {
  bool dark = true;
  @override
  void initState() {
    super.initState();
    widget.database.setting('dark').then((v) {
      if (mounted) setState(() => dark = v != 'false');
    });
  }

  ThemeData theme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFC87932),
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: dark ? const Color(0xFFF0B775) : const Color(0xFF985214),
          surface: dark ? const Color(0xFF202326) : Colors.white,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: dark
          ? const Color(0xFF181A1D)
          : const Color(0xFFF2F3F4),
      visualDensity: VisualDensity.compact,
      dividerColor: dark ? const Color(0xFF35393E) : const Color(0xFFDDDFE3),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .4)),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 13),
        bodySmall: TextStyle(fontSize: 11),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SizeSoul',
    debugShowCheckedModeBanner: false,
    theme: theme(),
    home: DashboardPage(
      database: widget.database,
      dark: dark,
      onTheme: (v) async {
        setState(() => dark = v);
        try {
          await widget.database.set('dark', '$v');
        } catch (_) {
          /* Theme remains usable when preferences are unavailable. */
        }
      },
    ),
  );
}
