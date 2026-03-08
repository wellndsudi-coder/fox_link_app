import '../../infra/datasources/professional_remote_datasource.dart';

/// Returns professionals who offer the given base service (serviceIds contains baseServiceId).
class GetProfessionalsByServiceUseCase {
  final ProfessionalRemoteDataSource dataSource;

  GetProfessionalsByServiceUseCase(this.dataSource);

  Future<List<Map<String, dynamic>>> call(String baseServiceId) async {
    final all = await dataSource.getProfessionals();
    return all.where((p) {
      final ids = p['serviceIds'];
      if (ids == null) return true; // backward compat: no serviceIds = offers all
      if (ids is List) {
        return ids.any((id) => id == baseServiceId);
      }
      return false;
    }).toList();
  }
}
