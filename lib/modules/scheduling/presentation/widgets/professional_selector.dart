import 'package:flutter/material.dart';

import 'professional_dropdown.dart';

/// Professional selection with SaaS card styling.
/// Wraps [ProfessionalDropdown] for consistent booking UI.
class ProfessionalSelector extends StatelessWidget {
  final String? selectedProfessionalId;
  final List<Map<String, dynamic>> professionals;
  final ValueChanged<String?> onChanged;

  const ProfessionalSelector({
    super.key,
    required this.selectedProfessionalId,
    required this.professionals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ProfessionalDropdown(
      selectedProfessionalId: selectedProfessionalId,
      professionals: professionals,
      onChanged: onChanged,
    );
  }
}
