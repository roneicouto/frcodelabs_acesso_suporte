import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/cf_service_recovery.dart';

void main() {
  late Directory folder;
  late File marker;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('cf-service-recovery-test-');
    marker = File('${folder.path}/attempt');
  });
  tearDown(() async { await folder.delete(recursive: true); });

  test('automatic repair runs and survives a reopened GUI without repeating', () async {
    var calls = 0;
    Future<void> repair() async { calls++; }
    expect(await cfAttemptServiceRepair(marker, repair), isTrue);
    expect(await cfAttemptServiceRepair(File(marker.path), repair), isFalse);
    expect(calls, 1);
  });

  test('failed repair prevents automatic loop and still allows manual retry', () async {
    await expectLater(cfAttemptServiceRepair(marker, () async { throw StateError('Denied'); }), throwsStateError);
    var calls = 0;
    Future<void> repair() async { calls++; }
    expect(await cfAttemptServiceRepair(marker, repair), isFalse);
    expect(calls, 0);
    expect(await cfAttemptServiceRepair(marker, repair, force: true), isTrue);
    expect(calls, 1);
  });

  test('a later opening may retry an old failed attempt', () async {
    await marker.writeAsString(DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch.toString());
    var calls = 0;
    expect(await cfAttemptServiceRepair(marker, () async { calls++; }), isTrue);
    expect(calls, 1);
  });
}

