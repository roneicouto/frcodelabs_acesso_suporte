# Personalizar este projeto para outra empresa

Este guia parte do CF Link 1.0.2 e mantém o mesmo servidor RustDesk OSS.
O objetivo é trocar a marca, os identificadores dos aplicativos e os nomes dos
pacotes, preservando as políticas de conexão já implementadas.

O caminho mais rápido é manter os nomes técnicos dos arquivos e substituir
seu conteúdo visual. **Editar somente `config/client.json` não é suficiente:**
há textos, cores e nomes de saída fixos nos scripts, indicados abaixo.

## 1. Preparar uma cópia independente

Trabalhe em outra pasta ou repositório. Transfira estes itens da raiz do projeto:

```text
assets/id_ed25519.pub
branding/
config/
docs/
scripts/
vendor/
README.md
LICENCE
.gitignore
.gitattributes
```

Comece essa cópia **sem `upstream/`, `.tools/` e `dist/`**. O setup obterá o
RustDesk original na versão fixada e aplicará a nova marca. Isso também evita
compartilhar as credenciais de assinatura Android da CF Tecnologia.

Se recebeu o ZIP de código-fonte completo, copie os itens acima para uma nova
pasta e trabalhe nela. O `upstream/` desse ZIP já está personalizado para CF Link.

Os scripts usam `replace_once`: são repetíveis para a mesma personalização,
mas não migram automaticamente de uma marca para outra. Mudar os textos de
substituição e reaplicar sobre um `upstream/` já personalizado pode causar
`Unexpected upstream content`. Nesse caso, use uma nova cópia limpa; não
resolva com substituição global, reset ou exclusão da pasta original da CF.

## 2. Manter o servidor e o comportamento

Não altere estes valores em `config/client.json`:

| Campo | Valor mantido |
|---|---|
| `id_server` | `179.198.111.247:21116` |
| `relay_server` | `179.198.111.247:21117` |
| `public_key_file` | `assets/id_ed25519.pub` |
| `upstream_tag` | `1.5.0` |

Mantenha o conteúdo de `assets/id_ed25519.pub` e as versões/commits de
`config/source-lock.json`. O cliente usa a chave pública; ele não precisa da
chave privada do servidor.

Preserve as regras implementadas em `scripts/cf_link.rs` e nos hooks de preparação:

- Full realiza e recebe conexões usando IDs do servidor da empresa.
- QS apenas recebe, fica disponível com o aplicativo aberto e não instala serviço.
- QS aceita senha temporária de oito caracteres **ou** aprovação local.
- Os dois perfis usam dark fixo, sem light ou opção de seguir o sistema.
- Servidor, relay e chave permanecem incorporados e bloqueados na interface.
- Full e QS são compilados separadamente; nunca habilite as duas features juntas.

Usar o mesmo servidor OSS não cria separação de acesso entre as empresas pela
marca do aplicativo. A autorização continua dependendo da senha ou aprovação
do cliente. Não trate a mudança de logo como uma barreira de isolamento.

## 3. Definir nomes e identificadores

Exemplo para uma empresa fictícia chamada **Nova Tecnologia**, com o app
**Nova Link**:

| Campo em `config/client.json` | Exemplo |
|---|---|
| `product` | `Nova Link` |
| `company` | `Nova Tecnologia` |
| `version` | `1.0.0` — versão inicial do novo produto |
| `full_app_name` | `NovaLink` |
| `qs_app_name` | `NovaLinkQS` |
| `android_full_package` | `com.novatecnologia.novalink.full` |
| `android_qs_package` | `com.novatecnologia.novalink.qs` |
| `palette` | Cores da nova marca, em hexadecimal |

Use nomes internos sem espaços, acentos ou caracteres especiais. Escolha nomes
diferentes de `CFLink` e `CFLinkQS`: eles também influenciam diretórios de
configuração e nomes de serviços. Os nomes visíveis podem conter espaços.
Mantenha identificadores Android distintos para Full e QS, em minúsculas.

O `product` do JSON não atualiza todos os textos da interface sozinho.
Faça também as alterações das próximas seções.

## 4. Trocar logo e registrar a identidade

Substitua as imagens, mantendo estes caminhos para reduzir alterações:

