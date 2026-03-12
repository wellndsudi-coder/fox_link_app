import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_tenant_config_usecase.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class EditTenantPage extends StatefulWidget {
  const EditTenantPage({super.key});

  @override
  State<EditTenantPage> createState() => _EditTenantPageState();
}

class _EditTenantPageState extends State<EditTenantPage> {
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _session = getIt<TenantSession>();
  final _whiteLabel = getIt<WhiteLabelService>();
  final _getTenantConfig = getIt<GetTenantConfigUseCase>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _whiteLabel.config.name;
    _loadFullConfig();
  }

  Future<void> _loadFullConfig() async {
    if (_session.tenantId == null) return;
    try {
      final config = await _getTenantConfig(_session.tenantId!);
      if (!mounted) return;
      setState(() {
        _nameController.text = config.name;
        _phoneController.text = config.phone ?? '';
        _descriptionController.text = config.description ?? '';
        _addressController.text = config.address ?? '';
        _cityController.text = config.city ?? '';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && _session.tenantId != null) {
      setState(() => _loading = true);
      try {
        final bytes = await picked.readAsBytes();
        final url = await _tenantRemote.uploadLogo(
          tenantId: _session.tenantId!,
          bytes: bytes,
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

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _session.tenantId == null) return;

    setState(() => _loading = true);
    try {
      await _tenantRemote.updateTenantConfig(
        tenantId: _session.tenantId!,
        name: name,
      );
      await _whiteLabel.load(_session.tenantId!);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome atualizado')),
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

  Future<void> _saveSalonInfo() async {
    if (_session.tenantId == null) return;
    setState(() => _loading = true);
    try {
      await _tenantRemote.updateTenantConfig(
        tenantId: _session.tenantId!,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
      await _whiteLabel.load(_session.tenantId!);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informações do salão atualizadas')),
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
      appBar: AppBar(title: const Text('Editar Salão')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogoSection(config.logoUrl),
                  const SizedBox(height: 24),
                  _buildNameSection(),
                  const SizedBox(height: 24),
                  _buildSalonInfoSection(),
                  const SizedBox(height: 32),
                ],
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
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Alterar Logo'),
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
      child: Icon(Icons.business, size: 40, color: AppColors.mutedForeground(context)),
    );
  }

  Widget _buildSalonInfoSection() {
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
            'Informações do salão',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Endereço',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              hintText: 'Cidade',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Telefone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Descrição',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saveSalonInfo,
              child: const Text('Salvar informações'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
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
            'Nome do salão',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nome do salão',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saveName,
              child: const Text('Salvar nome'),
            ),
          ),
        ],
      ),
    );
  }

}
