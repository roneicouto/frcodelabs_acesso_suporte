import 'dart:io';
import '../cf_update_launcher.dart';

Future<void> main(List<String> args) async {
  await cfLaunchWindowsUpdater(File(args[0]), File(args[1]));
  // Match the GUI: the parent must exit before the helper applies the update.
  exit(0);
}

