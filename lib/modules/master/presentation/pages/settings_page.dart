import 'package:flutter/material.dart';
import 'package:fox_link_app/modules/master/domain/entities/platform_settings_entity.dart';
import 'package:fox_link_app/modules/master/presentation/controllers/master_controller.dart';

class MasterSettingsPage extends StatefulWidget {
  final MasterController controller;

  const MasterSettingsPage({super.key, required this.controller});

  @override
  State<MasterSettingsPage> createState() => _MasterSettingsPageState();
}

class _MasterSettingsPageState extends State<MasterSettingsPage> {
  late final TextEditingController _platformNameController;
  late final TextEditingController _supportEmailController;
  late final TextEditingController _defaultTrialDaysController;
  late final TextEditingController _defaultPlanController;
  late final TextEditingController _platformDomainController;
  bool _saving = false;
  bool _hasPopulated = false;

  @override
  void initState() {
    super.initState();
    widget.controller.loadSettings();
    _platformNameController = TextEditingController();
    _supportEmailController = TextEditingController();
    _defaultTrialDaysController = TextEditingController(text: '30');
    _defaultPlanController = TextEditingController(text: 'basic');
    _platformDomainController = TextEditingController();
  }

  @override
  void dispose() {
    _platformNameController.dispose();
    _supportEmailController.dispose();
    _defaultTrialDaysController.dispose();
    _defaultPlanController.dispose();
    _platformDomainController.dispose();
    super.dispose();
  }

  void _populate(PlatformSettingsEntity? s) {
    if (s == null) return;
    _platformNameController.text = s.platformName;
    _supportEmailController.text = s.supportEmail;
    _defaultTrialDaysController.text = '${s.defaultTrialDays}';
    _defaultPlanController.text = s.defaultPlan;
    _platformDomainController.text = s.platformDomain;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.controller.saveSettings(PlatformSettingsEntity(
        platformName: _platformNameController.text.trim(),
        supportEmail: _supportEmailController.text.trim(),
        defaultTrialDays: int.tryParse(_defaultTrialDaysController.text) ?? 30,
        defaultPlan: _defaultPlanController.text.trim().isEmpty ? 'basic' : _defaultPlanController.text.trim(),
        platformDomain: _platformDomainController.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.settings;
        if (s != null && !_hasPopulated) {
          _hasPopulated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _populate(s));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _platformNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da plataforma',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _supportEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email de suporte',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _defaultTrialDaysController,
                decoration: const InputDecoration(
                  labelText: 'Dias de trial padrão',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _defaultPlanController,
                decoration: const InputDecoration(
                  labelText: 'Plano padrão',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _platformDomainController,
                decoration: const InputDecoration(
                  labelText: 'Domínio da plataforma',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
