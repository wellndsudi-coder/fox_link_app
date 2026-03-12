import '../entities/waitlist_entry.dart';
import '../repositories/waitlist_repository.dart';

class StreamWeeklyWaitlistUseCase {
  final WaitlistRepository repository;

  StreamWeeklyWaitlistUseCase(this.repository);

  Stream<List<WaitlistEntry>> call(String? professionalId) {
    return repository.streamWeeklyWaitlistByProfessional(professionalId);
  }
}
