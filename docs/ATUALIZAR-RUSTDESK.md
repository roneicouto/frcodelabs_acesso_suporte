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

- Servidor ID, relay e chave pública
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

No Windows, desde a 1.0.5 o cliente pode baixar, verificar e aplicar a atualização
após confirmação. Para versões anteriores, distribua o novo instalador Full e
o novo portátil QS manualmente. Não reative o atualizador original para tentar
atualizar a marca. macOS e Android continuam com o download externo.

Para preservar configurações e continuidade de atualização, mantenha os nomes
internos `CFLink`/`CFLinkQS`, os IDs Android e a identidade privada de assinatura
Android. Incremente o versionCode Android (`--build-number`); trocar apenas
`--build-name` não é suficiente para uma atualização Android normal.

Se precisar atualizar o servidor por compatibilidade, planeje essa etapa
separadamente, preservando suas configurações e chaves. Não gere novas chaves
do servidor apenas para atualizar o cliente.

## Aviso de novas versões do CF Link (desde 1.0.3)

O atualizador original do RustDesk continua desabilitado. Uma consulta própria
ao repositório público do CF Link avisa sobre novos pacotes e deixa o usuário
decidir se deseja atualizar. Até a 1.0.4 a instalação é manual. Atualize
`config/client.json` e os labels dos assets a cada publicação para que a
comparação use a versão própria do aplicativo e do pacote realmente disponível.

## Aplicação interna no Windows (1.0.5)

O pacote deve ter `size` e `digest` (`sha256:...`) válidos na API do GitHub.
Além de preservar os nomes dos assets e labels, não publique um novo tag usando
um binário Windows antigo com label novo. O cliente verifica os bytes recebidos
antes de oferecer **Atualizar e reiniciar**. Não há senha enviada na conexão.

O helper usa o comando nativo de atualização para Full instalado e substitui o
lançador original para QS/Full portátil. Mantenha o hook do caminho original no
packer e a identificação da instalação via `main_get_common`. Inclua
`cf_update_windows.ps1` nos assets Flutter e no ZIP das fontes. O Full portátil
deve reiniciar com `--noinstall`, evitando abrir a tela de instalação.

Para testar o fluxo completo é necessário instalar a 1.0.5 e publicar uma versão
superior, com binários recompilados e metadados correspondentes. Não é possível
acrescentar o atualizador interno aos executáveis 1.0.4 já distribuídos sem
atualizá-los primeiro. A confirmação UAC normal não é eliminada.

O piloto Windows identificou que a chamada PowerShell das versões 1.0.5/1.0.6
com `ProcessStartMode.detached` pode falhar antes de iniciar o script. A 1.0.7
usa processo normal com pipes e registra falhas de inicialização. É necessário
instalar a **1.0.7 manualmente uma vez** para corrigir o cliente de origem.
O teste do helper deve usar `scripts/tests/launch-updater.dart`, a mesma função
Dart chamada pelo produto, e encerrar o pai antes de aplicar o pacote isolado.
