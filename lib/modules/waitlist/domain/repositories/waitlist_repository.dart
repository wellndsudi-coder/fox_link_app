import '../entities/waitlist_entry.dart';

abstract class WaitlistRepository {
  Stream<List<WaitlistEntry>> streamWeeklyWaitlistByProfessional(
    String? professionalId,
  );

  Future<void> updateStatus(String id, WaitlistStatus status);
}
