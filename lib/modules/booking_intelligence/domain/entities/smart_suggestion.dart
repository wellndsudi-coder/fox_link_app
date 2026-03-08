class SmartSuggestion {
  final String label;
  final DateTime? dateTime;
  final String? serviceId;
  final String? professionalId;

  const SmartSuggestion({
    required this.label,
    this.dateTime,
    this.serviceId,
    this.professionalId,
  });
}
