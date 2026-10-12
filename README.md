# CF Link — CF Tecnologia

Cliente de suporte remoto personalizado, baseado no RustDesk OSS 1.5.0.
Servidor ID `179.198.111.247:21116`, relay `179.198.111.247:21117` e chave pública
de `assets/id_ed25519.pub` incorporados à compilação.

## Perfis

| Perfil | Realizar conexão | Receber conexão | Autorização | Windows |
|---|---|---|---|---|
| CF Link Full | Sim, usando IDs do servidor da empresa | Sim | Senha individual ou aprovação local | Instalável |
| CF Link QS | Bloqueado no núcleo, incluindo inversão de lados | Sim | Senha temporária ou aprovação local | Portátil; fechar a janela encerra o aplicativo |

Os perfis possuem diretórios próprios (`CFLink` e `CFLinkQS`), evitando misturar
preferências e serviços. O Full não incorpora senha permanente compartilhada.
O QS não permite instalação normal, instalação silenciosa nem instalação do
serviço Windows. Não é uma versão garantidamente menor em tamanho: utiliza
os componentes de captura e de recepção necessários ao RustDesk.

Desde a versão 1.0.1, Full e QS usam exclusivamente o tema dark, sem seletor
de tema claro ou do sistema. O QS exibe uma senha temporária de oito caracteres:
ela permite acesso sem confirmação local; sem a senha, a conexão depende de
aprovação de quem está recebendo o suporte. Não há senha fixa compartilhada.

## Configuração fixa

As opções incorporadas têm prioridade sobre arquivos TOML, importações,
preferências do usuário e parâmetros de configuração. A leitura de servidor
e chave pelo nome do executável foi desativada. A tela de rede fica oculta.
O Full recusa conexões para outro servidor (`ID@servidor`) e acesso por IP;
conexões entre dispositivos identificados pelo servidor continuam podendo
usar transporte direto P2P ou relay, conforme o RustDesk.

O bloqueio vale para este aplicativo. Um administrador que substitua ou
recompile o binário pode modificar seu comportamento. Trocas de servidor
exigem uma nova compilação e distribuição. Atualização automática para
o RustDesk original fica desativada.

## Identidade

- Nome: **CF Link**; versão de personalização **1.0.2**.
- Símbolo próprio: [branding/cf-link-symbol.png](branding/cf-link-symbol.png).
- Assinatura visual: [branding/cf-link-wordmark.png](branding/cf-link-wordmark.png).
- Violeta `#7C3AED`, ciano `#22D3EE`, grafite `#111827`.
- Especificação e prompts: [branding/identity.json](branding/identity.json).

As imagens finais foram criadas com a ferramenta integrada `image_gen`.
Os tamanhos ICO, ICNS e PNG das plataformas são exportados por
`scripts/export-icons.py`, preservando os arquivos originais.

## Compilar no Windows x64

Requer Python, Git e Visual Studio com as ferramentas C++ e o SDK Windows.
O ambiente instalado em `.tools` não substitui o Flutter de outros projetos.

```powershell
.\scripts\setup-windows.ps1
.\scripts\build-windows.ps1 -Profile both
```

Para repetir apenas um perfil com a ponte já gerada:

```powershell
.\scripts\build-windows.ps1 -Profile qs -SkipBridge
```

Saídas:

- `dist/windows/CFLink-1.0.2-install.exe`: instalador Full.
- `dist/windows/CFLinkQS-1.0.2.exe`: executável único QS, sem instalação.
- `dist/windows/full/` e `dist/windows/qs/`: aplicativos sem empacotamento.

Os executáveis não recebem assinatura Authenticode neste projeto. Não há
certificado de assinatura fornecido. Não instale pacotes de teste sobre
outro aplicativo com o mesmo nome sem confirmar a versão.

Para gerar o pacote de fontes correspondente a partir do checkout de trabalho:

```powershell
python scripts/package-source.py
```

Ele inclui o código modificado, o submódulo, os arquivos gerados e os scripts.
Não inclui ferramentas baixadas, certificados, senhas nem a chave privada.
Ao distribuir os executáveis, disponibilize também os fontes correspondentes
conforme a licença AGPLv3 de RustDesk. Créditos preservados em `LICENCE`
e [docs/NOTICE.txt](docs/NOTICE.txt).

