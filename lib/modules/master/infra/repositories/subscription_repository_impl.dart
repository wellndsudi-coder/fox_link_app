import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource dataSource;

  SubscriptionRepositoryImpl(this.dataSource);

  @override
  Future<List<SubscriptionEntity>> getSubscriptions() async {
    try {
      return await dataSource.getSubscriptions();
    } catch (_) {
      return [];
    }
  }
}