| Arquivo | Conteúdo esperado |
|---|---|
| `branding/cf-link-symbol.png` | Símbolo da nova empresa; PNG quadrado RGBA, transparente, preferencialmente 1024 × 1024 ou maior |
| `branding/cf-link-wordmark.png` | Logo horizontal com o novo nome; PNG transparente, proporção próxima de 3:1 |
| `branding/identity.json` | Nomes, empresa, conceito, paleta e origem reais das novas imagens |

O wordmark é reduzido para 96 × 32 no launcher portátil do Windows: use uma
composição legível nesse tamanho. A assinatura na tela principal é formada
pelo símbolo e por texto Flutter, configurado em `prepare.py`.

`scripts/export-icons.py` gera o ICO Windows, o ICNS macOS e os PNGs Android.
Não precisa editar manualmente cada tamanho. O ICO existente será sobrescrito.

`branding/identity.json` documenta a marca, mas não controla automaticamente a
interface. Atualize ou remova os prompts e a indicação de geração por IA se
eles não corresponderem às imagens novas. O logo original em `assets/` não é
a imagem consumida pelos scripts de exportação.

## 5. Alterar os textos e as cores aplicados ao código

### `scripts/prepare.py`

Altere **os textos novos à direita das substituições**, preservando os textos
originais usados para localizar o RustDesk. Exemplo:

```python
# O primeiro texto continua sendo o original do RustDesk.
replace_once(rc, 'VALUE "CompanyName", "Purslane Tech Pte. Ltd."',
             'VALUE "CompanyName", "Nova Tecnologia"')
```

Atualize estes pontos:

- No bloco `loadLogo`, troque `CF Link QS`, `CF Link` e `CF Tecnologia` pelos
  nomes visíveis e pela empresa nova.
- Nas substituições de `Runner.rc`, troque os valores novos de `CompanyName`,
  `FileDescription` e `ProductName`.
- Nas substituições de `libs/portable/Cargo.toml`, troque os valores novos de
  `ProductName` e `FileDescription`.
- Atualize os nomes humanos nas mensagens de bloqueio de configuração,
  instalação QS e serviços macOS, e na mensagem de compilação separada.
  Preserve as condições e os nomes das features nesses mesmos blocos.
- No dicionário `colors`, altere as cores de destino. As chaves continuam sendo
  as cores originais esperadas no RustDesk.
- Opcionalmente atualize a mensagem de conclusão do script.

**A paleta do JSON é descritiva neste projeto.** Para alterar as cores reais,
edite também o dicionário `colors`. Atualmente ele aplica violeta `7C3AED`,
ciano escuro `0891B2` e fundo `111827`. Flutter usa `0xAARRGGBB`: em cores com
prefixos `0x77` ou `0xAA`, preserve o alpha e altere os seis dígitos RGB.

Os campos `surface`, `text` e `success` do JSON não têm aplicação automática
completa. Se precisar mudar esses componentes, adicione substituições
específicas no overlay, a partir do tema em `upstream/flutter/lib/common.dart`.
Preserve o dark fixo e a legibilidade dos textos.

Não faça a personalização principal diretamente em `upstream/`: o resultado
deve poder ser reconstruído com os scripts em uma nova máquina.

A seção “Sobre / Licenças” usa `scripts/cf_legal.dart` e os assets gerados por
`prepare.py`. Nome, empresa e vers?o v?m do JSON. Ajuste o nome do ZIP de fonte
no campo `source_archive` em `prepare.py` quando mudar o prefixo dos pacotes.
Preserve os créditos RustDesk, a licença completa e a informação de acesso
às fontes correspondentes.

### `scripts/cf_link.rs`

Troque somente o nome humano na mensagem de erro
`CF Link only connects to IDs on the company server`, se desejar.
As constantes com os nomes internos são geradas a partir do JSON.

**Não renomeie** features `cf-full`/`cf-qs`, módulos `cf_link`, arquivos
`cf_link_config.rs` ou opções `cf-profile`/`cf-dark-only`. São identificadores
técnicos usados por Rust, Flutter e Android, não textos da marca na interface.

## 6. Ajustar os nomes dos pacotes Windows e a verificação

