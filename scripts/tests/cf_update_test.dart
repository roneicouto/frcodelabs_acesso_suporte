import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/cf_update_model.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_hbb/cf_update_download.dart';

void main() {
  const repo = 'roneicouto/frcodelabs-releases';
  const full = 'FRCodeLabs-Windows-Full-install.exe';
  const qs = 'FRCodeLabs-Windows-QS.exe';
  Map<String, dynamic> release(String version) => {
    'tag_name': version, 'draft': false, 'prerelease': false,
    'assets': [for (final asset in [full, qs]) <String, dynamic>{
      'name': asset, 'state': 'uploaded',
      'browser_download_url': 'https://github.com/$repo/releases/download/$version/$asset',
    }],
  };
  test('compares semantic versions rather than strings', () {
    expect(CfRelease.isNewer('v1.10.0', '1.9.9'), isTrue);
    expect(CfRelease.isNewer('v1.0.3', '1.0.3'), isFalse);
    expect(CfRelease.isNewer('v1.0.2', '1.0.3'), isFalse);
    expect(CfRelease.isNewer('v1.0.4-beta', '1.0.3'), isFalse);
  });
  test('selects Full and QS packages independently', () {
    final data = release('v1.0.4');
    expect(CfRelease.fromJson(data, '1.0.3', repo, full)!.download.path, endsWith('/$full'));
    expect(CfRelease.fromJson(data, '1.0.3', repo, qs)!.download.path, endsWith('/$qs'));
    expect(CfRelease.fromJson(data, '1.0.3', repo, 'missing.dmg'), isNull);
  });
  test('ignores drafts, prereleases and current versions', () {
    expect(CfRelease.fromJson(release('v1.0.3'), '1.0.3', repo, full), isNull);
    expect(CfRelease.fromJson({...release('v1.0.4'), 'draft': true}, '1.0.3', repo, full), isNull);
    expect(CfRelease.fromJson({...release('v1.0.4'), 'prerelease': true}, '1.0.3', repo, full), isNull);
  });
  test('does not offer an older platform package from a newer release', () {
    final data = release('v1.0.4');
    (data['assets'] as List)[0]['label'] = 'Windows Full x64 - v1.0.2';
    expect(CfRelease.fromJson(data, '1.0.3', repo, full), isNull);
    expect(CfRelease.fromJson(data, '1.0.3', repo, qs), isNotNull);
  });
  test('rejects download URLs outside the exact release and repository', () {
    for (final url in ['https://evil.example/$full', 'file:///tmp/$full',
      'https://github.com/another/repo/releases/download/v1.0.4/$full']) {
      final data = release('v1.0.4');
      (data['assets'] as List)[0]['browser_download_url'] = url;
      expect(CfRelease.fromJson(data, '1.0.3', repo, full), isNull);
    }
  });
  test('requires GitHub integrity metadata before internal installation', () {
    final data = release('v1.0.5');
    expect(CfRelease.fromJson(data, '1.0.4', repo, full)!.canInstall, isFalse);
    (data['assets'] as List)[0].addAll({'size': 100, 'digest': 'sha256:${'a' * 64}'});
    expect(CfRelease.fromJson(data, '1.0.4', repo, full)!.canInstall, isTrue);
  });
  test('downloads a matching Windows package with progress', () async {
    final directory = await Directory.systemTemp.createTemp('cf-download-test-');
    final bytes = [0x4d, 0x5a, 1, 2, 3];
    final client = MockClient((_) async => http.Response.bytes(bytes, 200));
    try {
      final package = CfRelease('1.0.5', Uri.parse('https://github.com/$repo/releases/download/v1.0.5/$full'),
        bytes: bytes.length, sha256: sha256.convert(bytes).toString());
      var progress = 0.0;
      final file = await cfDownloadUpdate(package, directory, client, (value) => progress = value);
      expect(await file.readAsBytes(), bytes);
      expect(progress, 1.0);
      expect(await File('${directory.path}/update.partial').exists(), isFalse);
    } finally { client.close(); await directory.delete(recursive: true); }
  });
  test('refuses corrupted, truncated, oversized and non-executable packages', () async {
    for (final scenario in ['hash', 'short', 'large', 'header', 'network']) {
      final directory = await Directory.systemTemp.createTemp('cf-download-test-');
      final bytes = scenario == 'header' ? [1, 2, 3] : [0x4d, 0x5a, 1];
      final client = MockClient((_) async {
        if (scenario == 'network') throw const SocketException('Disconnected');
        return http.Response.bytes(bytes, 200);
      });
      try {
        final package = CfRelease('1.0.5', Uri.parse('https://github.com/$repo/releases/download/v1.0.5/$full'),
          bytes: scenario == 'short' ? 10 : (scenario == 'large' ? 2 : 3),
          sha256: scenario == 'hash' ? '0' * 64 : sha256.convert(bytes).toString());
        await expectLater(cfDownloadUpdate(package, directory, client, (_) {}), throwsA(anything));
        expect(await directory.list().toList(), isEmpty);
      } finally { client.close(); await directory.delete(recursive: true); }
    }
  });
}

