import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  static SharedPreferences? _prefs;

  PreferencesService._init();

  static const String _fincasKey = 'fincas_list';
  static const String _valorUnitarioKey = 'last_valor_unitario';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<String> getFincas() {
    return _prefs?.getStringList(_fincasKey) ?? [];
  }

  Future<void> addFinca(String finca) async {
    final fincas = getFincas();
    final trimmedFinca = finca.trim();
    if (trimmedFinca.isNotEmpty && !fincas.contains(trimmedFinca)) {
      fincas.add(trimmedFinca);
      await _prefs?.setStringList(_fincasKey, fincas);
    }
  }

  Future<void> removeFinca(String finca) async {
    final fincas = getFincas();
    fincas.remove(finca);
    await _prefs?.setStringList(_fincasKey, fincas);
  }

  double getLastValorUnitario() {
    return _prefs?.getDouble(_valorUnitarioKey) ?? 0;
  }

  Future<void> setLastValorUnitario(double valor) async {
    await _prefs?.setDouble(_valorUnitarioKey, valor);
  }
}