Em `scripts/build-windows.ps1`, os nomes finais ainda estão fixos em
`CFLink-...-install.exe` e `CFLinkQS-....exe`.
Use o `$AppName` já calculado pelo script:

```powershell
$PackageName = if ($CurrentProfile -eq 'qs') {
    "$AppName-$($ClientConfig.version).exe"
} else {
    "$AppName-$($ClientConfig.version)-install.exe"
}
```

Preserve o sufixo **`-install.exe` do Full**: ele participa do fluxo de
instalação. O QS continua portátil, sem esse sufixo.

Em `scripts/verify-windows.py`, atualize os nomes esperados `CFLink` e
`CFLinkQS` para os nomes internos escolhidos. Preserve a verificação da base
RustDesk `1.5.0` e do bloqueio de instalação no QS.

## 7. Ajustar Android

Em `scripts/prepare-android.py`, atualize:

- O `label` visível: atualmente `CF Link` / `CF Link QS`.
- Os textos novos de `DEFAULT_NOTIFY_TITLE`, `channelName` e `description`.

Os `applicationId` e o bloqueio de boot do QS vêm dos campos Android do JSON.
**Não renomeie o namespace Kotlin/Java `com.carriez.flutter_hbb` nem as classes
JNI para apenas trocar a marca**: eles fazem parte da integração nativa.

Em `scripts/android-signing.py`, atualize o `-dname` para a nova empresa,
por exemplo `CN=Nova Link, O=Nova Tecnologia, C=BR`.
O nome técnico `cf-link.jks` e o alias `cf-link` podem continuar iguais dentro
da cópia independente; se mudar o alias, atualize também `keyAlias`.

O primeiro build cria uma identidade de assinatura própria em `.tools/signing`.
Não copie o keystore ou a senha da CF Tecnologia. Faça backup privado do novo
keystore e da senha: eles serão necessários para atualizar os APKs dessa marca.
Em atualizações Android, incremente também `--build-number`, atualmente fixo
em `1`, em `scripts/build-android.ps1`.

## 8. Ajustar macOS

`scripts/prepare-macos.py` e `scripts/build-macos.sh` leem os nomes internos
do JSON para o aplicativo e o DMG. Eles já se adaptam a `NovaLink`/`NovaLinkQS`.

Para a personalização rápida, preserve o prefixo técnico `com.carriez` dos
bundles. O nome novo do app torna os identificadores distintos. Trocar somente
esse prefixo no bundle não basta: `get_full_name()`, a organização nativa e os
caminhos/labels de LaunchAgents e LaunchDaemons também precisam ser alinhados.
Essa mudança adicional deve ser tratada separadamente e testada em um Mac.

Siga `docs/MACBOOK.md`. A compilação e os testes macOS precisam de um Mac;
este piloto foi compilado e verificado em Windows.

## 9. Atualizar documentação e empacotamento de fonte

| Arquivo | Alterar |
|---|---|
| `docs/NOTICE.txt` | Nova marca, empresa e versão; manter atribuições e licença RustDesk |
| `README.md` | Marca, arquivos de saída, paleta e resultados realmente obtidos pela nova empresa |
| `docs/VALIDACAO-WINDOWS.md` | Nomes dos novos pacotes; registrar a nova rodada de testes |
| `docs/MACBOOK.md` | Nomes ilustrativos dos aplicativos, DMGs e ZIP de fonte |
| `scripts/package-source.py` | Prefixo do ZIP `CFLink-...-source.zip`; opcionalmente a pasta interna `cf-link/` |
| `scripts/release-manifest.py` | Regex que identifica a versão pelo nome `CFLink`, textos e estado real das verificações |

Para o exemplo Nova Link, a regex de versão pode usar
`r'NovaLink(?:QS)?-(\d+\.\d+\.\d+)'`.
Não publique como aprovados testes que não executou. O manifesto contém textos
de validação fixos: precisa refletir a nova rodada, inclusive plataformas ainda
não compiladas. Não apague `LICENCE` nem os créditos e avisos legais da base.

## 10. Compilar e validar

Faça as alterações acima **antes** do primeiro setup na cópia limpa.
Os caminhos abaixo são relativos à raiz do projeto.

Windows x64, com Python, Git e Visual Studio com ferramentas C++/SDK Windows:

