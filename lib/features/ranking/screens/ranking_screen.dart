import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../services/firestore_service_stub.dart';

final firestoreServiceProvider = Provider<FirestoreServiceStub>((ref) {
  return FirestoreServiceStub();
});

final rankingProvider = FutureProvider<List<RankingEntry>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getRanking();
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rankingAsync = ref.watch(rankingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rankingTitle)),
      body: SafeArea(
        child: rankingAsync.when(
          loading: () => Center(child: Text(l10n.rankingLoading)),
          error: (err, stack) => Center(child: Text('${l10n.errorLabel}: $err')),
          data: (entries) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${entry.rank}')),
                  title: Text(entry.displayName),
                  trailing: Text(
                    '${entry.score}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
