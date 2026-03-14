import 'package:cloud_firestore/cloud_firestore.dart';

/// Busca limites do plano na coleção Firestore "plans".
/// Usado para aplicar limites editados no Master.
class PlanLimitsRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna os limites do plano ou null se não existir no Firestore.
  Future<PlanLimits?> getPlanLimits(String planId) async {
    final doc = await _firestore
        .collection('plans')
        .doc(planId)
        .get(const GetOptions(source: Source.server));

    if (!doc.exists || doc.data() == null) return null;

    final d = doc.data()!;
    return PlanLimits(
      maxProfessionals: d['maxProfessionals'] as int? ?? 2,
      maxServices: d['maxServices'] as int? ?? 15,
      maxAddonServices: d['maxAddonServices'] as int? ?? 10,
      maxUsers: d['maxUsers'] as int? ?? 10,
    );
  }
}

class PlanLimits {
  final int maxProfessionals;
  final int maxServices;
  final int maxAddonServices;
  final int maxUsers;

  const PlanLimits({
    required this.maxProfessionals,
    required this.maxServices,
    required this.maxAddonServices,
    required this.maxUsers,
  });
}
