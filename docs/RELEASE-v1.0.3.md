## CF Link 1.0.3 para Windows

### Alterações

- Escala adaptada como padrão para novas conexões e migração inicial dos clientes
  já salvos. Mudanças manuais posteriores de escala continuam sendo respeitadas.
- Full e QS aceitam a senha padrão de recebimento definida pelo responsável
  pelo projeto ou a senha temporária visível. A senha padrão não aparece na tela.
- O Full exige digitação em novas sessões: não envia a senha padrão, não reutiliza
  credenciais salvas e não oferece “Lembrar senha”. A aprovação local continua disponível.
- Aviso de atualização pelo repositório público do CF Link, com “Baixar atualização”
  e “Mais tarde”, mais um botão para consultar manualmente. Sem instalação automática.

A consulta automática ocorre no máximo uma vez a cada 24 horas por perfil.
Ela não envia IDs ou senhas do suporte. Falhas de rede não interrompem o atendimento.
Essa rotina começa a funcionar após instalar a versão 1.0.3; os clientes 1.0.2
precisam ser atualizados manualmente para recebê-la.

### Plataformas desta release

| Pacote | Versão real |
|---|---|
| Windows Full x64 — instalador | **1.0.3** |
| Windows QS x64 — portátil | **1.0.3** |
| macOS Full Apple Silicon ARM64 — DMG | **1.0.2**, mantido para preservar o download |
| macOS QS Apple Silicon ARM64 — DMG | **1.0.2**, mantido para preservar o download |

As mudanças acima estão nos novos executáveis Windows. Os DMGs não foram
recompilados nesta etapa: o código está preparado para a compilação no Mac.
Não há novo pacote Android ou Intel nesta release.

### Fontes e verificação

- `CFLink-1.0.3-source.zip`: fontes modificadas e instruções dos pacotes Windows novos.
- `CFLink-1.0.2-source.zip`: fontes fornecidas com a versão anterior, mantida nos DMGs.
- `SHA256SUMS.txt` e `release-manifest.json`: hashes, tamanhos e versão real de cada pacote.
- Os arquivos automáticos “Source code” deste repositório de downloads contêm
  somente sua documentação; para compilar o aplicativo use o ZIP CFLink correspondente.

Foram realizados cinco testes de comparação/seleção de atualização, três testes
de política em cada perfil, análise de código e verificações dos pacotes.
Sessões reais e execução macOS não foram testadas neste ambiente nesta publicação.

Os executáveis Windows seguem sem assinatura Authenticode; esta atualização não
elimina os avisos do SmartScreen. Os DMGs mantêm as características da publicação anterior.
Base RustDesk: 1.5.0. Licença: GNU AGPLv3; créditos preservados em “Sobre / Licenças”.
