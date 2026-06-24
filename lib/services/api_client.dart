import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/environment_record.dart';
import '../models/implementation_log.dart';
import '../models/maintenance_note.dart';
import '../models/model_transaction.dart';
import '../models/performance_record.dart';
import '../models/project.dart';
import 'app_session.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult({
    required this.email,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
  });

  final String email;
  final String name;
  final String accessToken;
  final String refreshToken;
}

class ProfileResult {
  const ProfileResult({
    required this.name,
    required this.email,
    required this.activeProjectId,
    required this.activeProjectName,
    this.profilePictureUrl = '',
  });

  final String name;
  final String email;
  final String activeProjectId;
  final String activeProjectName;
  final String profilePictureUrl;

  factory ProfileResult.fromJson(Map<String, dynamic> json) {
    return ProfileResult(
      name: (json['name'] ?? 'User').toString(),
      email: (json['email'] ?? '-').toString(),
      activeProjectId: (json['active_project_id'] ?? '').toString(),
      activeProjectName: (json['active_project_name'] ?? '').toString(),
      profilePictureUrl: (json['profile_picture_url'] ?? '').toString(),
    );
  }
}

abstract class ApiService {
  String get baseUrl;

  Future<AuthResult> login({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<List<Project>> fetchProjects();

  Future<void> selectProject(Project project);

  Future<ProfileResult> fetchProfile();

  Future<ProfileResult> updateProfileName(String fullName);

  Future<ProfileResult> updateProfileEmail(String email);

  Future<ProfileResult> updateProfilePhoto(String filePath);

  Future<void> updateProfilePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<List<EnvironmentRecord>> fetchEnvironmentRecords();

  Future<List<PerformanceRecord>> fetchPerformanceRecords();

  Future<List<ModelTransaction>> fetchModelTransactions();

  Future<List<MaintenanceNote>> fetchMaintenanceNotes();

  Future<List<ImplementationLog>> fetchImplementationLogs();

  Future<void> createImplementationLog({
    required String tanggal,
    required String aktivitas,
    required String status,
    required String versi,
    required String hasil,
    required String catatan,
    required String lokasiDeployment,
    required String namaSistem,
  });

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
  });

  Future<void> deleteImplementationLog(int id);

  Future<List<String>> fetchICFunctions();

  Future<void> createMaintenanceNote({
    required String judul,
    required String deskripsi,
    required String status,
    List<String> fungsi = const [],
    List<String> filePaths = const [],
  });

  Future<void> updateMaintenanceNote(
    int id, {
    required String judul,
    required String deskripsi,
    required String status,
    List<String> fungsi = const [],
    List<String> filePaths = const [],
  });

  Future<void> deleteMaintenanceNote(int id);
}

class ApiServices {
  static ApiService instance = DjangoApiClient();
}

