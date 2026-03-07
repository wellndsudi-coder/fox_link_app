import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';

/// DTO para servico mais usado.
class TopServiceItem {
  final String serviceName;
  final int count;

  const TopServiceItem({required this.serviceName, required this.count});
}

class GetTopServicesUseCase {
  final SchedulingRepository schedulingRepository;
  final ServiceRepository serviceRepository;
  final TenantSession session;

  GetTopServicesUseCase(
    this.schedulingRepository,
    this.serviceRepository,
    this.session,
  );

  Future<List<TopServiceItem>> call({int limit = 5}) async {
    final tenantId = session.tenantId;
    if (tenantId == null) return [];

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final appointments = await schedulingRepository.getByTenantAndPeriod(
      start: startOfMonth,
      end: endOfMonth,
    );

    final counts = <String, int>{};
    for (final a in appointments) {
      if (a.status.name == 'approved' || a.status.name == 'completed') {
        counts[a.serviceId] = (counts[a.serviceId] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return [];

    final services = await serviceRepository.getAll(tenantId);
    final nameById = <String, String>{};
    for (final s in services) {
      nameById[s.id] = s.name.value;
    }

    final items = counts.entries
        .map((e) => TopServiceItem(
              serviceName: nameById[e.key] ?? 'Serviço',
              count: e.value,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return items.take(limit).toList();
  }
}
