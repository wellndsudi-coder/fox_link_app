import '../entities/subscription_entity.dart';

/// Repositório de assinaturas para o módulo Master.
abstract class SubscriptionRepository {
  Future<List<SubscriptionEntity>> getSubscriptions();
}
