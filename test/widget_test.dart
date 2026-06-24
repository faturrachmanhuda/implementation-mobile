import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:main_app/main.dart';
import 'package:main_app/models/environment_record.dart';
import 'package:main_app/models/implementation_log.dart';
import 'package:main_app/models/maintenance_note.dart';
import 'package:main_app/models/model_transaction.dart';
import 'package:main_app/models/performance_record.dart';
import 'package:main_app/models/project.dart';
import 'package:main_app/services/api_client.dart';

void main() {
  setUp(() {
    ApiServices.instance = _FakeApiService();
  });

  testWidgets('Auth page opens with login and register tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('System Implementation Platform'), findsOneWidget);
    expect(find.text('Login/Daftar'), findsOneWidget);

    await tester.tap(find.text('Login/Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Buat Akun'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Masukkan email'), findsOneWidget);

    await tester.tap(find.text('Buat Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);
  });

  testWidgets('Login flow opens project selection before feature menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Login/Daftar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'user@mail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Project'), findsOneWidget);
    expect(find.text('Smart Campus Monitoring'), findsOneWidget);

    await tester.tap(find.text('Smart Campus Monitoring'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Pilih Project'));
    await tester.pumpAndSettle();

    expect(find.text('Implementation Log'), findsOneWidget);
    expect(find.text('Smart Campus Monitoring'), findsOneWidget);

    await tester.tap(find.text('Environment Monitoring'));
    await tester.pumpAndSettle();

    expect(find.text('System Health'), findsOneWidget);
    expect(find.text('Belum Ada Data'), findsOneWidget);
  });
}

class _FakeApiService implements ApiService {
  @override
  String get baseUrl => '';

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return AuthResult(
      email: email,
      name: 'User',
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh',
    );
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  Future<List<Project>> fetchProjects() async {
    return const [
      Project(
        id: 'SIP-001',
        createdAt: '16 Apr 2026',
        name: 'Smart Campus Monitoring',
        description: 'Monitoring implementasi sistem cerdas.',
      ),
    ];
  }

  @override
  Future<void> selectProject(Project project) async {}

  @override
  Future<ProfileResult> fetchProfile() async {
    return const ProfileResult(
      name: 'User',
      email: 'user@mail.com',
      activeProjectId: 'SIP-001',
      activeProjectName: 'Smart Campus Monitoring',
    );
  }

  @override
  Future<ProfileResult> updateProfileName(String fullName) async {
    return ProfileResult(
      name: fullName,
      email: 'user@mail.com',
      activeProjectId: 'SIP-001',
      activeProjectName: 'Smart Campus Monitoring',
    );
  }

  @override
  Future<ProfileResult> updateProfileEmail(String email) async {
    return ProfileResult(
      name: 'User',
      email: email,
      activeProjectId: 'SIP-001',
      activeProjectName: 'Smart Campus Monitoring',
    );
  }

  @override
  Future<ProfileResult> updateProfilePhoto(String filePath) async {
    return const ProfileResult(
      name: 'User',
      email: 'user@mail.com',
      activeProjectId: 'SIP-001',
      activeProjectName: 'Smart Campus Monitoring',
      profilePictureUrl: 'https://example.com/profile.png',
    );
  }

  @override
  Future<void> updateProfilePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {}

  @override
  Future<List<EnvironmentRecord>> fetchEnvironmentRecords() async => const [];

  @override
  Future<List<PerformanceRecord>> fetchPerformanceRecords() async => const [];

  @override
  Future<List<ModelTransaction>> fetchModelTransactions() async => const [];

  @override
  Future<List<MaintenanceNote>> fetchMaintenanceNotes() async => const [];

  @override
  Future<List<ImplementationLog>> fetchImplementationLogs() async => const [];

  @override
  Future<void> createImplementationLog({
    required String tanggal,
    required String aktivitas,
    required String status,
    required String versi,
    required String hasil,
    required String catatan,
    required String lokasiDeployment,
    required String namaSistem,
  }) async {}

  @override
  Future<void> updateImplementationLog(
    int id, {
    required String tanggal,
    required String aktivitas,
    required String status,
    required String versi,
    required String hasil,
    required String catatan,
    required String lokasiDeployment,
    required String namaSistem,
  }) async {}

  @override
  Future<void> deleteImplementationLog(int id) async {}

  @override
  Future<void> createMaintenanceNote({
    required String judul,
    required String deskripsi,
    required String status,
    List<String> filePaths = const [],
  }) async {}

  @override
  Future<void> updateMaintenanceNote(
    int id, {
    required String judul,
    required String deskripsi,
    required String status,
    List<String> filePaths = const [],
  }) async {}

  @override
  Future<void> deleteMaintenanceNote(int id) async {}
}
