import '../entities/waiting_list_entry.dart';

abstract class WaitingListRepository {
  Future<void> add({
    required String clientId,
    required String serviceId,
    required DateTime desiredDate,
    String? professionalId,
    DateTime? desiredTime,
  });

  Future<List<WaitingListEntry>> getByClient(String clientId);

  Future<List<WaitingListEntry>> getByDesiredDate(DateTime date);

  Future<List<WaitingListEntry>> getByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  });

  Future<List<WaitingListEntry>> getPendingByService(String serviceId);

  Future<WaitingListEntry?> getFirstPendingForService(String serviceId);

  Future<void> updateStatus(String entryId, WaitingListStatus status);

  Future<void> offerSlot({
    required String entryId,
    required DateTime slotStart,
    required DateTime slotEnd,
  });
}
