import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/draft_repository.dart';
import 'logic/draft_controller.dart';
import 'logic/draft_state.dart';

final draftRepositoryProvider = Provider<DraftRepository>((ref) => DraftRepository());

final draftControllerProvider =
    StateNotifierProvider.autoDispose<DraftController, DraftState>((ref) {
  final repo = ref.read(draftRepositoryProvider);
  return DraftController(repo);
});
