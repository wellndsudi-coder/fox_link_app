import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_client_appointments_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class ClientHistoryPage extends StatefulWidget {
  const ClientHistoryPage({super.key});

  @override
  State<ClientHistoryPage> createState() => _ClientHistoryPageState();
}

class _ClientHistoryPageState extends State<ClientHistoryPage> {
  final _session = GetIt.I<TenantSession>();
  final _getAppointments = GetIt.I<GetClientAppointmentsUseCase>();

  late Future<List<Appointment>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (_session.uid != null) {
      _future = _getAppointments(_session.uid!);
    } else {
      _future = Future.value(<Appointment>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _load();
        setState(() {});
      },
      child: FutureBuilder<List<Appointment>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          final now = DateTime.now();
          final past = all
              .where((a) =>
                  a.scheduledStart.isBefore(now) ||
                  a.status == AppointmentStatus.completed ||
                  a.status == AppointmentStatus.cancelled ||
                  a.status == AppointmentStatus.rejected ||
                  a.status == AppointmentStatus.noShow)
              .toList()
            ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

          if (past.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.mutedForeground(context)),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum agendamento no histórico',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.mutedForeground(context),
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: past.length,
            itemBuilder: (_, index) {
              final a = past[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(a.scheduledStart),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          _StatusChip(status: a.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Serviço agendado',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedForeground(context),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  (String, Color) _labelAndColor(BuildContext context) {
    switch (status) {
      case AppointmentStatus.completed:
        return ('Concluído', AppColors.success(context));
      case AppointmentStatus.cancelled:
        return ('Cancelado', AppColors.mutedForeground(context));
      case AppointmentStatus.rejected:
        return ('Rejeitado', AppColors.error(context));
      case AppointmentStatus.noShow:
        return ('Não compareceu', AppColors.error(context));
      default:
        return ('Outro', AppColors.mutedForeground(context));
    }
  }
}
