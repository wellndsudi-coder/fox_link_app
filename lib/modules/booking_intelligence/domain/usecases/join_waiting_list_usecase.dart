import '../repositories/waiting_list_repository.dart';

class JoinWaitingListUseCase {
  final WaitingListRepository repository;

  JoinWaitingListUseCase(this.repository);

  Future<void> call({
    required String clientId,
    required String serviceId,
    required DateTime desiredDate,
    String? professionalId,
    DateTime? desiredTime,
  }) {
    return repository.add(
      clientId: clientId,
      serviceId: serviceId,
      desiredDate: desiredDate,
      professionalId: professionalId,
      desiredTime: desiredTime,
    );
  }
}
