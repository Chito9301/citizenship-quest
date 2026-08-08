import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../services/firestore_service_stub.dart';
import '../../profile/providers/profile_provider.dart';

final firestoreServiceProvider = Provider<FirestoreServiceStub>((ref) {
  return FirestoreServiceStub();
});

/// Datos ya combinados y listos para pintar: el ranking simulado (aún
/// no hay backend) más la posición real del usuario local, insertada
/// en el lugar que le corresponde por puntaje.
class RankingViewData {
  const RankingViewData({
    required this.entries,
    required this.userRank,
    required this.userScore,
  });

  /// Lista completa ya ordenada por puntaje descendente, con el
  /// usuario local incluido en su posición real.
  final List<RankingEntry> entries;
  final int userRank;
  final int userScore;

  bool get userIsInTopTen => userRank <= 10;

  List<RankingEntry> get topTen => entries.take(10).toList();

  RankingEntry get userEntry => entries.firstWhere((e) => e.rank == userRank);
}

/// Combina el ranking simulado (FirestoreServiceStub, "mientras no
/// exista backend") con el puntaje real del usuario guardado
/// localmente, para que "Tu posición" sea siempre honesta aunque el
/// resto de la tabla sea de demostración.
final combinedRankingProvider = FutureProvider<RankingViewData>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  final mockEntries = await service.getRanking();

  final progress = await ref.watch(userProgressStreamProvider.future);
  final userScore = progress?.totalScore ?? 0;

  // Se arma la lista combinada (mock + usuario real) y se reordena por
  // puntaje para recalcular el rank de todos, incluyendo al usuario.
  final combined = [
    ...mockEntries.map((e) => (uid: e.uid, name: e.displayName, score: e.score)),
    (uid: 'local_user', name: 'Tú', score: userScore),
  ]..sort((a, b) => b.score.compareTo(a.score));

  final entries = <RankingEntry>[];
  int userRank = combined.length;
  for (var i = 0; i < combined.length; i++) {
    final row = combined[i];
    final rank = i + 1;
    if (row.uid == 'local_user') userRank = rank;
    entries.add(RankingEntry(
      uid: row.uid,
      displayName: row.name,
      score: row.score,
      rank: rank,
    ));
  }

  return RankingViewData(entries: entries, userRank: userRank, userScore: userScore);
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rankingAsync = ref.watch(combinedRankingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rankingTitle)),
      body: SafeArea(
        child: rankingAsync.when(
          loading: () => Center(child: Text(l10n.rankingLoading)),
          error: (err, stack) => Center(child: Text('${l10n.errorLabel}: $err')),
          data: (data) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...data.topTen.map(
                  (entry) => _RankingTile(
                    entry: entry,
                    isCurrentUser: entry.rank == data.userRank,
                  ),
                ),
                if (!data.userIsInTopTen) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: Text('⋯')),
                  ),
                  _RankingTile(entry: data.userEntry, isCurrentUser: true),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.entry, required this.isCurrentUser});

  final RankingEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? scheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: isCurrentUser ? scheme.primary : null,
          foregroundColor: isCurrentUser ? scheme.onPrimary : null,
          child: Text('${entry.rank}'),
        ),
        title: Text(
          entry.displayName,
          style: isCurrentUser ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.score}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 18, color: Colors.amber),
            ],
          ],
        ),
      ),
    );
  }
}
