import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/theme_presets.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  final _session = getIt<TenantSession>();
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _whiteLabel = getIt<WhiteLabelService>();

  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && _session.tenantId != null) {
      setState(() => _loading = true);
      try {
        final url = await _tenantRemote.uploadLogo(
          tenantId: _session.tenantId!,
          file: File(picked.path),
        );
        await _tenantRemote.updateTenantConfig(
          tenantId: _session.tenantId!,
          logoUrl: url,
        );
        await _whiteLabel.load(_session.tenantId!);
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo atualizada')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  Future<void> _onPresetSelected(String presetName) async {
    if (_session.tenantId == null) return;
    setState(() => _loading = true);
    try {
      await _tenantRemote.updateTenantConfig(
        tenantId: _session.tenantId!,
        themePresetName: presetName,
      );
      await _whiteLabel.load(_session.tenantId!);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tema "$presetName" aplicado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _whiteLabel.config;

    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _whiteLabel,
              builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoSection(config.logoUrl),
                    const SizedBox(height: 24),
                    _buildThemePresetsSection(config.themePresetName),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildThemePresetsSection(String? selectedPresetName) {
    final presets = ThemePresets.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema do app',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Escolha um dos temas definidos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: presets.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border(context),
            ),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isSelected = preset.name == selectedPresetName;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: preset.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(
                  preset.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: preset.primary)
                    : null,
                onTap: _loading ? null : () => _onPresetSelected(preset.name),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(String? logoUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Text(
            'Logo do salão',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Imagem exibida no app',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
          ),
          const SizedBox(height: 16),
          if (logoUrl != null && logoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: Image.network(
                logoUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderLogo(),
              ),
            )
          else
            _placeholderLogo(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Alterar logo'),
          ),
        ],
      ),
    );
  }

  Widget _placeholderLogo() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.fillColor(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Icon(
        Icons.business,
        size: 40,
        color: AppColors.mutedForeground(context),
      ),
    );
  }

}
