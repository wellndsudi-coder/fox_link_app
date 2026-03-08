import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/white_label_config.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

final List<Color> _paletteColors = [
  const Color(0xFFF97316),
  const Color(0xFF2563EB),
  const Color(0xFF16A34A),
  const Color(0xFFEC4899),
  const Color(0xFF8B5CF6),
  const Color(0xFFEF4444),
  const Color(0xFF0EA5E9),
  const Color(0xFF64748B),
];

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

  Future<void> _onColorSelected(String type, Color color) async {
    if (_session.tenantId == null) return;
    final hex = WhiteLabelConfig.toHex(color);

    setState(() => _loading = true);
    try {
      await _tenantRemote.updateTenantConfig(
        tenantId: _session.tenantId!,
        primaryColor: type == 'primary' ? hex : null,
        secondaryColor: type == 'secondary' ? hex : null,
        accentColor: type == 'accent' ? hex : null,
      );
      await _whiteLabel.load(_session.tenantId!);
      if (mounted) {
        setState(() => _loading = false);
        final label = type == 'primary'
            ? 'principal'
            : type == 'secondary'
                ? 'secundária'
                : 'de destaque';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cor $label atualizada')),
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
                    _buildColorSection(
                      'Cor principal',
                      'primary',
                      config.primaryColor ?? Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    _buildColorSection(
                      'Cor secundária',
                      'secondary',
                      config.secondaryColor ?? config.primaryColor ?? Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    _buildColorSection(
                      'Cor de destaque',
                      'accent',
                      config.accentColor ?? Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
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

  Widget _buildColorSection(String label, String type, Color effectiveSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _paletteColors.map((color) {
              final isSelected = color == effectiveSelected;
              return GestureDetector(
                onTap: () => _onColorSelected(type, color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
