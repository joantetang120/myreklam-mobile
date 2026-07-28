import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/services/api_client.dart';

void main() {
  test('accepts an empty successful API response', () {
    expect(parseApiResponse(http.Response('', 204)), isEmpty);
  });

  test('preserves a non-object successful response as data', () {
    expect(parseApiResponse(http.Response('[1,2]', 200)), {
      'data': [1, 2],
    });
  });

  test('turns invalid server error bodies into an ApiException', () {
    expect(
      () => parseApiResponse(http.Response('<html>error</html>', 500)),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having(
              (error) => error.message,
              'message',
              'Réponse invalide du serveur.',
            ),
      ),
    );
  });
}