```powershell
.\scripts\setup-windows.ps1
.\scripts\build-windows.ps1 -Profile both
python scripts\verify-windows.py
```

Para repetir os testes de política, usando o ambiente local:

```powershell
. .\scripts\env.ps1
cargo test --manifest-path upstream\Cargo.toml --locked --lib --features flutter,cf-full cf_link::tests -- --test-threads=1
cargo test --manifest-path upstream\Cargo.toml --locked --lib --features flutter,cf-qs cf_link::tests -- --test-threads=1
```

Android ARM64, no Windows com o ambiente Windows preparado, Android Studio,
SDK e NDK `28.2.13676358` instalados:

```powershell
.\scripts\setup-android.ps1
.\scripts\build-android.ps1 -BuildProfile both
```

macOS, no Mac com os pré-requisitos de `docs/MACBOOK.md`:

```bash
bash scripts/setup-macos.sh
bash scripts/build-macos.sh both
```

Depois das verificações e do ajuste dos textos do manifesto:

```powershell
python scripts\package-source.py
python scripts\release-manifest.py
```

Confirme a nova marca em tela, ícones, propriedades do executável e notificações.
Teste Full iniciando/recebendo e QS recebendo tanto por senha quanto por aprovação.
Confirme que fechar o QS encerra o suporte, que não permite conexão de saída ou
instalação de serviço e que servidor e tema continuam bloqueados. Faça um teste
real entre dois computadores usando esse mesmo servidor antes de distribuir.

Não use `-SkipFlutter` ao mudar marca/interface nem `-SkipBridge` no primeiro
build de uma cópia limpa. Renomear um instalador antigo não aplica a nova marca.

Para conferir textos e nomes que ainda fazem referência à marca original:

```powershell
rg -n 'CF Link|CFLink|CF Tecnologia|cftecnologia' scripts config docs branding README.md
```

Revise os resultados caso a caso: exemplos deste guia podem continuar citando
CF Link, e identificadores técnicos/nomes de arquivos não precisam ser trocados.

## Prompt pronto para um agente de IA

Preencha os dados entre colchetes e entregue o texto abaixo com a cópia do projeto:

```text
Personalize este fork de RustDesk para outra empresa seguindo
docs/PERSONALIZAR-OUTRA-EMPRESA.md. Trabalhe somente na cópia independente.

Empresa: [NOME DA EMPRESA]
Nome visível Full: [NOME DO APP]
Nome visível QS: [NOME DO APP QS]
Nome interno Full, sem espaços/acentos: [NomeApp]
Nome interno QS, sem espaços/acentos: [NomeAppQS]
IDs Android: [com.empresa.app.full] e [com.empresa.app.qs]
Versão inicial: [1.0.0]
Símbolo PNG transparente: [CAMINHO]
Wordmark PNG transparente: [CAMINHO]
Paleta: [CORES OU MANTER A PALETA ATUAL]
Plataformas a compilar agora: [WINDOWS / ANDROID / MACOS]

Mantenha ID server 179.198.111.247:21116, relay 179.198.111.247:21117
e a chave pública existente em assets/id_ed25519.pub.
Não altere config/source-lock.json, as restrições de conexão ou o dark fixo.
QS: somente receber, aplicativo aberto, senha temporária de oito caracteres
OU aprovação local. Full: realizar e receber. Não crie senha fixa compartilhada.

Leia os scripts e atualize tanto o JSON quanto os textos/cores fixos do overlay,
os nomes dos pacotes, a verificação e a documentação. Preserve os identificadores
técnicos cf-full, cf-qs, cf-profile, cf-dark-only, módulos Rust e namespace JNI.
Não faça substituição global de CF: ela pode quebrar features e integração.
Use uma origem upstream limpa na versão fixada, preservando a pasta original.
Não copie caches, binários antigos ou credenciais privadas da CF Tecnologia.

Execute as verificações aplicáveis e compile apenas nas plataformas disponíveis.
Não afirme que compilou macOS no Windows nem que uma sessão real foi testada
sem executá-la. Atualize os textos fixos do manifesto com os resultados reais.
Entregue os pacotes solicitados, o código-fonte correspondente, os hashes e
um resumo dos arquivos alterados. Não publique no Git sem instrução explícita.
```
