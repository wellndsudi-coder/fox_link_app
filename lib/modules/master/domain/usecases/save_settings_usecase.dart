import '../entities/platform_settings_entity.dart';
import '../repositories/master_repository.dart';

class SaveSettingsUseCase {
  final MasterRepository repository;

  SaveSettingsUseCase(this.repository);

  Future<void> call(PlatformSettingsEntity settings) =>
      repository.saveSettings(settings);
}
