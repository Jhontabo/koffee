import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  static SharedPreferences? _prefs;

  PreferencesService._init();

  static const String _valorUnitarioKey = 'last_valor_unitario';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String _getFincasKey(String userId) => 'fincas_list_$userId';

  List<String> getFincas(String userId) {
    if (userId.isEmpty) return [];
    return _prefs?.getStringList(_getFincasKey(userId)) ?? [];
  }

  Future<void> addFinca(String userId, String finca) async {
    if (userId.isEmpty) return;
    final fincas = getFincas(userId);
    final trimmedFinca = finca.trim();
    if (trimmedFinca.isNotEmpty && !fincas.contains(trimmedFinca)) {
      fincas.add(trimmedFinca);
      await _prefs?.setStringList(_getFincasKey(userId), fincas);
    }
  }

  Future<void> removeFinca(String userId, String finca) async {
    if (userId.isEmpty) return;
    final fincas = getFincas(userId);
    fincas.remove(finca);
    await _prefs?.setStringList(_getFincasKey(userId), fincas);
  }

  double getLastValorUnitario() {
    return _prefs?.getDouble(_valorUnitarioKey) ?? 0;
  }

  Future<void> setLastValorUnitario(double valor) async {
    await _prefs?.setDouble(_valorUnitarioKey, valor);
  }
}
