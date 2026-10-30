import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'cf_update_download.dart';
import 'cf_update_model.dart';
import 'cf_update_panel.dart';
import 'cf_update_launcher.dart';

class CfUpdateNotice extends StatefulWidget {
  final bool isQs;
  const CfUpdateNotice({super.key, required this.isQs});
  @override
  State<CfUpdateNotice> createState() => _CfUpdateNoticeState();
}

class _CfUpdateNoticeState extends State<CfUpdateNotice> {
  Timer? _timer;
  bool _busy = false;
  CfRelease? _release;
  String _status = '';
  http.Client? _downloadClient;
  double? _progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check(startup: true);
    });
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _check());
  }

  String? get _asset {
    if (Platform.isWindows && Abi.current() == Abi.windowsX64) {
      return widget.isQs ? 'FRCodeLabs-Windows-QS.exe' : 'FRCodeLabs-Windows-Full-install.exe';
    }
    if (Platform.isMacOS && Abi.current() == Abi.macosArm64) {
      return widget.isQs ? 'FRCodeLabs-macOS-QS-arm64.dmg' : 'FRCodeLabs-macOS-Full-arm64.dmg';
    }
    if (Platform.isAndroid && Abi.current() == Abi.androidArm64) {
      return widget.isQs ? 'FRCodeLabs-Android-QS-arm64.apk' : 'FRCodeLabs-Android-Full-arm64.apk';
    }
    return null;
  }

  Future<void> _check({bool manual = false, bool startup = false}) async {
    if (!mounted || _busy) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final previous = int.tryParse(bind.mainGetLocalOption(key: 'cf-update-check-ms')) ?? 0;
    if (!manual && !startup && now >= previous && now - previous < const Duration(hours: 24).inMilliseconds) return;
    setState(() { _busy = true; if (manual) _status = 'Verificando...'; });
    final client = http.Client();
    try {
      final info = jsonDecode(await rootBundle.loadString('assets/cf_legal.json')) as Map<String, dynamic>;
      final repository = info['update_repository'] as String;
      if (!RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repository)) {
        throw const FormatException('Invalid update repository');
      }
      await bind.mainSetLocalOption(key: 'cf-update-check-ms', value: now.toString());
      final response = await client.get(
        Uri.https('api.github.com', '/repos/$repository/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'FRCodeLabs/${info['version']}'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.length > 1024 * 1024) {
        throw const FormatException('Update check unavailable');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final asset = _asset;
      final release = asset == null ? null : CfRelease.fromJson(data, info['version'] as String, repository, asset);
      if (!mounted) return;
      setState(() {
        _release = release;
        if (manual) {
          _status = release != null ? '' :
            (CfRelease.isNewer(data['tag_name'] is String ? data['tag_name'] : '', info['version'])
              ? 'Ainda não há um pacote novo compatível com este aplicativo.'
              : 'Você está na versão mais recente.');
        }
      });
    } catch (_) {
      if (mounted && manual) setState(() => _status = 'Não foi possível verificar. Tente novamente mais tarde.');
      // Background network failures must not interrupt a support session.
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    final release = _release;
    if (release == null || _busy) return;
    if (Platform.isWindows) {
      await _installWindows(release);
      return;
    }
    try {
      final opened = await launchUrl(release.download, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {
      // Report failure in the application instead of interrupting the session.
    }
    if (mounted) setState(() => _status = 'Não foi possível abrir o download.');
  }

  Future<void> _installWindows(CfRelease release) async {
    setState(() { _busy = true; _status = 'Preparando download...'; });
    final client = http.Client();
    _downloadClient = client;
    var failureMessage = 'Não foi possível baixar a atualização. Verifique a conexão e tente novamente.';
    try {
      final installed = await bind.mainGetCommon(key: 'cf-installed-exe');
      final launcher = Platform.environment['CFLINK_PORTABLE_SOURCE'] ?? '';
      if (installed.isEmpty && (launcher.isEmpty || !await File(launcher).exists())) {
        failureMessage = 'Abra o aplicativo pelo executável portátil ou pela instalação para atualizar.';
        throw const FormatException('Abra o aplicativo pelo pacote portátil para atualizar.');
      }
      final directory = await Directory.systemTemp.createTemp('FRCodeLabs-update-');
      final package = await cfDownloadUpdate(release, directory, client, (value) {
        if (mounted) setState(() { _progress = value; _status = 'Baixando atualização: ${(value * 100).floor()}%'; });
      });
      _downloadClient = null;
      if (!mounted) return;
      setState(() { _progress = null; _status = 'Download verificado.'; });
      final accepted = await showDialog<bool>(context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Instalar FR CODE LABS ${release.version}?'),
          content: Text('O aplicativo será fechado e aberto novamente. As conexões em andamento serão interrompidas.'
              '${installed.isNotEmpty ? '\n\nO Windows poderá solicitar autorização de administrador.' : ''}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Agora não')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Atualizar e reiniciar')),
          ],
        ));
      if (accepted != true) {
        await package.delete();
        if (mounted) setState(() => _status = 'Atualização adiada.');
        return;
      }
      final helper = File('${directory.path}/cf_update_windows.ps1');
      failureMessage = 'Não foi possível iniciar o atualizador. O download foi preservado. Tente novamente ou instale o pacote manualmente.';
      // PowerShell 5 uses the system codepage for scripts without a BOM.
      await helper.writeAsBytes([0xef, 0xbb, 0xbf, ...utf8.encode(await rootBundle.loadString('assets/cf_update_windows.ps1'))]);
      final plan = File('${directory.path}/plan.json');
      await plan.writeAsString(jsonEncode({
        'mode': installed.isEmpty ? 'portable' : 'installed',
        'profile': widget.isQs ? 'qs' : 'full', 'version': release.version,
        'package': package.path, 'target': installed.isEmpty ? launcher : installed,
        'runtime': Platform.resolvedExecutable, 'processId': pid,
        'bytes': release.bytes, 'sha256': release.sha256,
      }));
      await cfLaunchWindowsUpdater(helper, plan);
      await File('${plan.path}.go').writeAsString('confirmed');
      bind.mainOnMainWindowClose();
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
      exit(0);
    } catch (_) {
      if (mounted) setState(() => _status = failureMessage);
    } finally {
      client.close();
      _downloadClient = null;
      if (mounted) setState(() { _busy = false; _progress = null; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _downloadClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CfUpdatePanel(
    version: _release?.version, busy: _busy, progress: _progress, status: _status,
    internalUpdate: Platform.isWindows,
    onCheck: () => _check(manual: true), onDownload: _download,
    onLater: () => setState(() => _release = null),
    onCancel: () => _downloadClient?.close(),
  );
}

