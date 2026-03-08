import '../../domain/entities/waiting_list_entry.dart';
import '../../domain/repositories/waiting_list_repository.dart';
import '../datasources/waiting_list_remote_datasource.dart';

class WaitingListRepositoryImpl implements WaitingListRepository {
  final WaitingListRemoteDataSource dataSource;

  WaitingListRepositoryImpl(this.dataSource);

  @override
  Future<void> add({
    required String clientId,
    required String serviceId,
    required DateTime desiredDate,
    String? professionalId,
    DateTime? desiredTime,
  }) async {
    await dataSource.add(
      clientId: clientId,
      serviceId: serviceId,
      desiredDate: desiredDate,
      professionalId: professionalId,
      desiredTime: desiredTime,
    );
  }

  @override
  Future<List<WaitingListEntry>> getByClient(String clientId) =>
      dataSource.getByClient(clientId);

  @override
  Future<List<WaitingListEntry>> getByDesiredDate(DateTime date) =>
      dataSource.getByDesiredDate(date);

  @override
  Future<List<WaitingListEntry>> getByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  }) =>
      dataSource.getByProfessionalAndDate(
        professionalId: professionalId,
        date: date,
      );

  @override
  Future<List<WaitingListEntry>> getPendingByService(String serviceId) =>
      dataSource.getPendingByService(serviceId);

  @override
  Future<WaitingListEntry?> getFirstPendingForService(String serviceId) =>
      dataSource.getFirstPendingForService(serviceId);

  @override
  Future<void> updateStatus(String entryId, WaitingListStatus status) =>
      dataSource.updateStatus(entryId, status);

  @override
  Future<void> offerSlot({
    required String entryId,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) =>
      dataSource.offerSlot(
        entryId: entryId,
        slotStart: slotStart,
        slotEnd: slotEnd,
      );
}
