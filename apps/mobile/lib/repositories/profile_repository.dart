import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/bill_session_api_client.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> fetchProfile();
  Future<UserProfile> updateProfile(UserProfile profile);
}

/// Implementasi API Repository: bertanggung jawab penuh pada request HTTP ke backend REST API
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'http://localhost:3000/api';

  final http.Client _client;
  final String baseUrl;

  @override
  Future<UserProfile> fetchProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Accept': 'application/json'},
    );

    return _processResponse(response, 'Gagal memuat profil dari server');
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(profile.toJson()),
    );

    return _processResponse(response, 'Gagal memperbarui profil di server');
  }

  UserProfile _processResponse(http.Response response, String defaultErrorMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseJsonBody(response.body, response.statusCode);
    } else {
      throw ApiException(
        '$defaultErrorMessage (${response.statusCode})',
        response.statusCode,
      );
    }
  }

  UserProfile _parseJsonBody(String body, int statusCode) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Format respons server bukan JSON objek.');
      }
      return UserProfile.fromJson(decoded);
    } on FormatException catch (e) {
      throw ApiException('Format data JSON rusak: ${e.message}', statusCode);
    } catch (e) {
      throw ApiException('Terjadi kesalahan pengolahan data: $e', statusCode);
    }
  }
}

/// Implementasi Local Repository via SharedPreferences untuk offline persistence
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository([SharedPreferences? preferences]) : _preferences = preferences;

  static const String storageKey = 'chiscan_user_profile';
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _storage async =>
      _preferences ??= await SharedPreferences.getInstance();

  @override
  Future<UserProfile> fetchProfile() async {
    final prefs = await _storage;
    final jsonString = prefs.getString(storageKey);
    if (jsonString == null) {
      await updateProfile(UserProfile.defaultProfile);
      return UserProfile.defaultProfile;
    }
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(decoded);
    } catch (_) {
      return UserProfile.defaultProfile;
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final prefs = await _storage;
    await prefs.setString(storageKey, jsonEncode(profile.toJson()));
    return profile;
  }
}

/// Implementasi In-Memory untuk unit testing dan preview cepat
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository({UserProfile? initialProfile})
      : _profile = initialProfile ?? UserProfile.defaultProfile;

  UserProfile _profile;

  @override
  Future<UserProfile> fetchProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile;
    return _profile;
  }
}
