import 'package:equatable/equatable.dart';

/// Configurações da plataforma para o painel Master.
class PlatformSettingsEntity extends Equatable {
  final String platformName;
  final String supportEmail;
  final int defaultTrialDays;
  final String defaultPlan;
  final String platformDomain;

  const PlatformSettingsEntity({
    this.platformName = 'Fox Link',
    this.supportEmail = '',
    this.defaultTrialDays = 30,
    this.defaultPlan = 'basic',
    this.platformDomain = '',
  });

  @override
  List<Object?> get props =>
      [platformName, supportEmail, defaultTrialDays, defaultPlan, platformDomain];
}
