import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'cf_update_model.dart';

/// The caller owns the client so closing it cancels an in-flight download.
Future<File> cfDownloadUpdate(CfRelease release, Directory directory,
    http.Client client, void Function(double) progress) async {
  if (!release.canInstall) throw const FormatException('Missing package integrity data');
  final partial = File('${directory.path}/update.partial');
  IOSink? sink;
  try {
    final request = http.Request('GET', release.download)
      ..headers['User-Agent'] = 'FRCodeLabs-Updater';
    final response = await client.send(request).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 ||
        (response.contentLength != null && response.contentLength != release.bytes)) {
      throw const FormatException('Unexpected update response');
    }
    sink = partial.openWrite();
    var received = 0;
    await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
      received += chunk.length;
      if (received > release.bytes) throw const FormatException('Package too large');
      sink.add(chunk);
      // Await disk writes instead of buffering the entire installer in memory.
      await sink.flush();
      progress(received / release.bytes);
    }
    await sink.close();
    sink = null;
    if (received != release.bytes ||
        (await sha256.bind(partial.openRead()).first).toString() != release.sha256) {
      throw const FormatException('Package integrity check failed');
    }
    final header = await partial.open();
    try {
      final bytes = await header.read(2);
      if (bytes.length != 2 || bytes[0] != 0x4d || bytes[1] != 0x5a) {
        throw const FormatException('Not a Windows package');
      }
    } finally {
      await header.close();
    }
    return await partial.rename('${directory.path}/FRCodeLabs-update.exe');
  } finally {
    await sink?.close();
    if (await partial.exists()) await partial.delete();
  }
}

