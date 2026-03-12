import '../../domain/entities/waitlist_entry.dart';
import '../../domain/repositories/waitlist_repository.dart';
import '../datasources/waitlist_remote_datasource.dart';

class WaitlistRepositoryImpl implements WaitlistRepository {
  final WaitlistRemoteDataSource dataSource;

  WaitlistRepositoryImpl(this.dataSource);

  @override
  Stream<List<WaitlistEntry>> streamWeeklyWaitlistByProfessional(
    String? professionalId,
  ) {
    return dataSource.streamWeeklyWaitlist(professionalId);
  }

  @override
  Future<void> updateStatus(String id, WaitlistStatus status) async {
    await dataSource.updateStatus(id, status);
  }
}
