import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/theme/app_theme.dart';
import 'package:myreklam/theme/theme_controller.dart';
import 'package:myreklam/widgets/appearance_settings.dart';
import 'package:myreklam/widgets/post_card.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

Widget harness(ThemeController controller, {Widget? child}) =>
    ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.mode,
        home: Scaffold(
          body: child ?? AppearanceSettings(controller: controller),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to automatic and invalid stored preference is safe', () async {
    final controller = ThemeController();
    await controller.load();
    expect(controller.mode, ThemeMode.system);
    SharedPreferences.setMockInitialValues({
      ThemeController.storageKey: 'invalid',
    });
    await controller.load();
    expect(controller.mode, ThemeMode.system);
    controller.dispose();
  });

  test('all three choices persist across controller reloads', () async {
    final controller = ThemeController();
    for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
      await controller.setMode(mode);
      final restarted = ThemeController();
      await restarted.load();
      expect(restarted.mode, mode);
      restarted.dispose();
    }
    controller.dispose();
  });

  test(
    'failed persistence preserves the previous choice and clears busy state',
    () async {
      final controller = ThemeController(persistMode: (_) async => false);
      await expectLater(controller.setMode(ThemeMode.dark), throwsStateError);
      expect(controller.mode, ThemeMode.system);
      expect(controller.saving, isFalse);
      controller.dispose();
    },
  );

  testWidgets('changing theme preserves the current route', (tester) async {
    final controller = ThemeController();
    await tester.pumpWidget(harness(controller));
    final context = tester.element(find.byType(AppearanceSettings));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Écran conservé')),
      ),
    );
    await tester.pumpAndSettle();
    await controller.setMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(find.text('Écran conservé'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Écran conservé'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets(
    'automatic follows OS and explicit choice overrides OS immediately',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final controller = ThemeController();
      await tester.pumpWidget(harness(controller));
      expect(
        Theme.of(tester.element(find.byType(AppearanceSettings))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byType(DropdownButton<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clair').last);
      await tester.pumpAndSettle();
      expect(controller.mode, ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(AppearanceSettings))).brightness,
        Brightness.light,
      );
      await controller.setMode(ThemeMode.system);
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(AppearanceSettings))).brightness,
        Brightness.light,
      );
    },
  );

  testWidgets(
    'legacy surfaces and text are readable; light and media white stay unchanged',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      final surface = AdaptiveColors.surface(context, Colors.white);
      final text = AdaptiveColors.foreground(context, const Color(0xFF333333));
      final contrast =
          (text.computeLuminance() + .05) / (surface.computeLuminance() + .05);
      expect(contrast, greaterThanOrEqualTo(4.5));
      expect(AdaptiveColors.foreground(context, Colors.white), Colors.white);
      expect(AdaptiveColors.surface(context, Colors.transparent).a, 0);
      expect(
        AdaptiveColors.surface(context, const Color(0xFF1B8D4B)),
        const Color(0xFF1B8D4B),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(AdaptiveColors.surface(context, Colors.white), Colors.white);
      expect(AdaptiveColors.foreground(context, Colors.black), Colors.black);
    },
  );

  testWidgets('feed card and avatar change colours without losing content', (
    tester,
  ) async {
    final controller = ThemeController();
    await controller.setMode(ThemeMode.dark);
    await tester.pumpWidget(
      harness(
        controller,
        child: const SingleChildScrollView(
          child: PostCard(
            profileImage: '',
            username: 'Louis',
            userType: 'Particulier',
            postText: 'Publication test',
            postImage: null,
            likesCount: 2,
            commentsCount: 1,
            timeAgo: 'Il y a 1 h',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Publication test'), findsOneWidget);
    expect(find.byType(ReklamAvatar), findsOneWidget);
    final body = tester.widget<Text>(find.text('Publication test'));
    expect(body.style!.color!.computeLuminance(), greaterThan(.4));
    await controller.setMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(find.text('Publication test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings remain usable on a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ThemeController();
    await controller.setMode(ThemeMode.dark);
    await tester.pumpWidget(
      harness(
        controller,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: AppearanceSettings(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Apparence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'forms never create a new light theme or force a light colour scheme',
    () {
      for (final file
          in Directory('lib/screens')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        expect(
          RegExp(r'data:\s*ThemeData\(').hasMatch(source),
          isFalse,
          reason: file.path,
        );
        expect(
          source.contains('ColorScheme.light('),
          isFalse,
          reason: file.path,
        );
      }
    },
  );

  testWidgets(
    'render light and dark previews of shared feed and settings components',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/Manjari-Regular.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final controller = ThemeController();
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await controller.setMode(mode);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: harness(
              controller,
              child: ListView(
                children: [
                  const SizedBox(height: 32),
                  const ListTile(
                    title: Text(
                      'Mon espace',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppearanceSettings(controller: controller),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Rechercher sur MyReklam',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const PostCard(
                    profileImage: '',
                    username: 'Louis',
                    userType: 'Particulier',
                    postText:
                        'Des bons plans et des idées à partager avec la communauté.',
                    postImage: null,
                    likesCount: 12,
                    commentsCount: 3,
                    timeAgo: 'Il y a 1 h',
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Publier une annonce'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/theme-previews')
            ..createSync(recursive: true);
          await File(
            '${directory.path}/${mode.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
}
