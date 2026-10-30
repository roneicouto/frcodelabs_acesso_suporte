import 'dart:async';
import 'dart:io';

Future<void> cfLaunchWindowsUpdater(File helper, File plan) async {
  final windows = Platform.environment['SystemRoot'] ?? r'C:\Windows';
  // PowerShell 5 does not start reliably with Dart's DETACHED_PROCESS flag.
  // A regular child with pipes survives exit(0) of the Windows GUI as well.
  final child = await Process.start(
    '$windows/System32/WindowsPowerShell/v1.0/powershell.exe',
    ['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass',
      '-File', helper.path, '-Plan', plan.path],
  );
  final errors = <int>[];
  child.stdout.listen((_) {}, onError: (Object error) {});
  child.stderr.listen((chunk) {
    if (errors.length < 16384) errors.addAll(chunk.take(16384 - errors.length));
  }, onError: (Object error) {});
  int? exitCode;
  unawaited(child.exitCode.then((code) { exitCode = code; }));
  final ready = File('${plan.path}.ready');
  final failure = File('${plan.path}.error');
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (!await ready.exists()) {
    if (await failure.exists() || exitCode != null || DateTime.now().isAfter(deadline)) {
      await File('${plan.path}.launch.log').writeAsBytes([
        ...systemEncoding.encode('Updater startup failed; exit code: $exitCode\r\n'), ...errors,
      ]);
      if (exitCode == null) child.kill();
      throw const FileSystemException('Could not start the Windows updater');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

