/// Modelo mínimo de usuario, independiente del SDK de Firebase.
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.isAnonymous = true,
  });
}

/// Stub de un futuro AuthService respaldado por Firebase Auth.
///
/// Sprint 1: no hay backend real todavía. Este servicio simula un login
/// anónimo instantáneo y devuelve datos "mock" para poder construir el
/// resto de la app (perfil, ranking, sync) sin depender de Firebase.
///
/// Cuando se integre Firebase de verdad, esta clase se reemplaza por una
/// implementación que use FirebaseAuth.instance, manteniendo la misma
/// interfaz pública para no romper el resto de la app.
class AuthServiceStub {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  Future<AppUser> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = const AppUser(
      uid: 'mock-uid-local-0001',
      displayName: 'Guest Learner',
      email: '',
      isAnonymous: true,
    );
    return _currentUser!;
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = AppUser(
      uid: 'mock-uid-${email.hashCode}',
      displayName: email.split('@').first,
      email: email,
      isAnonymous: false,
    );
    return _currentUser!;
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
  }
}
