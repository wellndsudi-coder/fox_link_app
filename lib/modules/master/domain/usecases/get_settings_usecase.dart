import '../entities/platform_settings_entity.dart';
import '../repositories/master_repository.dart';

class GetSettingsUseCase {
  final MasterRepository repository;

  GetSettingsUseCase(this.repository);

  Future<PlatformSettingsEntity> call() => repository.getSettings();
}
