import '../entities/manual_block.dart';
import '../repositories/manual_block_repository.dart';

class SaveManualBlockUseCase {
  final ManualBlockRepository repository;

  SaveManualBlockUseCase(this.repository);

  Future<void> call(ManualBlock block) async {
    if (!block.start.isBefore(block.end)) {
      throw Exception('Horário de início deve ser anterior ao fim.');
    }
    await repository.save(block);
  }
}
