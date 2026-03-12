import '../repositories/scheduling_repository.dart';
import '../../../users/domain/repositories/user_repository.dart';

/// Cliente com dados para exibição (do profissional).
class ClientDisplay {
  final String id;
  final String name;

  const ClientDisplay({required this.id, required this.name});
}

/// Lista clientes únicos que já tiveram agendamentos com o profissional.
class GetClientsByProfessionalUseCase {
  final SchedulingRepository schedulingRepository;
  final UserRepository userRepository;

  GetClientsByProfessionalUseCase({
    required this.schedulingRepository,
    required this.userRepository,
  });

  Future<List<ClientDisplay>> call(String professionalId) async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 365 * 2));

    final appointments = await schedulingRepository.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: start,
      end: end,
    );

    final clientIds = appointments.map((a) => a.clientId).toSet().toList();
    if (clientIds.isEmpty) return [];

    final users = await userRepository.getUsersByIds(clientIds);
    final result = <ClientDisplay>[];

    for (var i = 0; i < clientIds.length; i++) {
      final id = clientIds[i];
      final u = i < users.length ? users[i] : null;
      final name = u != null
          ? ((u['name'] as String?) ?? (u['displayName'] as String?) ?? (u['email'] as String?) ?? id)
          : id;
      result.add(ClientDisplay(id: id, name: name));
    }

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }
}
