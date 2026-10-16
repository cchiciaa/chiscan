import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chiscan_mobile/models/bill_session.dart';
import 'package:chiscan_mobile/repositories/bill_session_repository.dart';
import 'package:chiscan_mobile/services/bill_session_api_client.dart';

void main() {
  group('P6 Unit Test - Model & API Integration (BillSession)', () {
    test('1. Model Valid - berhasil mem-parsing JSON valid ke instance BillSession', () {
      final validJson = {
        'id': 'session-101',
        'title': 'Makan Siang Bareng',
        'hostName': 'Budi Santoso',
        'grandTotalAmount': 150000,
        'participantCount': 3,
      };

      final session = BillSession.fromJson(validJson);

      expect(session.id, 'session-101');
      expect(session.title, 'Makan Siang Bareng');
      expect(session.hostName, 'Budi Santoso');
      expect(session.grandTotalAmount, 150000);
      expect(session.participantCount, 3);
      expect(session.toJson(), validJson);
    });

    test('2. Model Invalid - melempar FormatException jika field wajib tidak ada atau tipe data salah', () {
      final invalidJsonMissingFields = {
        'grandTotalAmount': 50000,
        // missing 'id', 'title', 'hostName'
      };

      expect(
        () => BillSession.fromJson(invalidJsonMissingFields),
        throwsA(isA<FormatException>()),
      );

      final invalidJsonWrongType = {
        'id': 12345, // should be String
        'title': 'Makan Malam',
        'hostName': 'Andi',
      };

      expect(
        () => BillSession.fromJson(invalidJsonWrongType),
        throwsA(isA<FormatException>()),
      );
    });

    test('3. API Sukses - mengembalikan daftar BillSession saat HTTP 200 OK dengan data valid', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/sessions');
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode([
            {
              'id': 'api-1',
              'title': 'Kopi Sore',
              'hostName': 'Citra',
              'grandTotalAmount': 75000,
              'participantCount': 2,
            },
            {
              'id': 'api-2',
              'title': 'Pizza Malam',
              'hostName': 'Dimas',
              'grandTotalAmount': 240000,
              'participantCount': 5,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = BillSessionApiClient(client: mockClient, baseUrl: 'http://example.com/api');
      final repository = ApiBillSessionRepository(apiClient: apiClient);

      final sessions = await repository.fetchSessions();

      expect(sessions.length, 2);
      expect(sessions[0].id, 'api-1');
      expect(sessions[0].title, 'Kopi Sore');
      expect(sessions[0].hostName, 'Citra');
      expect(sessions[0].grandTotalAmount, 75000);
      expect(sessions[1].id, 'api-2');
      expect(sessions[1].title, 'Pizza Malam');
      expect(sessions[1].grandTotalAmount, 240000);
    });

    test('4. Data Kosong - mengembalikan List kosong saat HTTP 200 OK dengan array kosong []', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/sessions');
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = BillSessionApiClient(client: mockClient, baseUrl: 'http://example.com/api');
      final repository = ApiBillSessionRepository(apiClient: apiClient);

      final sessions = await repository.fetchSessions();

      expect(sessions, isEmpty);
      expect(sessions.length, 0);
    });

    test('5. HTTP Gagal - melempar ApiException saat server merespon dengan status code 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = BillSessionApiClient(client: mockClient, baseUrl: 'http://example.com/api');
      final repository = ApiBillSessionRepository(apiClient: apiClient);

      expect(
        () => repository.fetchSessions(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('6. JSON Rusak - melempar ApiException saat response body bukan JSON yang valid', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"invalid_json: true, missing_bracket',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = BillSessionApiClient(client: mockClient, baseUrl: 'http://example.com/api');
      final repository = ApiBillSessionRepository(apiClient: apiClient);

      expect(
        () => repository.fetchSessions(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('JSON rusak'),
          ),
        ),
      );
    });

    test('7. Penyimpanan ke Backend (POST API) - berhasil menyimpan data sesi baru ke server', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/sessions');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Nasi Goreng Spesial');
        expect(body['hostName'], 'Eko');

        return http.Response(
          jsonEncode({
            'id': 'api-created-99',
            'title': 'Nasi Goreng Spesial',
            'hostName': 'Eko',
            'grandTotalAmount': 0,
            'participantCount': 0,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = BillSessionApiClient(client: mockClient, baseUrl: 'http://example.com/api');
      final repository = ApiBillSessionRepository(apiClient: apiClient);

      final created = await repository.createSession(
        title: 'Nasi Goreng Spesial',
        hostName: 'Eko',
      );

      expect(created.id, 'api-created-99');
      expect(created.title, 'Nasi Goreng Spesial');
      expect(created.hostName, 'Eko');
    });
  });
}
