import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill_session.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class BillSessionApiClient {
  BillSessionApiClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'http://localhost:3000/api';

  final http.Client _client;
  final String baseUrl;

  Future<List<BillSession>> getSessions() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw const FormatException('Format response bukan JSON array.');
        }
        return decoded
            .map((item) => BillSession.fromJson(item as Map<String, dynamic>))
            .toList();
      } on FormatException catch (e) {
        throw ApiException('JSON rusak atau format tidak valid: ${e.message}', response.statusCode);
      } catch (e) {
        throw ApiException('Terjadi kesalahan pengolahan data: $e', response.statusCode);
      }
    } else {
      throw ApiException(
        'Gagal memuat sesi dari server (${response.statusCode})',
        response.statusCode,
      );
    }
  }

  Future<BillSession> createSession({
    required String title,
    required String hostName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'hostName': hostName,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic decoded = jsonDecode(response.body);
        return BillSession.fromJson(decoded as Map<String, dynamic>);
      } on FormatException catch (e) {
        throw ApiException('Format response server rusak: ${e.message}', response.statusCode);
      }
    } else {
      throw ApiException(
        'Gagal membuat sesi di server (${response.statusCode})',
        response.statusCode,
      );
    }
  }

  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/sessions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'hostName': hostName,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic decoded = jsonDecode(response.body);
        return BillSession.fromJson(decoded as Map<String, dynamic>);
      } on FormatException catch (e) {
        throw ApiException('Format response server rusak: ${e.message}', response.statusCode);
      }
    } else {
      throw ApiException(
        'Gagal memperbarui sesi di server (${response.statusCode})',
        response.statusCode,
      );
    }
  }

  Future<void> deleteSession(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/sessions/$id'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Gagal menghapus sesi di server (${response.statusCode})',
        response.statusCode,
      );
    }
  }
}
