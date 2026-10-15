import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test('fresh game starts dark and remembers finishing its guide', () async {
    final store = MemoryStore();
    final state = GameState(store);
    await state.load();
    expect(state.darkMode, isTrue);
    expect(state.introduced, isFalse);
    state.completeIntro();
    await state.flush();
    final reopened = GameState(store);
    await reopened.load();
    expect(reopened.darkMode, isTrue);
    expect(reopened.introduced, isTrue);
    expect(reopened.coins, state.coins);
    await reopened.flush();
    state.dispose();
    reopened.dispose();
  });

  test('opacity clamps controls and ignores non-finite values', () async {
    final state = GameState(MemoryStore());
    state.setHudOpacity(4);
    expect(state.hudOpacity, .8);
    state.setHudOpacity(-1);
    expect(state.hudOpacity, .2);
    state.setHudOpacity(double.nan);
    expect(state.hudOpacity, .2);
    await state.flush();
    state.dispose();
  });
  test(
    'appearance, joystick and HUD preferences persist without changing progress',
    () async {
      final store = MemoryStore();
      final state = GameState(store)..coins = 739;
      state.setDarkMode(true);
      state.setJoystickPosition(JoystickPosition.right);
      state.setHudVisible(false);
      state.setHudOpacity(.24);
      await state.flush();
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.darkMode, isTrue);
      expect(loaded.hudVisible, isFalse);
      expect(loaded.hudOpacity, .24);
      expect(loaded.joystickPosition, JoystickPosition.right);
      expect(loaded.coins, 739);
      loaded.setDarkMode(false);
      loaded.setJoystickPosition(JoystickPosition.center);
      loaded.setHudVisible(true);
      await loaded.flush();
      final reopened = GameState(store);
      await reopened.load();
      expect(reopened.darkMode, isFalse);
      expect(reopened.hudVisible, isTrue);
      expect(reopened.joystickPosition, JoystickPosition.center);
      await reopened.flush();
      state.dispose();
      loaded.dispose();
      reopened.dispose();
    },
  );

  test('older saves default to dark, left joystick and visible HUD', () async {
    final store = MemoryStore();
    final old = GameState(store)..coins = 488;
    final data = old.toJson()
      ..remove('darkMode')
      ..remove('joystickPosition')
      ..remove('hudVisible')
      ..remove('hudOpacity');
    store.value = jsonEncode(data);
    final loaded = GameState(store);
    await loaded.load();
    expect(loaded.recoveredSave, isFalse);
    expect(loaded.darkMode, isTrue);
    expect(loaded.hudVisible, isTrue);
    expect(loaded.hudOpacity, .38);
    expect(loaded.joystickPosition, JoystickPosition.left);
    expect(loaded.coins, 488);
    await loaded.flush();
    old.dispose();
    loaded.dispose();
  });

  test('an unknown control preference never discards a valid save', () async {
    final store = MemoryStore();
    final original = GameState(store)..coins = 961;
    store.value = jsonEncode(
      original.toJson()..['joystickPosition'] = 'future-value',
    );
    final loaded = GameState(store);
    await loaded.load();
    expect(loaded.recoveredSave, isFalse);
    expect(loaded.coins, 961);
    expect(loaded.joystickPosition, JoystickPosition.left);
    await loaded.flush();
    original.dispose();
    loaded.dispose();
  });
}
