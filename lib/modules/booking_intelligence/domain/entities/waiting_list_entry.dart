class WaitingListEntry {
  final String id;
  final String clientId;
  final String serviceId;
  final String? professionalId;
  final DateTime desiredDate;
  final DateTime? desiredTime;
  final DateTime createdAt;
  final WaitingListStatus status;
  final DateTime? offeredSlotStart;
  final DateTime? offeredSlotEnd;
  final DateTime? offeredAt;

  const WaitingListEntry({
    required this.id,
    required this.clientId,
    required this.serviceId,
    this.professionalId,
    required this.desiredDate,
    this.desiredTime,
    required this.createdAt,
    required this.status,
    this.offeredSlotStart,
    this.offeredSlotEnd,
    this.offeredAt,
  });
}

enum WaitingListStatus {
  pending,
  slotOffered,
  professionalConfirmed,
  clientNotified,
  cancelled,
  notified, // legacy alias for clientNotified
}