class DjangoApiClient implements ApiService {
  DjangoApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(RegExp(r'/$'), '') {
    debugPrint('DjangoApiClient: Initialized with Base URL -> $_baseUrl');
  }

  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.6:8004',
  );

  final http.Client _client;
  final String _baseUrl;
  String? _accessToken;
  String? _refreshToken;

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    // Fallback to local network
    return 'http://192.168.1.6:8004';
  }

  @override
  String get baseUrl => _baseUrl;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/api/auth/login/', {
      'email': email,
      'password': password,
    }, authenticated: false);

    final user = response['user'];
    _accessToken = (response['access'] ?? '').toString();
    _refreshToken = (response['refresh'] ?? '').toString();

    if (_accessToken == null || _accessToken!.isEmpty) {
      throw const ApiException('Token login tidak diterima dari server.');
    }

    return AuthResult(
      email: user is Map ? (user['email'] ?? email).toString() : email,
      name: user is Map ? (user['name'] ?? email).toString() : email,
      accessToken: _accessToken!,
      refreshToken: _refreshToken ?? '',
    );
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _post('/api/auth/register/', {
      'name': name,
      'email': email,
      'password': password,
    }, authenticated: false);
  }

  @override
  Future<List<Project>> fetchProjects() async {
    final response = await _client.get(
      _uri('/api/projects/'),
      headers: _headers(),
    );
    final data = _decode(response);
    if (data is! List) {
      throw const ApiException('Format daftar project tidak valid.');
    }
    return data
        .whereType<Map>()
        .map((item) => Project.fromJson(item.cast<String, dynamic>()))
        .where((project) => project.id.isNotEmpty)
        .toList();
  }

  @override
  Future<void> selectProject(Project project) async {
    await _post('/api/projects/select/', {
      'project_id': project.id,
      'project_name': project.name,
    });
  }

  @override
  Future<ProfileResult> fetchProfile() async {
    final data = await _getMap('/api/profile/');
    return ProfileResult.fromJson(data);
  }

  @override
  Future<ProfileResult> updateProfileName(String fullName) async {
    final data = await _post('/api/profile/update-name/', {
      'full_name': fullName,
    });
    return _profileFromWrappedResponse(data);
  }

  @override
  Future<ProfileResult> updateProfileEmail(String email) async {
    final data = await _post('/api/profile/update-email/', {'email': email});
    return _profileFromWrappedResponse(data);
  }

  @override
  Future<ProfileResult> updateProfilePhoto(String filePath) async {
    final data = await _multipartPost('/api/profile/update-photo/', const {}, [
      filePath,
    ], 'profile_picture');
    return _profileFromWrappedResponse(data);
  }

  @override
  Future<void> updateProfilePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _post('/api/profile/update-password/', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  @override
  Future<List<EnvironmentRecord>> fetchEnvironmentRecords() async {
    final response = await _client.get(
      _uri('/api/environment/'),
      headers: _headers(),
    );
    final data = _decode(response);
    if (data is! List) {
      throw const ApiException('Format data environment tidak valid.');
    }
    return data
        .whereType<Map>()
        .map((item) => EnvironmentRecord.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<PerformanceRecord>> fetchPerformanceRecords() async {
    final response = await _client.get(
      _uri('/api/performance/'),
      headers: _headers(),
    );
    final data = _decode(response);
    if (data is! List) {
      throw const ApiException('Format data performa tidak valid.');
    }
    return data
        .whereType<Map>()
        .map((item) => PerformanceRecord.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<ModelTransaction>> fetchModelTransactions() async {
    final response = await _client.get(
      _uri('/api/transactions/'),
      headers: _headers(),
    );
    final data = _decode(response);
    if (data is! List) {
      throw const ApiException('Format data model transaksi tidak valid.');
    }
    return data
        .whereType<Map>()
        .map((item) => ModelTransaction.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<MaintenanceNote>> fetchMaintenanceNotes() async {
    final response = await _client.get(
      _uri('/api/notes/'),
      headers: _headers(),
    );
    final data = _decode(response);
    if (data is! List) {
      throw const ApiException('Format data maintenance notes tidak valid.');
    }
    return data
        .whereType<Map>()
        .map((item) => MaintenanceNote.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<ImplementationLog>> fetchImplementationLogs() async {
    final response = await _client.get(_uri('/api/logs/'), headers: _headers());
    final data = _decode(response);
    if (data is! List) {
      throw const ApiException('Format data implementation log tidak valid.');
    }
    return data
        .whereType<Map>()
        .map((item) => ImplementationLog.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

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
  }) async {
    await _post('/api/logs/create/', {
      'tanggal': tanggal,
      'aktivitas': aktivitas,
      'status': status,
      'versi': versi,
      'hasil': hasil,
      'catatan': catatan,
      'lokasi_deployment': lokasiDeployment,
      'nama_sistem': namaSistem,
    });
  }

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
  }) async {
    await _post('/api/logs/update/$id/', {
      'tanggal': tanggal,
      'aktivitas': aktivitas,
      'status': status,
      'versi': versi,
      'hasil': hasil,
      'catatan': catatan,
      'lokasi_deployment': lokasiDeployment,
      'nama_sistem': namaSistem,
    });
  }

  @override
  Future<void> deleteImplementationLog(int id) async {
    final response = await _client.delete(
      _uri('/api/logs/delete/$id/'),
      headers: _headers(),
    );
    _decode(response);
  }

  @override
  Future<List<String>> fetchICFunctions() async {
    final response = await _client.get(
      _uri('/api/notes/ic-functions/'),
      headers: _headers(),
    );
    final data = _decode(response);
    if (data is Map<String, dynamic>) {
      final systems = data['systems'];
      if (systems is List) {
        return systems.map((s) => (s['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
      }
    }
    return [];
  }

  @override
  Future<void> createMaintenanceNote({
    required String judul,
    required String deskripsi,
    required String status,
    List<String> fungsi = const [],
    List<String> filePaths = const [],
  }) async {
    final fields = {
      'judul': judul,
      'deskripsi': deskripsi,
      'status': status,
      'fungsi': jsonEncode(fungsi),
    };
    await _multipartPost('/api/notes/create/', fields, filePaths, 'lampiran');
  }

  @override
  Future<void> updateMaintenanceNote(
    int id, {
    required String judul,
    required String deskripsi,
    required String status,
    List<String> fungsi = const [],
    List<String> filePaths = const [],
  }) async {
    final fields = {
      'judul': judul,
      'deskripsi': deskripsi,
      'status': status,
      'fungsi': jsonEncode(fungsi),
    };
    await _multipartPost('/api/notes/update/$id/', fields, filePaths, 'lampiran');
  }

  @override
  Future<void> deleteMaintenanceNote(int id) async {
    final response = await _client.delete(
      _uri('/api/notes/delete/$id/'),
      headers: _headers(),
    );
    _decode(response);
  }

  Future<Map<String, dynamic>> _multipartPost(
    String path,
    Map<String, String> fields,
    List<String> filePaths,
    String fileFieldKey,
  ) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final headers = _headers(authenticated: true);
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields.addAll(fields);

    for (final filePath in filePaths) {
      if (filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(fileFieldKey, filePath),
        );
      }
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    final data = _decode(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const ApiException('Format response server tidak valid.');
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(authenticated: authenticated),
      body: jsonEncode(body),
    );
    final data = _decode(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const ApiException('Format response server tidak valid.');
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _client.get(_uri(path), headers: _headers());
    final data = _decode(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const ApiException('Format response server tidak valid.');
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers({bool authenticated = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'ngrok-skip-browser-warning': 'true',
    };
    if (authenticated && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    final activeProjectId = AppSession.activeProjectId.trim();
    if (activeProjectId.isNotEmpty) {
      headers['X-Project-ID'] = activeProjectId;
    }
    return headers;
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data is Map
        ? (data['message'] ?? data['detail'] ?? 'Request gagal.').toString()
        : 'Request gagal (${response.statusCode}).';
    throw ApiException(message);
  }

  ProfileResult _profileFromWrappedResponse(Map<String, dynamic> data) {
    final profileData = data['profile'];
    if (profileData is Map<String, dynamic>) {
      return ProfileResult.fromJson(profileData);
    }
    if (profileData is Map) {
      return ProfileResult.fromJson(profileData.cast<String, dynamic>());
    }
    throw const ApiException('Format profil dari server tidak valid.');
  }
}
