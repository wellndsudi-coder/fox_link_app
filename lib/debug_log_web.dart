import 'dart:convert';
import 'dart:html' as html;

void debugLog(String location, String message, Map<String, dynamic> data,
    {String? hypothesisId}) {
  final payload = {
    'sessionId': '80dbef',
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    if (hypothesisId != null) 'hypothesisId': hypothesisId,
  };
  html.HttpRequest.request(
    'http://127.0.0.1:7333/ingest/34281f1c-80df-4eb0-85c2-50262c8b9e42',
    method: 'POST',
    sendData: jsonEncode(payload),
    requestHeaders: {
      'Content-Type': 'application/json',
      'X-Debug-Session-Id': '80dbef',
    },
  ).then((_) {}, onError: (_) {});
}
