import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CfLegalButton extends StatelessWidget {
  final bool isQs;
  const CfLegalButton({super.key, required this.isQs});

  Future<void> _show(BuildContext context) async {
    try {
      final info = jsonDecode(await rootBundle.loadString('assets/cf_legal.json'))
          as Map<String, dynamic>;
      final notice = await rootBundle.loadString('assets/cf_notice.txt');
      final license = await rootBundle.loadString('assets/cf_license.txt');
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sobre / Licenças'),
          scrollable: true,
          content: SizedBox(
            width: 560,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SelectableText('${info['product']}${isQs ? ' QS' : ''} ${info['version']}\n'
                  '${info['company']}\nBase: RustDesk ${info['base']}\n\n'
                  'Copyright © 2026 Purslane Tech Pte. Ltd. e colaboradores RustDesk.\n'
                  'Personalização e identidade visual: ${info['company']}.\n\n'
                  'Este software pode ser redistribuído e modificado nos termos da '
                  'GNU AGPLv3. É fornecido sem garantia, nos limites da licença.\n\n'
                  'Código-fonte correspondente: ${info['source_archive']}. '
                  'Esse pacote deve acompanhar a distribuição do aplicativo, '
                  'incluindo as modificações e as instruções de compilação.'),
              TextButton(
                onPressed: () async {
                  final opened = await launchUrl(Uri.parse('https://github.com/rustdesk/rustdesk'));
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Não foi possível abrir o projeto original.')));
                  }
                },
                child: const Text('Projeto original RustDesk'),
              ),
              const Divider(),
              SelectableText(notice),
              const Divider(),
              const Text('GNU Affero General Public License v3',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(license, style: const TextStyle(fontSize: 12)),
            ]),
          ),
          actions: [TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'))],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar os avisos legais.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Expanded(child: FutureBuilder<String>(
        future: rootBundle.loadString('assets/cf_legal.json').then(
          (text) => (jsonDecode(text) as Map<String, dynamic>)['version'] as String),
        builder: (context, snapshot) => Text(
            snapshot.hasData ? 'Versão ${snapshot.data}' :
              (snapshot.hasError ? 'Versão indisponível' : ''),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
          ),
      )),
      TextButton.icon(
        onPressed: () => _show(context),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFB8BDC9),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(0, 30),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.info_outline_rounded, size: 14),
        label: const Text('Sobre', semanticsLabel: 'Sobre e licenças'),
      ),
    ],
  );
}
