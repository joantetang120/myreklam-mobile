import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:myreklam/services/app_update_service.dart';
import 'package:myreklam/services/update_reminder_store.dart';
import 'package:myreklam/widgets/dot_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({
    required this.child,
    this.checkForRequiredUpdate,
    this.reminderStore,
    this.openStore,
    super.key,
  });

  final Widget child;
  final Future<AppUpdateRequirement?> Function()? checkForRequiredUpdate;
  final UpdateReminderStore? reminderStore;
  final Future<bool> Function(Uri)? openStore;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate>
    with WidgetsBindingObserver {
  late final UpdateReminderStore _reminders;
  AppUpdateRequirement? _requirement;
  bool _loading = true;
  bool _checking = false;
  bool _openingStore = false;
  String? _storeError;

  @override
  void initState() {
    super.initState();
    _reminders = widget.reminderStore ?? UpdateReminderStore();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        defaultTargetPlatform == TargetPlatform.iOS) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    AppUpdateRequirement? result;
    try {
      result =
          await (widget.checkForRequiredUpdate?.call() ??
                  AppUpdateService().checkForRequiredUpdate())
              .timeout(const Duration(seconds: 12));
      if (result?.platform == AppStorePlatform.ios) {
        final version = result?.storeVersion;
        if (version == null || !await _reminders.shouldPrompt(version)) {
          result = null;
        }
      }
    } catch (_) {
      // Offline, invalid lookup or plugin failure: no update lockout.
      result = null;
    } finally {
      _checking = false;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _requirement = result;
    });
  }

  Future<void> _postpone() async {
    final version = _requirement?.storeVersion;
    setState(() => _requirement = null);
    if (version != null) await _reminders.postpone(version);
  }

  Future<void> _openIosStore() async {
    final requirement = _requirement;
    if (_openingStore || requirement == null) return;
    setState(() {
      _openingStore = true;
      _storeError = null;
    });
    try {
      // Also suppress this release after visiting the store: an "Open" button
      // instead of "Update" must not trap the person in an immediate loop.
      await _reminders.postpone(requirement.storeVersion!);
      final opened =
          await (widget.openStore?.call(requirement.storeUri) ??
                  launchUrl(
                    requirement.storeUri,
                    mode: LaunchMode.externalApplication,
                  ))
              .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        if (opened) {
          _requirement = null;
        } else {
          _storeError =
              'Impossible d’ouvrir l’App Store. Réessayez ou choisissez « Plus tard ».';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _storeError =
              'Impossible d’ouvrir l’App Store. Vous pouvez continuer à utiliser l’application.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingStore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Google Play retains its existing loading screen and mandatory flow.
    if (_loading && defaultTargetPlatform != TargetPlatform.iOS) {
      return const _UpdateLoadingScreen();
    }
    final requirement = _requirement;
    if (requirement?.platform == AppStorePlatform.android) {
      return _RequiredUpdateScreen(requirement: requirement!);
    }
    // This gate wraps the Navigator, so replacing the splash route cannot
    // discard the lookup or the lifecycle observer before it finishes.
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (requirement?.platform == AppStorePlatform.ios) ...[
          ModalBarrier(
            color: Colors.black54,
            dismissible: true,
            onDismiss: _postpone,
          ),
          Center(
            child: AlertDialog(
              title: Text(requirement!.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(requirement.message),
                  if (_storeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _storeError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _postpone,
                  child: const Text('Plus tard'),
                ),
                FilledButton(
                  onPressed: _openingStore ? null : _openIosStore,
                  child: Text(_openingStore ? 'Ouverture…' : 'Mettre à jour'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _UpdateLoadingScreen extends StatelessWidget {
  const _UpdateLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdaptiveColors.surface(context, Colors.white),
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/images/splash.png',
              width: MediaQuery.sizeOf(context).width * 0.6,
              fit: BoxFit.contain,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: SafeArea(child: Center(child: DotLoader(size: 40))),
          ),
        ],
      ),
    );
  }
}

class _RequiredUpdateScreen extends StatefulWidget {
  const _RequiredUpdateScreen({required this.requirement});

  final AppUpdateRequirement requirement;

  @override
  State<_RequiredUpdateScreen> createState() => _RequiredUpdateScreenState();
}

class _RequiredUpdateScreenState extends State<_RequiredUpdateScreen> {
  bool _openingStore = false;

  Future<void> _openStore() async {
    if (_openingStore) return;
    setState(() => _openingStore = true);

    try {
      final immediateUpdate = widget.requirement.startImmediateUpdate;
      if (immediateUpdate != null) {
        await immediateUpdate();
        return;
      }
      final opened = await launchUrl(
        widget.requirement.storeUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showStoreError();
      }
    } catch (_) {
      if (mounted) _showStoreError();
    } finally {
      if (mounted) setState(() => _openingStore = false);
    }
  }

  void _showStoreError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Impossible d’ouvrir le store. Vérifiez votre connexion et réessayez.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeName = widget.requirement.platform == AppStorePlatform.android
        ? 'Google Play'
        : 'l’App Store';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AdaptiveColors.surface(context, Colors.white),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/splash.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 36),
                    Icon(
                      Icons.system_update_alt_rounded,
                      size: 52,
                      color: AdaptiveColors.foreground(
                        context,
                        Color(0xFF1B8D4B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.requirement.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AdaptiveColors.surface(
                              context,
                              const Color(0xFF17211B),
                            ),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.requirement.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                        color: AdaptiveColors.surface(
                          context,
                          const Color(0xFF526057),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _openingStore ? null : _openStore,
                        icon: _openingStore
                            ? SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AdaptiveColors.foreground(
                                    context,
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.open_in_new_rounded),
                        label: Text('Mettre à jour sur $storeName'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AdaptiveColors.surface(
                            context,
                            const Color(0xFF1B8D4B),
                          ),
                          foregroundColor: AdaptiveColors.foreground(
                            context,
                            Colors.white,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
