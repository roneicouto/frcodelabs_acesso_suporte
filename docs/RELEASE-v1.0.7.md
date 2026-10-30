## CF Link 1.0.7 — correção da atualização e novo visual

### Instalação inicial desta correção

**Se você usa 1.0.5 ou 1.0.6, baixe e instale/abra a 1.0.7 manualmente.**
O erro está na chamada do atualizador dessas versões. Elas conseguem baixar o
pacote, mas podem falhar após a confirmação; o cliente antigo precisa ser
substituído para receber a correção.

### O que mudou

- Corrigida a inicialização do PowerShell após o download e a confirmação.
- O aplicativo só fecha depois que o atualizador sinaliza que está pronto.
- Mensagens diferentes para problemas de download e de início da instalação.
- Versão e acesso às licenças alinhados em uma linha discreta.
- Nova versão apresentada em cartão violeta, com botão **Atualizar agora**,
  opção **Mais tarde** e progresso dentro do cartão.
- Consulta manual mais discreta, sem o texto quebrado no painel estreito do Full.

As regras de senha, servidor, autenticação e instalação Full/QS permanecem.
O Windows ainda pode solicitar autorização de administrador e exibir os avisos
normais de executáveis sem assinatura comercial.

Validação: análise e compilação Flutter, inspeção visual em 200/280 px e três
cenários com o lançador Dart real e executáveis inofensivos (Full, QS e arquivo
corrompido). O processo pai encerra antes da aplicação, verificando que o helper
continua e reabre o aplicativo de teste. Instalação real com serviço/UAC e
sessões remotas continuam dependendo do piloto.
Os três cenários também passaram com o lançador compilado como aplicativo
Windows sem console.

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.7** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

Fontes Windows: `CFLink-1.0.7-source.zip`. Fontes dos DMGs:
`CFLink-1.0.2-source.zip`. Confira os hashes em `SHA256SUMS.txt` e os pacotes
em `release-manifest.json`. Os arquivos automáticos “Source code” deste
repositório de downloads contêm somente a documentação.

Base RustDesk 1.5.0, GNU AGPLv3. Créditos e licença preservados em **Sobre**.
