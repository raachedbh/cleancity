import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final directory = Directory('docs/screenshots/v17.2');
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png').writeAsBytes(bytes);
        return bytes.length > 1000;
      },
  responseDataCallback: (_) async {},
);
