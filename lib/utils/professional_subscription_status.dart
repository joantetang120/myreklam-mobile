class ProfessionalSubscriptionStatus {
  const ProfessionalSubscriptionStatus({
    required this.isPremium,
    required this.label,
  });

  final bool isPremium;
  final String label;
}

/// Resolves the public status of a professional account from a profile API
/// response. Missing or ambiguous data is treated as non-premium so the UI
/// never awards a paid badge without proof of an active paid subscription.
ProfessionalSubscriptionStatus resolveProfessionalSubscriptionStatus(
  Map<String, dynamic>? profileResponse, {
  DateTime? now,
}) {
  final subscription = _extractSubscription(profileResponse);
  if (subscription == null || subscription.isEmpty) {
    return const ProfessionalSubscriptionStatus(
      isPremium: false,
      label: 'Basic',
    );
  }

  final plan = subscription['plan']?.toString().trim().toLowerCase() ?? '';
  final status = subscription['status']?.toString().trim().toLowerCase() ?? '';
  final isPaidPlan = const {
    'premium',
    'monthly',
    'annual',
    'yearly',
  }.contains(plan);
  final isActive = status == 'active';
  final endDate = DateTime.tryParse(subscription['end_date']?.toString() ?? '');
  final referenceTime = now ?? DateTime.now();
  final isExpired = endDate != null && !referenceTime.isBefore(endDate);

  if (isPaidPlan && isActive && !isExpired) {
    return const ProfessionalSubscriptionStatus(
      isPremium: true,
      label: 'Premium ⭐️',
    );
  }

  return const ProfessionalSubscriptionStatus(isPremium: false, label: 'Basic');
}

Map<String, dynamic>? _extractSubscription(
  Map<String, dynamic>? profileResponse,
) {
  if (profileResponse == null) return null;

  for (final source in [
    profileResponse,
    profileResponse['user'],
    profileResponse['profile'],
  ]) {
    if (source is! Map) continue;
    final subscription = source['subscription'];
    if (subscription is Map) {
      return Map<String, dynamic>.from(subscription);
    }

    final plan = source['subscription_plan'];
    final status = source['subscription_status'];
    if (plan != null || status != null) {
      return <String, dynamic>{
        'plan': plan,
        'status': status,
        'end_date': source['subscription_end_date'],
      };
    }
  }

  return null;
}
