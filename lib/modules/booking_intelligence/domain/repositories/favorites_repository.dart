import '../entities/favorite_professional.dart';

abstract class FavoritesRepository {
  Future<void> add({
    required String clientId,
    required String professionalId,
    required String professionalName,
  });

  Future<void> remove({
    required String clientId,
    required String professionalId,
  });

  Future<List<FavoriteProfessional>> getByClient(String clientId);

  Future<bool> isFavorite({
    required String clientId,
    required String professionalId,
  });
}
