import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz_models.dart';
import '../../quiz/providers/quiz_provider.dart';

/// Emite el UserProgress actual y se actualiza automáticamente cada vez
/// que cambia en el almacenamiento local (por ejemplo, al terminar un
/// quiz).
final userProgressStreamProvider = StreamProvider<UserProgress?>((ref) async* {
  final storageService = ref.watch(localStorageServiceProvider);

  if (!storageService.isInitialized) {
    await storageService.init();
  }

  yield* storageService.watchProgress();
});
