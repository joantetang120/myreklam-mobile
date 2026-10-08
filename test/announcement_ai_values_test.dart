import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/announcement_ai_values.dart';
import 'package:myreklam/services/announcement_ai_service.dart';
import 'package:myreklam/services/api_client.dart';

void main() {
  test(
    'API pictures are materialized with bytes for every upload workflow',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'myreklam-ai-test-',
      );
      try {
        final images = await AnnouncementAiService().materializeImages([
          {'mime': 'image/jpeg', 'base64': 'YQ=='},
          {'mime': 'image/jpeg', 'base64': 'not base64!'},
          {'mime': 'text/html', 'base64': 'YQ=='},
        ], destination: directory);
        expect(images, hasLength(1));
        expect(images.single.bytes, [97]);
        expect(await File(images.single.path).readAsBytes(), [97]);
        expect(images.single.extension, 'jpg');
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  test('option matching does not select unknown or ambiguous defaults', () {
    expect(AnnouncementAiValues.option('cdi', ['CDI', 'CDD']), 'CDI');
    expect(AnnouncementAiValues.option('UNKNOWN', ['CDI', 'CDD']), isNull);
    expect(AnnouncementAiValues.option('cdi', ['CDI', 'cdi']), isNull);
  });
  test('training keys and job labels preserve their API representation', () {
    expect(
      AnnouncementAiValues.key('À distance', {'distance': 'À distance'}),
      'distance',
    );
    expect(
      AnnouncementAiValues.option('FULL_TIME', [
        'Temps plein',
      ], apiValue: (_) => 'FULL_TIME'),
      'Temps plein',
    );
    expect(
      AnnouncementAiValues.keys(
        ['distance', 'Inconnu'],
        {'distance': 'À distance'},
      ),
      ['distance'],
    );
  });
  test(
    'categories match labels/codes without choosing an ambiguous company',
    () {
      expect(
        AnnouncementAiValues.category('BTP', [
          {'id': 12, 'name': 'BTP'},
        ])?['id'],
        12,
      );
      expect(
        AnnouncementAiValues.category('BTP', [
          {'id': 12, 'name': 'BTP'},
          {'id': 13, 'name': 'BTP'},
        ]),
        isNull,
      );
      expect(
        AnnouncementAiValues.category('music', [
          {'code': 'music', 'label': 'Musique'},
        ])?['code'],
        'music',
      );
    },
  );
  test('dates reject overflow and dates without an explicit year', () {
    expect(AnnouncementAiValues.date('2026-02-30'), isNull);
    expect(AnnouncementAiValues.date('07/10'), isNull);
    expect(AnnouncementAiValues.date('2026-10-07')?.year, 2026);
  });
  test('times reject invalid hours and minutes', () {
    expect(AnnouncementAiValues.time('24:00'), isNull);
    expect(AnnouncementAiValues.time('10:70'), isNull);
    expect(AnnouncementAiValues.time('09:30')?.minute, 30);
  });
  test('prices retain zero and decimals, reject negatives and infinity', () {
    expect(AnnouncementAiValues.number('0'), '0');
    expect(AnnouncementAiValues.number('129,99'), '129.99');
    expect(AnnouncementAiValues.number('-1'), isNull);
    expect(AnnouncementAiValues.number('NaN'), isNull);
    expect(AnnouncementAiValues.number('Infinity'), isNull);
  });
  test('empty and malformed extraction results are explicit failures', () {
    for (final response in <Map<String, dynamic>>[
      {},
      {'data': {}},
      {
        'data': {'fields': {}},
      },
      {
        'data': {
          'fields': {'title': null},
        },
      },
    ]) {
      expect(
        () => AnnouncementAiResult.parse(response),
        throwsA(isA<ApiException>()),
      );
    }
  });
  test(
    'partial fields keep warnings and missing fields without fake values',
    () {
      final result = AnnouncementAiResult.parse({
        'data': {
          'fields': {'title': 'Affiche', 'price': null},
          'warnings': ['Prix absent'],
          'missing_fields': ['price'],
        },
      });
      expect(result.fields, {'title': 'Affiche'});
      expect(result.warnings, ['Prix absent']);
      expect(result.missingFields, ['price']);
    },
  );
  test('returned pictures use the existing mime and base64 contract', () {
    final result = AnnouncementAiResult.parse({
      'data': {
        'fields': {},
        'media': [
          {'mime': 'image/jpeg', 'base64': 'YQ=='},
        ],
      },
    });
    expect(result.media.single['mime'], 'image/jpeg');
    expect(result.fields, isEmpty);
  });
  test('requests support exactly the four types and exclude demandes', () {
    expect(AnnouncementAiService.kinds, [
      'bonplans',
      'job-offers',
      'events',
      'trainings',
    ]);
    expect(AnnouncementAiService.timeout, const Duration(minutes: 2));
  });
}
