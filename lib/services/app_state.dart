// Un singleton simple para mantener el estado global de la app.
class AppState {
  // Constructor privado
  AppState._internal();

  // La instancia única
  static final AppState _instance = AppState._internal();

  // Constructor factory para devolver la instancia única
  factory AppState() {
    return _instance;
  }

  // La variable de estado que queremos rastrear
  String? activeChatId;
}