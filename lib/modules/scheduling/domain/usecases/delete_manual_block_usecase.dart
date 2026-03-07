import '../repositories/manual_block_repository.dart';

class DeleteManualBlockUseCase {
  final ManualBlockRepository repository;

  DeleteManualBlockUseCase(this.repository);

  Future<void> call(String blockId) async {
    await repository.delete(blockId);
  }
}
