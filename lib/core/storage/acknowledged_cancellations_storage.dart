import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Armazena IDs de agendamentos cancelados que o cliente já viu/confirmou.
class AcknowledgedCancellationsStorage {
  static const _keyPrefix = 'ack_cancellations_';

  Future<Set<String>> getAcknowledged(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_keyPrefix$clientId');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      return (list ?? []).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> acknowledge(String clientId, String appointmentId) async {
    final set = await getAcknowledged(clientId);
    set.add(appointmentId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$clientId', jsonEncode(set.toList()));
  }
}