## Verificação do piloto

Windows x64: os dois executáveis foram gerados. Os dois testes de política
passaram em cada perfil (quatro resultados aprovados). A verificação das DLLs
empacotadas confirmou os nomes `CFLink` / `CFLinkQS`, a base 1.5.0 e o bloqueio
de instalação no QS. As portas TCP 21115, 21116 e 21117 estão acessíveis.
Não foi realizado um atendimento real entre dois dispositivos.

```powershell
python scripts/check-server.py
. .\scripts\env.ps1
Set-Location upstream
cargo test --lib --features flutter,cf-full cf_link::tests
cargo test --lib --features flutter,cf-qs cf_link::tests
```

`python scripts/verify-windows.py` verifica os aplicativos empacotados sem
instalar serviços nem abrir a interface.

Teste em dois computadores: instalar o Full em um, abrir o QS no outro,
conectar ao ID do QS pelo Full, aceitar localmente e confirmar imagem e
controle. Rejeitar outra solicitação; fechar o QS e confirmar que não aceita
novas conexões. Testar parâmetros de conexão no QS, importação de um servidor
alternativo e renomeação do executável. A chave pública só está validada
criptograficamente contra o servidor depois de uma sessão bem-sucedida.

## Demais plataformas

Android ARM64 pode ser compilado neste Windows com as ferramentas da etapa
Windows e o Android SDK 36 / NDK r28c já instalados:

```powershell
.\scripts\setup-android.ps1
.\scripts\build-android.ps1 -BuildProfile both
```

As assinaturas Android usam a chave gerada em `.tools/signing/cf-link.jks`
e a senha em `.tools/signing/password.txt`. Faça backup privado dos dois
arquivos: a mesma identidade é necessária para atualizar os aplicativos.
Esses arquivos e `android/key.properties` são excluídos dos pacotes de fontes.
Os perfis têm IDs de pacote diferentes, permitindo instalação simultânea.
O QS inicia na tela de compartilhar, não oferece início automático e encerra
seu processo quando é removido da lista de recentes. Deixá-lo em segundo
plano durante o atendimento mantém o serviço de captura, permitindo usar
outros aplicativos no telefone.

A compilação utiliza os codecs de software da base. O recurso experimental
Rust `mediacodec` não é habilitado. Permissões de captura e acessibilidade
continuam sendo concedidas pelo usuário. Não foi realizado teste em aparelho.

macOS exige compilação em macOS (Mac próprio ou runner GitHub Actions) e, para
distribuição assinada/notarizada, credenciais Apple apropriadas.
O fluxo macOS inclui `scripts/setup-macos.sh` para obter o código fixado,
instalar as dependências e preparar os SDKs locais, seguido de
`scripts/build-macos.sh` para gerar os DMGs Full e QS. O guia completo está em
[docs/MACBOOK.md](docs/MACBOOK.md). Os pacotes serão da arquitetura do MacBook
(Apple Silicon ou Intel), com mínimo configurado em macOS 12.3.
Os scripts foram verificados no Windows, mas a compilação macOS ainda precisa
ser executada no MacBook.
A assinatura ad hoc do script não substitui Developer ID / notarização.

