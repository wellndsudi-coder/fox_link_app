class SoonestSlots {
  final List<SoonestSlot> slots;

  const SoonestSlots({required this.slots});
}

class SoonestSlot {
  final DateTime dateTime;
  final String professionalId;
  final String professionalName;
  final String serviceId;
  final int minutesFromNow;

  const SoonestSlot({
    required this.dateTime,
    required this.professionalId,
    required this.professionalName,
    required this.serviceId,
    required this.minutesFromNow,
  });
}
