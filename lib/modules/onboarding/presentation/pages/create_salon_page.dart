import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/auth/domain/entities/onboarding_data.dart';
import 'package:fox_link_app/core/widgets/admin_shell.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/onboarding_page.dart';

class CreateSalonPage extends StatefulWidget {
  final OnboardingData data;

  const CreateSalonPage({
    super.key,
    required this.data,
  });

  @override
  State<CreateSalonPage> createState() => _CreateSalonPageState();
}

class _CreateSalonPageState extends State<CreateSalonPage> {
  final _salonNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _userRemote = getIt<UserRemoteDataSource>();
  final _professionalRemote = getIt<ProfessionalRemoteDataSource>();
  final _session = getIt<TenantSession>();

  File? selectedImage;
  bool _isLoading = false;
  bool _alsoAttendsClients = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.data.phone;
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (file != null) {
      setState(() => selectedImage = File(file.path));
    }
  }

  Future<void> _create() async {
    if (_salonNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do salão.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tenantId = await _tenantRemote.createTenant(
        name: _salonNameController.text.trim(),
        ownerId: widget.data.uid,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
      );

      if (selectedImage != null) {
        final logoUrl = await _tenantRemote.uploadLogo(
          tenantId: tenantId,
          file: selectedImage!,
        );

        await FirebaseFirestore.instance
            .collection('tenants')
            .doc(tenantId)
            .update({'logoUrl': logoUrl});
      }

      final roles = ['owner'];
      String? professionalId;

      if (_alsoAttendsClients) {
        professionalId = await _professionalRemote.createProfessionalAsOwner(
          tenantId: tenantId,
          uid: widget.data.uid,
          name: widget.data.name,
          email: widget.data.email,
        );
        roles.add('professional');
      }

      await _userRemote.createUser(
        uid: widget.data.uid,
        email: widget.data.email,
        role: 'owner',
        tenantId: tenantId,
        name: widget.data.name,
        phone: widget.data.phone,
        roles: roles,
      );

      _session.setSessionWithRoles(
        tenantId: tenantId,
        roles: roles,
        uid: widget.data.uid,
        email: widget.data.email,
      );
      if (professionalId != null) {
        _session.setProfessionalId(professionalId);
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.fillColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OnboardingPage(data: widget.data),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back,
                        size: 18, color: AppColors.mutedForeground(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Criar salão',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Informe os dados do seu estabelecimento',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground(context),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Nome do salão',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _salonNameController,
                decoration: _inputDecoration(context, 'Studio Hair'),
              ),

              const SizedBox(height: 16),

              Text(
                'Endereço',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: _inputDecoration(context, 'Rua das Flores, 123'),
              ),

              const SizedBox(height: 16),

              Text(
                'Cidade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cityController,
                decoration: _inputDecoration(context, 'São Paulo'),
              ),

              const SizedBox(height: 16),

              Text(
                'Telefone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(context, '(11) 3333-4444'),
              ),

              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _alsoAttendsClients,
                    onChanged: (v) {
                      setState(() => _alsoAttendsClients = v ?? false);
                    },
                    activeColor: AppColors.primary(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Também atendo clientes',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Você aparecerá na agenda e poderá receber agendamentos',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Criar salão',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
