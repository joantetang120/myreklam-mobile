import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';

/// Permission keys a manager can be granted (must match the backend).
class DelegationPermission {
  static const String announcements = 'announcements';
  static const String posts = 'posts';
  static const String messages = 'messages';
  static const String editAccount = 'edit_account';
  static const String manageSubscription = 'manage_subscription';

  static const List<String> all = [
    announcements,
    posts,
    messages,
    editAccount,
    manageSubscription,
  ];

  /// Human-readable French label + icon for a permission key.
  static String label(String key) {
    switch (key) {
      case announcements:
        return 'Créer / modifier / supprimer des annonces';
      case posts:
        return 'Créer / modifier / supprimer des posts';
      case messages:
        return 'Répondre et envoyer des messages';
      case editAccount:
        return 'Modifier le compte';
      case manageSubscription:
        return "Gérer l'abonnement";
      default:
        return key;
    }
  }

  static IconData icon(String key) {
    switch (key) {
      case announcements:
        return Icons.campaign_outlined;
      case posts:
        return Icons.post_add_outlined;
      case messages:
        return Icons.chat_bubble_outline;
      case editAccount:
        return Icons.manage_accounts_outlined;
      case manageSubscription:
        return Icons.workspace_premium_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }
}

/// A counterpart user in a delegation (the manager, or the owner).
class DelegationUser {
  final int id;
  final String name;
  final String? email;
  final String? avatar;
  final String? accountType;

  DelegationUser({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.accountType,
  });

  factory DelegationUser.fromJson(Map<String, dynamic> json) {
    return DelegationUser(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Utilisateur',
      email: json['email']?.toString(),
      avatar: ApiConfig.resolveMediaUrl(json['avatar']?.toString()),
      accountType: json['account_type']?.toString(),
    );
  }
}

/// A delegation row. [user] is the counterpart (manager when viewed by the
/// owner, owner when viewed by the manager).
class Delegation {
  final int id;
  final int ownerId;
  final int managerId;
  final List<String> permissions;
  final bool isPaidSeat;
  final DelegationUser? user;

  Delegation({
    required this.id,
    required this.ownerId,
    required this.managerId,
    required this.permissions,
    required this.isPaidSeat,
    this.user,
  });

  factory Delegation.fromJson(Map<String, dynamic> json) {
    return Delegation(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ownerId: int.tryParse(json['owner_id']?.toString() ?? '0') ?? 0,
      managerId: int.tryParse(json['manager_id']?.toString() ?? '0') ?? 0,
      permissions: (json['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isPaidSeat: json['is_paid_seat'] == true,
      user: json['user'] is Map
          ? DelegationUser.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
    );
  }
}
