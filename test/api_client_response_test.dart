import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/services/api_client.dart';

void main() {
  test('preserves age-confirmation code for new social signup', () {
    expect(
      () => parseApiResponse(
        http.Response(
          '{"code":"AGE_CONFIRMATION_REQUIRED","message":"Confirmez votre âge"}',
          422,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'AGE_CONFIRMATION_REQUIRED',
        ),
      ),
    );
  });
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
