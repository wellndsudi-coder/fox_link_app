import 'package:intl/intl.dart';

import '../../../scheduling/domain/entities/appointment.dart';
import '../../../scheduling/domain/repositories/scheduling_repository.dart';

import '../entities/smart_suggestion.dart';
import '../repositories/favorites_repository.dart';
import 'get_first_available_slot_usecase.dart';

class SmartBookingSuggestionUseCase {
  final SchedulingRepository schedulingRepository;
  final FavoritesRepository favoritesRepository;
  final GetFirstAvailableSlotUseCase getFirstAvailableSlotUseCase;

  SmartBookingSuggestionUseCase({
    required this.schedulingRepository,
    required this.favoritesRepository,
    required this.getFirstAvailableSlotUseCase,
  });

  Future<List<SmartSuggestion>> call(String clientId) async {
    final suggestions = <SmartSuggestion>[];

    final history = await schedulingRepository.getByClient(clientId);
    final completed = history
        .where((a) => a.status == AppointmentStatus.completed || a.status == AppointmentStatus.approved)
        .toList();

    String? preferredServiceId;
    String? preferredProfessionalId;
    if (completed.isNotEmpty) {
      completed.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
      preferredServiceId = completed.first.serviceId;
      preferredProfessionalId = completed.first.professionalId;
    }

    final favorites = await favoritesRepository.getByClient(clientId);
    if (preferredProfessionalId == null && favorites.isNotEmpty) {
      preferredProfessionalId = favorites.first.professionalId;
    }

    final serviceId = preferredServiceId;
    if (serviceId != null) {
      final first = await getFirstAvailableSlotUseCase(
        serviceId: serviceId,
        clientId: clientId,
      );
      if (first != null) {
        suggestions.add(SmartSuggestion(
          label: _formatLabel(first.slot),
          dateTime: first.slot,
          serviceId: serviceId,
          professionalId: first.professionalId,
        ));
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final friday = _nextWeekday(today, DateTime.friday);

    if (suggestions.length < 3 && serviceId != null) {
      final second = await getFirstAvailableSlotUseCase(
        serviceId: serviceId,
        clientId: clientId,
        forDate: tomorrow,
      );
      if (second != null) {
        suggestions.add(SmartSuggestion(
          label: 'Amanhã ${DateFormat('HH:mm').format(second.slot)}',
          dateTime: second.slot,
          serviceId: serviceId,
          professionalId: second.professionalId,
        ));
      }
    }

    if (suggestions.length < 3 && serviceId != null) {
      final third = await getFirstAvailableSlotUseCase(
        serviceId: serviceId,
        clientId: clientId,
        forDate: friday,
      );
      if (third != null) {
        suggestions.add(SmartSuggestion(
          label: 'Sexta ${DateFormat('HH:mm').format(third.slot)}',
          dateTime: third.slot,
          serviceId: serviceId,
          professionalId: third.professionalId,
        ));
      }
    }

    while (suggestions.length < 3) {
      suggestions.add(const SmartSuggestion(label: 'Ver horários disponíveis'));
      if (suggestions.length >= 3) break;
    }

    return suggestions.take(3).toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatLabel(DateTime dt) {
    final now = DateTime.now();
    if (_sameDay(dt, now)) {
      return 'Hoje ${DateFormat('HH:mm').format(dt)}';
    }
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (_sameDay(dt, tomorrow)) {
      return 'Amanhã ${DateFormat('HH:mm').format(dt)}';
    }
    return DateFormat("EEEE HH:mm", 'pt_BR').format(dt);
  }

  DateTime _nextWeekday(DateTime from, int weekday) {
    var d = from;
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }
}
