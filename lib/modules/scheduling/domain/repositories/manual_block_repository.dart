import '../entities/manual_block.dart';

abstract class ManualBlockRepository {
  Future<void> save(ManualBlock block);
  Future<void> delete(String blockId);
  Future<List<ManualBlock>> getByProfessionalAndPeriod({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  });
}
