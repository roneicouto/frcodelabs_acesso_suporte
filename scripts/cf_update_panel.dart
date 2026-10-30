import 'package:flutter/material.dart';

class CfUpdatePanel extends StatelessWidget {
  final String? version;
  final bool busy;
  final double? progress;
  final String status;
  final bool internalUpdate;
  final VoidCallback onCheck;
  final VoidCallback onDownload;
  final VoidCallback onLater;
  final VoidCallback onCancel;

  const CfUpdatePanel({super.key, this.version, required this.busy,
    this.progress, required this.status, required this.internalUpdate,
    required this.onCheck, required this.onDownload, required this.onLater,
    required this.onCancel});

  static const _muted = Color(0xFFADB5C4);
  static const _accent = Color(0xFF06D0D7);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (version != null) Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF306BEB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.system_update_alt_rounded, size: 17, color: _accent),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nova versão', style: TextStyle(fontSize: 12,
                height: 1.3, fontWeight: FontWeight.w600, color: Color(0xFFF9FAFB))),
              const SizedBox(height: 2),
              Text('FR CODE LABS $version', style: const TextStyle(fontSize: 11,
                height: 1.3, fontWeight: FontWeight.w400, color: _muted)),
            ])),
          ]),
          const SizedBox(height: 12),
          if (progress == null) ...[
            FilledButton.icon(
              onPressed: busy ? null : onDownload,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF306BEB), foregroundColor: Colors.white,
                minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(internalUpdate ? 'Atualizar agora' : 'Baixar agora'),
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: busy ? null : onLater,
              style: TextButton.styleFrom(foregroundColor: _muted,
                minimumSize: const Size(0, 28), padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
              child: const Text('Mais tarde')),
          ] else ...[
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 5,
                color: _accent, backgroundColor: const Color(0xFF374151))),
            const SizedBox(height: 8),
            Text('Baixando… ${(progress! * 100).floor()}%', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w400)),
            TextButton(onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: _muted,
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
              child: const Text('Cancelar download')),
          ],
        ]),
      ),
      TextButton(
        onPressed: busy ? null : onCheck,
        style: TextButton.styleFrom(foregroundColor: _muted,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          minimumSize: const Size(0, 32), tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (busy && version == null)
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
          else const Icon(Icons.refresh_rounded, size: 15),
          const SizedBox(width: 6),
          const Flexible(child: Text('Verificar atualização', maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      if (status.isNotEmpty && progress == null) Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Text(status, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, height: 1.4,
            fontWeight: FontWeight.w400, color: _muted))),
    ],
  );
}

