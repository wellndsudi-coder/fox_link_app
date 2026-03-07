import 'package:flutter_test/flutter_test.dart';
import 'package:fox_link_app/modules/scheduling/domain/services/schedule_validator.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

void main() {
  test('Should throw ScheduleConflictException when new overlaps approved', () {
    final now = DateTime(2026, 1, 5, 8, 0);
    final newAppointment = Appointment(
      id: '2',
      tenantId: 't1',
      professionalId: 'p1',
      clientId: 'c1',
      serviceId: 's1',
      scheduledStart: DateTime(2026, 1, 5, 9, 0),
      scheduledEnd: DateTime(2026, 1, 5, 10, 0),
      finalPrice: 100,
      finalDuration: 60,
      status: AppointmentStatus.pending,
      createdAt: now,
    );
    final approved = [
      Appointment(
        id: '1',
        tenantId: 't1',
        professionalId: 'p1',
        clientId: 'c1',
        serviceId: 's1',
        scheduledStart: DateTime(2026, 1, 5, 9, 30),
        scheduledEnd: DateTime(2026, 1, 5, 10, 30),
        finalPrice: 100,
        finalDuration: 60,
        status: AppointmentStatus.approved,
        createdAt: now,
      ),
    ];
    expect(
      () => ScheduleValidator.validateConflict(
        newAppointment: newAppointment,
        approvedAppointments: approved,
      ),
      throwsA(isA<ScheduleConflictException>()),
    );
  });
}