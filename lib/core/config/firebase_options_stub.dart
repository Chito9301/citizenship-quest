/// Stub de configuración de Firebase.
///
/// Sprint 1 NO inicializa Firebase de verdad (no hay dependencia del
/// paquete `firebase_core` en pubspec.yaml todavía). Esta clase existe
/// para que el resto del código (AuthServiceStub, FirestoreServiceStub)
/// tenga un lugar único donde leer "configuración" y para dejar preparado
/// el punto de extensión del Sprint 2, cuando se agregue
/// `firebase_core` + `firebase_options.dart` generado por FlutterFire CLI.
class FirebaseOptionsStub {
  final String projectId;
  final String appId;
  final String apiKey;
  final String messagingSenderId;

  const FirebaseOptionsStub({
    this.projectId = 'citizenship-quest-dev',
    this.appId = 'mock-app-id',
    this.apiKey = 'mock-api-key',
    this.messagingSenderId = 'mock-sender-id',
  });

  static const FirebaseOptionsStub current = FirebaseOptionsStub();

  @override
  String toString() {
    return 'FirebaseOptionsStub(projectId: $projectId, appId: $appId)';
  }
}
