import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'professional_availability_page.dart';

/// Admin: editar horários de qualquer profissional.
class AdminProfessionalAvailabilityPage extends StatelessWidget {
  final String professionalId;
  final String? professionalName;

  const AdminProfessionalAvailabilityPage({
    super.key,
    required this.professionalId,
    this.professionalName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          professionalName != null
              ? 'Horários: $professionalName'
              : 'Horários do profissional',
        ),
      ),
      body: ProfessionalAvailabilityPage(
        professionalIdOverride: professionalId,
      ),
    );
  }
}
