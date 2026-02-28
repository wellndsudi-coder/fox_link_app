import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/create_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

class MockSchedulingRepository extends Mock
    implements SchedulingRepository {}

void main() {

  late MockSchedulingRepository repository;
  late CreateAppointmentUseCase useCase;

  setUp(() {
    repository = MockSchedulingRepository();
    useCase = CreateAppointmentUseCase(repository);
  });

  test('Should create when no conflict', () async {

    final appointment = Appointment(
      id: '1',
      professionalId: 'p1',
      clientId: 'c1',
      serviceId: 's1',
      scheduledStart: DateTime.now().add(Duration(days: 1)),
      scheduledEnd: DateTime.now().add(Duration(days: 1, hours: 1)),
      finalPrice: 100,
      finalDuration: 60,
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
    );

    when(() => repository.getApprovedByProfessionalAndDate(
      professionalId: any(named: 'professionalId'),
      date: any(named: 'date'),
    )).thenAnswer((_) async => []);

    when(() => repository.create(any()))
        .thenAnswer((_) async {});

    await useCase.call(appointment);

    verify(() => repository.create(appointment)).called(1);
  });
}