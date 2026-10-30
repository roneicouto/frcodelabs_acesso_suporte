import 'dart:io';

/// Persist before invoking native repair: a successful call exits the GUI and
/// reopens it. A failed registration must not create an automatic restart loop.
Future<bool> cfAttemptServiceRepair(File marker, Future<void> Function() repair,
    {bool force = false}) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final previous = await marker.exists()
      ? int.tryParse((await marker.readAsString()).trim()) ?? 0 : 0;
  final elapsed = now - previous;
  if (!force && previous > 0 && elapsed >= 0 &&
      elapsed < const Duration(minutes: 2).inMilliseconds) return false;
  await marker.parent.create(recursive: true);
  await marker.writeAsString(now.toString(), flush: true);
  await repair();
  return true;
}

