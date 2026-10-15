import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state/game_state.dart';
import 'state/bootstrap.dart';
import 'ui/game_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final state = await loadGameState(
    testBuild: const bool.fromEnvironment('CLEANCITY_TEST_MODE'),
  );
  runApp(CleanCityApp(state: state));
}

class CleanCityApp extends StatelessWidget {
  const CleanCityApp({super.key, required this.state});
  final GameState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => MaterialApp(
      title: 'CleanCity',
      debugShowCheckedModeBanner: false,
      theme: gameTheme,
      darkTheme: darkGameTheme,
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: GameScreen(state: state),
    ),
  );
}
