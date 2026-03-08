class ClientHistoryItem {
  final String appointmentId;
  final String serviceId;
  final String serviceName;
  final String professionalId;
  final String professionalName;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;

  const ClientHistoryItem({
    required this.appointmentId,
    required this.serviceId,
    required this.serviceName,
    required this.professionalId,
    required this.professionalName,
    required this.scheduledStart,
    required this.scheduledEnd,
  });
}
