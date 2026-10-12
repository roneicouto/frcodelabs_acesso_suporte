# Atualizar a base RustDesk do CF Link

Atualizar o RustDesk original e publicar uma nova versão do CF Link são etapas
distintas. O CF Link incorpora modificações de marca, tema, servidor e permissões;
uma atualização automática do cliente original não reaplica essas modificações.
Por isso, `allow-auto-update` fica desabilitado no cliente personalizado.

## Procedimento

1. Escolha uma release estável no [repositório oficial](https://github.com/rustdesk/rustdesk/releases)
   e leia as notas, principalmente mudanças de segurança, servidor, Flutter e builds.
2. Crie uma branch/cópia de trabalho independente. Preserve o código e os pacotes
   da versão publicada para poder voltar a ela. Comece com um `upstream/` limpo
   da nova release, sem substituir a pasta de trabalho original.
3. Registre o tag e o commit exatos da nova base, incluindo o commit de
   `libs/hbb_common`. Consulte os workflows da nova release para as versões
   compatíveis de Rust, Flutter, vcpkg, bridge, Xcode e Android NDK/SDK.
4. Atualize os arquivos da tabela abaixo. Não basta trocar o número da versão
   em um JSON: alguns scripts ainda contêm valores fixos.
5. Revise os pontos usados pelo overlay e adapte somente os hooks necessários.
   `replace_once` deve interromper a preparação se encontrar código inesperado;
   investigue o erro, em vez de desativar essa verificação.
6. Gere o bridge novamente e compile Full e QS separadamente em cada plataforma.
   Para macOS, execute no Mac. Reavalie dependências e caches se o compilador,
   SDK, arquitetura ou conjunto de bibliotecas nativas mudar.
7. Execute os testes de política, verifique os pacotes e faça sessões reais
   entre dois dispositivos. Confirme também a compatibilidade com o servidor OSS
   existente; não presuma que toda nova versão de cliente mantém essa compatibilidade.
8. Incremente a versão própria do CF Link, atualize os avisos, gere o pacote de
   fontes correspondente e os hashes. Distribua os pacotes personalizados e as
   fontes. Só publique depois da validação; preserve a versão anterior.

## Arquivos e valores que precisam de revisão

| Arquivo | Revisar ao atualizar a base |
|---|---|
| `config/client.json` | `upstream_tag` e versão própria `version`; conservar servidor e chave |
| `config/source-lock.json` | Tag, commit, submódulo, Rust/Flutter/bridge/vcpkg, mínimo macOS e hash do engine Windows quando aplicável |
| `config/android-vcpkg/vcpkg.json`, `config/macos-vcpkg/vcpkg.json` | Baseline e dependências de acordo com a nova base |
| `config/flutter-pubspec.lock` | Lockfile Dart resolvido com a versão compatível de Flutter da nova base |
| `scripts/setup-windows.ps1`, `scripts/env.ps1` | Tag, versões de ferramentas, dependências e preparação do SDK privado |
| `scripts/setup-android.ps1`, `scripts/build-android.ps1` | NDK/SDK, ferramentas de assinatura, arquitetura e `--build-number` |
| `scripts/setup-macos.sh`, `scripts/env-macos.sh`, `scripts/build-macos.sh` | Compatibilidade Xcode, CocoaPods, LLVM e versões do lock |
| `scripts/prepare-tools.py`, `scripts/prepare-macos-tools.py` | Patches Flutter: remover somente os que a nova base tornou desnecessários, adaptar os demais |
| `scripts/prepare.py`, `scripts/prepare-android.py`, `scripts/prepare-macos.py` | Trechos originais procurados pelo overlay, hooks e identidade |
| `scripts/cf_link.rs` | APIs de configuração e precedência das opções na nova base |
| `scripts/prepare-sodium.py`, `vendor/libsodium-sys` | Se a nova base ainda precisa do patch e usa a mesma versão da dependência |
| `scripts/verify-windows.py` | Versão base esperada, hoje `1.5.0` |
| `docs/NOTICE.txt`, `README.md`, guias e manifesto | Versões, atribuições e resultados realmente obtidos |

Os workflows e os lockfiles da **release escolhida** são a referência para a
atualização das ferramentas. Não troque tudo pela versão mais recente disponível
sem verificar compatibilidade. A personalização não autoriza alterar o submódulo
compartilhado arbitrariamente: fixe o commit previsto pela nova base.

## Regras a verificar em cada atualização

- Servidor `179.198.111.247:21116`, relay `179.198.111.247:21117` e chave pública
  continuam incorporados, sem edição pela interface ou substituição pelo nome do EXE.
- Full realiza e recebe usando IDs do servidor da empresa.
- QS impede conexão de saída e inversão de lados, não instala serviço e encerra
  a disponibilidade ao fechar o aplicativo.
- QS permite senha temporária de oito caracteres ou aprovação local, sem senha
  permanente compartilhada.
- Preferências Full/QS ficam separadas; dark permanece fixo em todas as janelas.
- Nome, ícones, notificações e “Sobre / Licenças” mantêm a identidade CF Link.
- A licença e os avisos continuam acessíveis, inclusive no QS; o ZIP distribuído
  contém as fontes da versão modificada, não apenas um link para o RustDesk original.

No Windows, carregue `scripts/env.ps1` e execute os dois testes descritos no guia
de personalização; depois rode `python scripts/verify-windows.py`. Use também
`docs/VALIDACAO-WINDOWS.md` para a sessão real. Testes de política e verificações
estáticas não comprovam captura de tela, controle remoto, permissões ou instalação.

## Publicação e atualização dos clientes instalados

A versão de personalização, por exemplo `1.0.2`, e a versão base RustDesk, hoje
`1.5.0`, são números independentes. Um ajuste de interface pode incrementar
somente a versão de personalização. Uma mudança de base exige o processo acima.

Hoje a entrega é manual: distribuir o novo instalador Full e o novo portátil QS,
fechar a versão anterior e instalar/abrir o pacote novo. Não reative o atualizador
original para tentar atualizar a marca. Um atualizador próprio, apontando para
releases CF Link, seria uma implementação adicional.

Para preservar configurações e continuidade de atualização, mantenha os nomes
internos `CFLink`/`CFLinkQS`, os IDs Android e a identidade privada de assinatura
Android. Incremente o versionCode Android (`--build-number`); trocar apenas
`--build-name` não é suficiente para uma atualização Android normal.

Se precisar atualizar o servidor por compatibilidade, planeje essa etapa
separadamente, preservando suas configurações e chaves. Não gere novas chaves
do servidor apenas para atualizar o cliente.
