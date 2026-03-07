import '../entities/manual_block.dart';
import '../repositories/manual_block_repository.dart';

class GetManualBlocksByPeriodUseCase {
  final ManualBlockRepository repository;

  GetManualBlocksByPeriodUseCase(this.repository);

  Future<List<ManualBlock>> call({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  }) {
    return repository.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: start,
      end: end,
    );
  }
}
