import 'package:flutter_test/flutter_test.dart';
import 'package:easy_mock_http/easy_mock_http.dart';

import 'examples.dart';

void main() {
  setUp(mockHttp.init);

  group('mockHttp', () {
    final cards = [
      {'id': 1, 'name': 'Almadar', 'quantity': 3},
      {'id': 2, 'name': 'Libyana', 'quantity': 2},
      {'id': 3, 'name': 'Ltt', 'quantity': 0},
    ];

    test('getProductsV1 returns the stubbed body', () async {
      // Arrange
      mockHttp.when.get(cardsUrl, response: cards);

      // Act
      final response = await getProductsV1();

      // Assert
      mockHttp.verify.get(cardsUrl).called(1);
      expect(response, cards);
    });

    test('getProductsV2 returns the stubbed body', () async {
      // Arrange
      mockHttp.when.get(cardsUrl, response: cards);

      // Act
      final response = await getProductsV2();

      // Assert
      mockHttp.verify.get(cardsUrl).called(1);
      expect(response, cards);
    });

    test('matches a stub by request header', () async {
      // Arrange
      mockHttp.when.get(
        cardsUrl,
        headers: {'Authorization': 'Bearer token-123'},
        response: cards,
      );

      // Act
      final response = await getProductsWithAuth('token-123');

      // Assert
      mockHttp.verify
          .get(cardsUrl, headers: {'Authorization': 'Bearer token-123'})
          .calledOnce;
      expect(response, cards);
    });

    test('matches a stub by query parameter', () async {
      // Arrange
      final page2 = [
        {'id': 4, 'name': 'Madar', 'quantity': 1},
      ];
      mockHttp.when.get(cardsUrl, query: {'page': 2}, response: page2);

      // Act
      final response = await getProductsPage(2);

      // Assert
      mockHttp.verify.get(cardsUrl, query: {'page': 2}).calledOnce;
      expect(response, page2);
    });

    test('applies the stubbed response delay', () async {
      // Arrange
      mockHttp.when.get(
        pingUrl,
        response: {'pong': true},
        delay: const Duration(milliseconds: 300),
      );
      final stopwatch = Stopwatch()..start();

      // Act
      final response = await ping();

      // Assert
      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 300)),
      );
      expect(response, {'pong': true});
    });

    test('propagates an injected network failure', () async {
      // Arrange
      mockHttp.when.get(cardsUrl, error: Exception('connection refused'));

      // Act
      final request = getProductsV1();

      // Assert
      await expectLater(request, throwsA(isA<Exception>()));
    });
  });
}
