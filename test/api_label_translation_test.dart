import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/constants/annonce_status_labels.dart';
import 'package:myreklam/constants/demande_natures.dart';
import 'package:myreklam/constants/job_labels.dart';
import 'package:myreklam/constants/reward_action_labels.dart';

/// Guards against the regression where an API code reached the UI verbatim
/// (`searchjob`, `INTERIM`, `MEAL_VOUCHERS`, `profile_picture`, ...).
void main() {
  group('DemandeNatures', () {
    test('translates the codes returned by the categories API', () {
      expect(DemandeNatures.label('searchjob'), 'Recherche d\'emploi');
      expect(DemandeNatures.label('realestate'), 'Immobilier');
      expect(DemandeNatures.label('servicehelp'), 'Services / Aide');
      expect(DemandeNatures.label('fashion'), 'Mode');
      expect(DemandeNatures.label('multimedia'), 'Multimédia');
    });

    test('still translates the legacy French codes', () {
      expect(DemandeNatures.label('emploi'), 'Recherche d\'emploi');
      expect(DemandeNatures.label('logement'), 'Immobilier');
    });

    test('never leaks a raw code or an empty chip', () {
      expect(DemandeNatures.label('brand_new_code'), 'Brand new code');
      expect(DemandeNatures.label(null), 'Demande');
      expect(DemandeNatures.label('  '), 'Demande');
    });
  });

  group('JobLabels', () {
    test('translates every work time and contract type', () {
      expect(JobLabels.label('FULL_TIME'), 'Temps plein');
      expect(JobLabels.label('INTERIM'), 'Intérim');
      expect(JobLabels.label('ALTERNANCE'), 'Alternance');
      expect(JobLabels.label('CDI'), 'CDI');
      expect(JobLabels.label('SEASONAL'), 'Saisonnier');
    });

    test('translates the advantages shown as checkbox labels', () {
      expect(JobLabels.label('MEAL_VOUCHERS'), 'Titre restaurant');
      expect(JobLabels.label('REMOTE_WORK'), 'Télétravail');
      expect(JobLabels.label('COMPANY_CAR'), 'Voiture de fonction');
      expect(JobLabels.label('THIRTEENTH_MONTH'), '13ème mois');
    });

    test('accepts the lowercase variant some endpoints return', () {
      expect(JobLabels.label('full_time'), 'Temps plein');
      expect(JobLabels.label('internship'), 'Stage');
    });

    test('leaves an already translated label untouched', () {
      expect(JobLabels.label('Temps plein'), 'Temps plein');
      expect(JobLabels.label('Voiture de fonction'), 'Voiture de fonction');
    });

    test('humanizes an unknown code instead of leaking it', () {
      expect(JobLabels.label('NEW_BENEFIT'), 'New benefit');
      expect(JobLabels.label(null), '');
    });
  });

  group('AnnonceStatusLabels', () {
    test('translates the publication statuses', () {
      expect(AnnonceStatusLabels.label('PUBLISHED'), 'Publié');
      expect(AnnonceStatusLabels.label('PENDING_REVIEW'), 'En attente');
      expect(AnnonceStatusLabels.label('pending_review'), 'En attente');
      expect(AnnonceStatusLabels.label('ARCHIVED'), 'Archivé');
    });

    test('humanizes an unknown status', () {
      expect(AnnonceStatusLabels.label('UNDER_APPEAL'), 'Under appeal');
      expect(AnnonceStatusLabels.label(null), '');
    });
  });

  group('RewardActionLabels', () {
    test('translates the actions missing from the rewards screens', () {
      expect(RewardActionLabels.label('registration'), 'Inscription');
      expect(RewardActionLabels.label('profile_picture'), 'Photo de profil');
      expect(RewardActionLabels.label('phone_added'), 'Numéro de téléphone');
      expect(RewardActionLabels.label('social_media'), 'Réseau social');
    });

    test('keeps translating the historical actions', () {
      expect(RewardActionLabels.label('bon_plan'), 'Bon plan');
      expect(RewardActionLabels.label('mys_conversion'), 'Conversion récompense');
      expect(RewardActionLabels.label(null), 'Action');
    });
  });
}
