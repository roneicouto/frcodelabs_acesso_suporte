import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:window_manager/window_manager.dart';
import 'cf_service_recovery.dart';

class CfServiceStatus extends StatefulWidget {
  const CfServiceStatus({super.key});
  @override
  State<CfServiceStatus> createState() => _CfServiceStatusState();
}

class _CfServiceStatusState extends State<CfServiceStatus> with WindowListener {
  bool _busy = false;
  String _state = '';
  bool _checkOnFocus = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) windowManager.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _check(); });
  }

  File _repairMarker(String exe) {
    final name = exe.replaceAll('\\', '/').split('/').last;
    return File('${Directory.systemTemp.path}/FRCodeLabs-service-repair/$name.marker');
  }

  Future<void> _check({bool autoRepair = true}) async {
    if (!mounted || _busy || !Platform.isWindows || bind.isIncomingOnly()) return;
    setState(() { _busy = true; });
    try {
      final exe = await bind.mainGetCommon(key: 'cf-installed-exe');
      if (exe.isEmpty) return; // Full portable never installs or starts a service.
      if (mounted) setState(() => _state = 'checking');
      final folder = await Directory.systemTemp.createTemp('FRCodeLabs-service-');
      final helper = File('${folder.path}/service.ps1');
      await helper.writeAsBytes([0xef, 0xbb, 0xbf,
        ...utf8.encode(await rootBundle.loadString('assets/cf_service_windows.ps1'))]);
      final plan = File('${folder.path}/plan.json');
      final name = exe.replaceAll('\\', '/').split('/').last.replaceFirst(RegExp(r'\.exe$', caseSensitive: false), '');
      await plan.writeAsString(jsonEncode({'name': name, 'exe': exe}));
      final windows = Platform.environment['SystemRoot'] ?? r'C:\Windows';
      final process = await Process.run('$windows/System32/WindowsPowerShell/v1.0/powershell.exe',
        ['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass',
          '-File', helper.path, '-Plan', plan.path]);
      final file = File('${plan.path}.result');
      if (!await file.exists()) {
        await File('${plan.path}.launch.log').writeAsString('${process.exitCode}\n${process.stderr}');
        throw const FileSystemException('Service helper did not return a result');
      }
      final result = jsonDecode((await file.readAsString()).replaceFirst('\uFEFF', '')) as Map<String, dynamic>;
      final state = result['state'];
      if (state == 'running' || state == 'started') {
        try {
          final marker = _repairMarker(exe);
          if (await marker.exists()) await marker.delete();
        } on FileSystemException catch (error) {
          debugPrint('FR CODE LABS service recovery marker cleanup: $error');
        }
      }
      if (mounted) {
        setState(() => _state =
          ['running', 'started', 'missing', 'mismatch'].contains(state) ? state as String : 'error');
      }
    } catch (_) {
      if (mounted) setState(() => _state = 'error');
    } finally { if (mounted) setState(() => _busy = false); }
    if (mounted && autoRepair && _state == 'missing') await _repair(automatic: true);
  }

  @override
  void onWindowClose() { _checkOnFocus = true; }

  @override
  void onWindowMinimize() { _checkOnFocus = true; }

  @override
  void onWindowFocus() {
    if (_checkOnFocus) {
      _checkOnFocus = false;
      _check();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _repair({bool automatic = false}) async {
    if (_busy || !Platform.isWindows || bind.isIncomingOnly()) return;
    final exe = await bind.mainGetCommon(key: 'cf-installed-exe');
    if (exe.isEmpty || !mounted) return;
    if (!automatic) {
      final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Reparar serviço do FR CODE LABS?'),
      content: const Text('O Full vai registrar novamente seu serviço e reabrir o aplicativo, preservando o ID e as configurações. As conexões em andamento serão interrompidas. O Windows poderá solicitar autorização de administrador.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reparar serviço')),
      ],
      ));
      if (confirm != true || !mounted) return;
    }
    setState(() { _busy = true; _state = 'repairing'; });
    try {
      // Existing native repair imports the user's configuration, registers the
      // service, restores shortcuts and reopens the Full. Do not duplicate it.
      final attempted = await cfAttemptServiceRepair(_repairMarker(exe),
        () => bind.mainSetOption(key: 'stop-service', value: ''), force: !automatic);
      if (!attempted && mounted) setState(() => _state = 'repair_failed');
    } catch (_) {
      if (mounted) setState(() => _state = 'repair_failed');
    } finally { if (mounted) setState(() => _busy = false); }
    if (mounted && _state != 'repair_failed') {
      await _check(autoRepair: false);
      if (mounted && _state == 'missing') setState(() => _state = 'repair_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isEmpty) return const SizedBox.shrink();
    final ok = _state == 'running' || _state == 'started';
    final repair = _state == 'missing' || _state == 'mismatch' || _state == 'repair_failed';
    final text = ok ? 'Serviço ativo' : _state == 'checking' ? 'Verificando serviço…' :
      _state == 'repairing' ? 'Preparando serviço…' :
      _state == 'repair_failed' ? 'Não foi possível preparar o serviço' :
      _state == 'missing' ? 'Serviço não instalado' : _state == 'mismatch' ? 'Serviço precisa de reparo' : 'Não foi possível iniciar o serviço';
    return Padding(padding: const EdgeInsets.only(top: 8), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(ok ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
          size: 12, color: ok ? const Color(0xFF6BC4A6) : const Color(0xFFADB5C4)),
        const SizedBox(width: 5),
        Flexible(child: Text(text, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, height: 1.3, fontWeight: FontWeight.w400, color: Color(0xFFADB5C4)))),
      ]),
      if (!ok && _state != 'checking' && _state != 'repairing') TextButton(
        onPressed: _busy ? null : repair ? _repair : _check,
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFADB5C4),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
        child: Text(repair ? 'Reparar serviço' : 'Tentar novamente')),
    ]));
  }
}
