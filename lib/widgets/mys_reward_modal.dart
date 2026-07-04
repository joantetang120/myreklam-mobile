import 'package:flutter/material.dart';
import 'package:myreklam/utils/user_session.dart';

class MysRewardModal extends StatefulWidget {
  final num amount;
  final String actionType;
  final VoidCallback? onClose;

  const MysRewardModal({
    super.key,
    required this.amount,
    required this.actionType,
    this.onClose,
  });

  static Future<void> show(BuildContext context, {
    required num amount,
    required String actionType,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MysRewardModal(
        amount: amount,
        actionType: actionType,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<MysRewardModal> createState() => _MysRewardModalState();
}

class _MysRewardModalState extends State<MysRewardModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 20.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 20.0, end: -15.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -15.0, end: 10.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getActionDescription() {
    switch (widget.actionType) {
      case 'bon_plan':
        return 'Publication d\'un bon plan';
      case 'demande':
        return 'Publication d\'une demande';
      case 'evenement':
        return 'Publication d\'un événement';
      case 'formation':
        return 'Publication d\'une formation';
      case 'job_offer':
        return 'Publication d\'une offre d\'emploi';
      case 'profile_complete':
        return 'Profil complété';
      case 'profile_picture':
        return 'Photo de profil ajoutée';
      case 'social_media':
        return 'Réseau social ajouté';
      case 'phone_added':
        return 'Numéro de téléphone ajouté';
      case 'presentation':
        return 'Présentation ajoutée';
      case 'onboarding_complete':
        return 'Onboarding complété';
      case 'review':
        return 'Avis sur un profil entreprise';
      default:
        return 'Action réalisée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF8F1), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Coin Icon
                    Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    const Text(
                      'Félicitations !',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      _getActionDescription(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // My's Earned
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF9800).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_circle,
                            color: Color(0xFFFF9800),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.amount.toStringAsFixed(widget.amount is int || widget.amount == widget.amount.roundToDouble() ? 0 : 1)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/images/image-removebg-preview 2.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.monetization_on,
                                  color: Color(0xFFFF9800),
                                  size: 24,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // New Balance
                    ValueListenableBuilder<double>(
                      valueListenable: ValueNotifier<double>(UserSession().mys),
                      builder: (context, balance, child) {
                        return Text(
                          'Nouveau solde: ${UserSession().mys} My\'s',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Super !',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
