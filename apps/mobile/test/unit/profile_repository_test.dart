import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chiscan_mobile/models/user_profile.dart';
import 'package:chiscan_mobile/repositories/profile_repository.dart';
import 'package:chiscan_mobile/services/bill_session_api_client.dart';

void main() {
  group('Pemisahan Tanggung Jawab - Profile Repository (API Requests)', () {
    test('1. fetchProfile API Sukses - memanggil endpoint GET /api/profile dan mem-parsing model', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/profile');
        return http.Response(
          jsonEncode({
            'id': 'user-100',
            'name': 'Budi Santoso',
            'email': 'budi@chiscan.app',
            'phoneNumber': '081299887766',
            'bankName': 'BCA',
            'accountNumber': '5410123456',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = ApiProfileRepository(client: mockClient, baseUrl: 'http://example.com/api');
      final profile = await repository.fetchProfile();

      expect(profile.id, 'user-100');
      expect(profile.name, 'Budi Santoso');
      expect(profile.email, 'budi@chiscan.app');
      expect(profile.phoneNumber, '081299887766');
      expect(profile.bankName, 'BCA');
      expect(profile.accountNumber, '5410123456');
    });

    test('2. updateProfile API Sukses - mengirim payload PUT /api/profile dan menerima hasil', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/profile');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Citra Lestari');
        expect(body['email'], 'citra@chiscan.app');

        return http.Response(
          jsonEncode({
            'id': 'user-200',
            'name': 'Citra Lestari',
            'email': 'citra@chiscan.app',
            'phoneNumber': '081377889900',
            'bankName': 'Mandiri',
            'accountNumber': '1370001234567',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = ApiProfileRepository(client: mockClient, baseUrl: 'http://example.com/api');
      final updated = await repository.updateProfile(
        const UserProfile(
          id: 'user-200',
          name: 'Citra Lestari',
          email: 'citra@chiscan.app',
          phoneNumber: '081377889900',
          bankName: 'Mandiri',
          accountNumber: '1370001234567',
        ),
      );

      expect(updated.name, 'Citra Lestari');
      expect(updated.bankName, 'Mandiri');
    });

    test('3. HTTP Gagal - melempar ApiException saat server merespon dengan status code 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = ApiProfileRepository(client: mockClient, baseUrl: 'http://example.com/api');

      expect(
        () => repository.fetchProfile(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('4. JSON Rusak - melempar ApiException saat body respons bukan format JSON valid', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"invalid_json_format', 200, headers: {'content-type': 'application/json'});
      });

      final repository = ApiProfileRepository(client: mockClient, baseUrl: 'http://example.com/api');

      expect(
        () => repository.fetchProfile(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('JSON rusak'))),
      );
    });
  });
}
