class WaitlistEntry {
  final String id;
  final String clientName;
  final String? clientPhone;
  final String serviceName;
  final String? serviceId;
  final String? clientId;
  final String? professionalId;
  final DateTime desiredDate;
  final DateTime createdAt;
  final WaitlistStatus status;

  const WaitlistEntry({
    required this.id,
    required this.clientName,
    this.clientPhone,
    required this.serviceName,
    this.serviceId,
    this.clientId,
    this.professionalId,
    required this.desiredDate,
    required this.createdAt,
    required this.status,
  });
}

enum WaitlistStatus {
  waiting,
  offered,
  scheduled,
  cancelled,
}
