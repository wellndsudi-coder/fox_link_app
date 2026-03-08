import 'package:shared_preferences/shared_preferences.dart';

const _key = 'remember_me';

class RememberMePreference {
  final SharedPreferences _prefs;

  RememberMePreference(this._prefs);

  Future<bool> get() async => _prefs.getBool(_key) ?? true;

  Future<void> set(bool value) => _prefs.setBool(_key, value);
}
