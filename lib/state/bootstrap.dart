import 'game_state.dart';

/// A test APK can inspect a copy of the player's save without changing it.
Future<GameState> loadGameState({
  required bool testBuild,
  SaveStore? normalStore,
  SaveStore? testStore,
}) async {
  final normal = normalStore ?? LocalSaveStore();
  final store = testBuild
      ? testStore ?? LocalSaveStore(key: 'cleancity_test_save_v1')
      : normal;
  if (testBuild && await store.read() == null) {
    final previous = await normal.read();
    if (previous != null) await store.write(previous);
  }
  final state = GameState(store);
  await state.load();
  if (testBuild) {
    state.unlockTestContent();
    await state.flush();
  }
  return state;
}
