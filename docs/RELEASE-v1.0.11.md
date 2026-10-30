## CF Link 1.0.11 — serviço do Full instalado

Ao abrir o **Full instalado no Windows**, o aplicativo verifica seu serviço:

- Ativo: mantém funcionando, sem reiniciar.
- Parado: tenta iniciar automaticamente. Se necessário, solicita autorização
  de administrador pelo Windows.
- Desabilitado ou pausado: tenta habilitar em modo automático ou retomar.
- Ausente ou com caminho divergente: mostra **Reparar serviço**. Após a sua
  confirmação, usa a rotina original para preservar o ID e as configurações,
  registrar o serviço e reabrir o Full.

O rodapé informa o estado e permite tentar novamente em caso de falha.
Full também verifica novamente ao reabrir a janela escondida ou minimizada.
Alternar entre programas ou retornar do UAC não dispara uma nova tentativa.
O reparo avisa que as conexões serão interrompidas. Se a autorização do Windows
for recusada, o aplicativo continua aberto e informa a falha.

**QS e Full portátil não instalam nem controlam serviços.** As regras de
senha, servidor e verificação de atualizações permanecem iguais.

Validação: análise/compilação Flutter, metadados dos pacotes e sete cenários
isolados do script com os comandos de serviço simulados. Os serviços do
computador não foram alterados por esses testes. O início/reparo real e os
diálogos UAC precisam ser validados no piloto.

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.11** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

Fontes Windows: `CFLink-1.0.11-source.zip`. Fontes dos DMGs:
`CFLink-1.0.2-source.zip`. Confira `SHA256SUMS.txt` e `release-manifest.json`.
Os arquivos automáticos “Source code” do repositório de downloads contêm
somente a documentação; use o ZIP CFLink correspondente para compilar.

Base RustDesk 1.5.0, GNU AGPLv3; créditos preservados em **Sobre**.