O Git local está preparado para versionar configuração, identidade, scripts
e dependências vendorizadas; caches, binários e credenciais ficam ignorados.
O código está disponível em [cdlawliet/CFLink](https://github.com/cdlawliet/CFLink).
Use [docs/VALIDACAO-WINDOWS.md](docs/VALIDACAO-WINDOWS.md) para registrar o teste
de conexão real e as restrições dos dois perfis antes da distribuição aos clientes.

iOS no RustDesk é controlador: não atende ao requisito de Full bidirecional
nem de QS receptor. Não há pacote iOS incluído neste piloto.

Consulte `dist/android` para os APKs efetivamente gerados. Não há artefatos
macOS compilados neste ambiente.

Android ARM64: os APKs Full e QS foram gerados e suas assinaturas v2 foram
verificadas. Os nomes, IDs dos pacotes e a arquitetura `arm64-v8a` foram
confirmados no manifesto compilado. As bibliotecas nativas têm alinhamento
de 16 KB. Windows usa binários sem Authenticode; Android usa a identidade
privada de assinatura deste projeto.

## Superfície de alteração

A versão 1.0.1 altera `scripts/cf_link.rs` para fixar a preferência local dark
e habilitar o modo nativo de senha temporária ou aprovação no QS. Não muda
a implementação de autenticação do RustDesk. No Flutter, os hooks em
`common.dart` impedem light/system nos clientes CF; `desktop_setting_page.dart`
e `mobile/pages/settings_page.dart` ocultam o seletor nesses clientes. Os
caminhos antigos continuam ativos quando a opção CF de dark fixo está ausente.
Os testes de configuração tentam gravar light e verificam que dark prevalece;
no QS verificam o modo, a ausência de senha permanente e os oito caracteres.

A preparação para MacBook adiciona scripts e dependências de build locais.
`prepare-macos.py` altera a identidade do bundle e o mínimo de macOS em
`AppInfo.xcconfig`, `Info.plist`, `Podfile`, `project.pbxproj` e nos metadados
de empacotamento de `Cargo.toml`; essas alterações são necessárias para nomes
separados e um mínimo coerente no build nativo e na interface. Os workarounds
Flutter ficam no SDK privado. Esta etapa não altera as políticas de conexão
nem recompila os executáveis Windows/Android já entregues.

Alterações no núcleo são condicionadas a `cf-full` / `cf-qs`; sem esses
recursos, os caminhos originais do RustDesk permanecem.

- `src/lib.rs`, `Cargo.toml`: habilitam os módulos de personalização.
- `src/common.rs`: inicialização antecipada e prioridade da política fixa.
- `src/platform/windows.rs`: ignora servidor no nome do EXE e bloqueia instalação QS.
- `src/platform/macos.rs`, `src/service.rs`: bloqueiam serviço QS e aplicam o nome
  da empresa antes de gerar os plists, evitando usar os caminhos do RustDesk original.
- `src/client.rs`: valida a política antes de abrir uma conexão.
- `src/flutter_ffi.rs`: aplica a configuração ao serviço Android também.
- `flutter/lib/common.dart`: cores e cabeçalho de marca.
- `flutter/lib/desktop/widgets/tabbar_widget.dart`: encerra a janela principal QS.
- Recursos de ícones e `Runner.rc`: identidade dos aplicativos.
- `libs/portable`: nome, marca e cor do empacotador Windows.
- `flutter/pubspec.lock`: resolução compatível com o Flutter 3.24.5 usado pelo upstream.
- Android `build.gradle` / manifesto: identidade e IDs dos pacotes.
- Android `gradle.properties`: memória de 4 GB para concluir a otimização R8 do APK.
- Android `MainService.kt` / `BootReceiver.kt`: encerramento e bloqueio de início automático QS.
- Flutter mobile `home_page.dart` / `settings_page.dart`: tela inicial QS e ocultação de início automático.
- `build.rs`: seleciona os fontes C pelo alvo, permitindo compilar Android a partir do Windows.
- `vendor/libsodium-sys/build.rs`, `Cargo.lock` e o patch em `Cargo.toml`: separam
  a biblioteca Android das ferramentas Windows usadas na compilação. A API de
  execução do libsodium-sys 0.2.7 foi preservada; sem a variável específica de
  alvo, o comportamento original de compilação permanece.

O submódulo `hbb_common` não foi modificado. Referências exatas das fontes
e ferramentas estão em [config/source-lock.json](config/source-lock.json).

## Créditos e atualização da base

Desde 1.0.2, a tela principal exibe a marca CF Link e oferece “Sobre / Licenças”,
acessível no Full e no QS, com autoria, licença completa e indicação do ZIP
de fontes que deve acompanhar os pacotes. A implementação fica em
`scripts/cf_legal.dart`; os avisos são empacotados como assets pelo overlay.
Os hooks adicionais em `common.dart`, `desktop_home_page.dart` e
`mobile/pages/server_page.dart` ocultam o banner e tornam os avisos acessíveis
nos clientes CF, preservando o caminho original nos demais clientes.
Não houve alteração nas políticas de autenticação/conexão nesta etapa.

O procedimento de atualização da base está em
[docs/ATUALIZAR-RUSTDESK.md](docs/ATUALIZAR-RUSTDESK.md).
