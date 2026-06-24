import 'package:flutter/material.dart';

import '../views/environment_monitoring_page.dart';
import '../views/fitur_seleksi.dart';
import '../views/halaman_awal.dart';
import '../views/implementation_log_page.dart';
import '../views/login_dan_buat_akun_page.dart';
import '../views/maintenance_notes_page.dart';
import '../views/model_transaction_logging_page.dart';
import '../views/performance_monitoring_page.dart';
import '../views/profil_page.dart';
import '../views/project_seleksi.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System Implementation Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      initialRoute: HalamanAwal.routeName,
      scrollBehavior: const _NoStretchScrollBehavior(),
      routes: {
        HalamanAwal.routeName: (_) => const HalamanAwal(),
        LoginDanBuatAkunPage.routeName: (_) => const LoginDanBuatAkunPage(),
        ProjectSeleksiPage.routeName: (_) => const ProjectSeleksiPage(),
        FiturSeleksiPage.routeName: (_) => const FiturSeleksiPage(),
        ImplementationLogPage.routeName: (_) => const ImplementationLogPage(),
        EnvironmentMonitoringPage.routeName: (_) =>
            const EnvironmentMonitoringPage(),
        MaintenanceNotesPage.routeName: (_) => const MaintenanceNotesPage(),
        ModelTransactionLoggingPage.routeName: (_) =>
            const ModelTransactionLoggingPage(),
        PerformanceMonitoringPage.routeName: (_) =>
            const PerformanceMonitoringPage(),
        ProfilPage.routeName: (_) => const ProfilPage(),
      },
    );
  }
}

class _NoStretchScrollBehavior extends ScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Menghilangkan efek stretching/glow
  }
}
