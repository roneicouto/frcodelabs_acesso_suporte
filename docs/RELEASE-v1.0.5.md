## CF Link 1.0.5 para Windows

Full e QS agora têm atualização interna: download com progresso e cancelamento,
verificação de tamanho e SHA-256 e confirmação antes de fechar o aplicativo.
Ao escolher **Atualizar e reiniciar**, o pacote é aplicado e o CF Link é aberto
novamente. As conexões em andamento são interrompidas nessa etapa.

O Full instalado preserva o serviço e as configurações pelo instalador nativo,
com autorização de administrador quando o Windows solicitar. QS continua
portátil; seu executável original é substituído e uma cópia `.previous` é mantida.
O Full portátil também é atualizado e reaberto sem a tela de instalação.
As senhas, o tema escuro, a versão visível e a escala adaptada permanecem.

### Como começar

Quem está na **1.0.4 ou anterior deve baixar e instalar/abrir a 1.0.5 manualmente**.
O botão dessas versões ainda abre o navegador. Depois de instalada a 1.0.5,
uma próxima release poderá ser baixada e aplicada dentro do aplicativo.
Feche outras janelas do mesmo portátil antes de atualizar.

Não há alteração na assinatura dos executáveis; o SmartScreen e o UAC podem
continuar exibindo as confirmações normais do Windows.

### Pacotes

| Sistema | Versão Full / QS |
|---|---|
| Windows x64 | **1.0.5** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados até recompilação no Mac |

Links estáveis preservados. Fontes Windows: `CFLink-1.0.5-source.zip`.
Fontes dos DMGs: `CFLink-1.0.2-source.zip`. Consulte `SHA256SUMS.txt` e
`release-manifest.json`. Os arquivos automáticos “Source code” do repositório
de downloads contêm a documentação; use o ZIP CFLink para compilar o aplicativo.

Validação: oito testes Dart e três cenários isolados de aplicação portátil no
Windows. O fluxo com instalação real/UAC e sessões remotas requer teste no piloto.
Base RustDesk 1.5.0, GNU AGPLv3; créditos e licença preservados no aplicativo.
