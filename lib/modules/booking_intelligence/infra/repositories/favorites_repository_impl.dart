import '../../domain/entities/favorite_professional.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource dataSource;

  FavoritesRepositoryImpl(this.dataSource);

  @override
  Future<void> add({
    required String clientId,
    required String professionalId,
    required String professionalName,
  }) =>
      dataSource.add(
        clientId: clientId,
        professionalId: professionalId,
        professionalName: professionalName,
      );

  @override
  Future<void> remove({
    required String clientId,
    required String professionalId,
  }) =>
      dataSource.remove(
        clientId: clientId,
        professionalId: professionalId,
      );

  @override
  Future<List<FavoriteProfessional>> getByClient(String clientId) =>
      dataSource.getByClient(clientId);

  @override
  Future<bool> isFavorite({
    required String clientId,
    required String professionalId,
  }) =>
      dataSource.isFavorite(
        clientId: clientId,
        professionalId: professionalId,
      );
}
