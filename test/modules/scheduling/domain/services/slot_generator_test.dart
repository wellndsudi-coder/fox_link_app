import 'package:flutter_test/flutter_test.dart';
import 'package:fox_link_app/modules/scheduling/domain/services/slot_generator.dart';
import 'package:fox_link_app/modules/availability/domain/entities/availability.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

void main() {

  test('Should not generate slot when there is conflict', () {

    final now = DateTime(2026, 1, 1, 8, 0);

    final availability = Availability(
      id: '1',
      professionalId: 'p1',
      weekday: DateTime.monday,
      startMinutes: 8 * 60,
      endMinutes: 18 * 60,
      breakStartMinutes: null,
      breakEndMinutes: null,
    );

    final approved = [
      Appointment(
        id: 'a1',
        professionalId: 'p1',
        clientId: 'c1',
        serviceId: 's1',
        scheduledStart: DateTime(2026, 1, 5, 9, 0),
        scheduledEnd: DateTime(2026, 1, 5, 10, 0),
        finalPrice: 100,
        finalDuration: 60,
        status: AppointmentStatus.approved,
        createdAt: now,
      )
    ];

    final slots = SlotGenerator.generateSlots(
      date: DateTime(2026, 1, 5),
      now: now,
      serviceDurationMinutes: 60,
      slotStepMinutes: 60,
      weeklyAvailability: availability,
      approvedAppointments: approved,
    );

    expect(
      slots.contains(DateTime(2026, 1, 5, 9, 0)),
      false,
    );
  });
}