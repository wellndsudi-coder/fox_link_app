import 'package:flutter_test/flutter_test.dart';
import 'package:fox_link_app/modules/scheduling/domain/services/schedule_validator.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

void main() {

  test('Should throw when scheduling in the past', () {

    final appointment = Appointment(
      id: '1',
      professionalId: 'p1',
      clientId: 'c1',
      serviceId: 's1',
      scheduledStart: DateTime(2020, 1, 1),
      scheduledEnd: DateTime(2020, 1, 1, 1),
      finalPrice: 100,
      finalDuration: 60,
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
    );

    expect(
          () => ScheduleValidator.validateCreation(appointment),
      throwsException,
    );
  });
}