import 'package:flutter/material.dart';
import 'package:myreklam/services/app_update_service.dart';
import 'package:myreklam/widgets/dot_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({
    required this.child,
    this.checkForRequiredUpdate,
    super.key,
  });

  final Widget child;
  final Future<AppUpdateRequirement?> Function()? checkForRequiredUpdate;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  late final Future<AppUpdateRequirement?> _updateCheck;

  @override
  void initState() {
    super.initState();
    _updateCheck =
        widget.checkForRequiredUpdate?.call() ??
        AppUpdateService().checkForRequiredUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUpdateRequirement?>(
      future: _updateCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _UpdateLoadingScreen();
        }

        final requirement = snapshot.data;
        if (requirement == null) return widget.child;

        return _RequiredUpdateScreen(requirement: requirement);
      },
    );
  }
}

class _UpdateLoadingScreen extends StatelessWidget {
  const _UpdateLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        backgroundColor: Colors.white,
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
                    const Icon(
                      Icons.system_update_alt_rounded,
                      size: 52,
                      color: Color(0xFF1B8D4B),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.requirement.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17211B),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.requirement.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                        color: const Color(0xFF526057),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _openingStore ? null : _openStore,
                        icon: _openingStore
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.open_in_new_rounded),
                        label: Text('Mettre à jour sur $storeName'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8D4B),
                          foregroundColor: Colors.white,
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
